"""
마음봄 - LangChain Agent v1.0

STT → 감정 분석 → GPT-4o 응답 생성의 전체 플로우를 orchestration하는 Agent
"""
import os
import sys
from pathlib import Path
from typing import Any, Optional
from datetime import datetime

# 프로젝트 루트 경로 설정
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# 환경변수 로드
from dotenv import load_dotenv
env_path = project_root / ".env"
if env_path.exists():
    load_dotenv(dotenv_path=env_path)

# LangChain imports
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

# 어댑터 imports
# 직접 실행 시와 모듈로 import 시 모두 작동하도록 처리
try:
    # 모듈로 import될 때 (from engine.langchain_agent import ...)
    from .adapters import run_speech_to_text, run_emotion_analysis, EmotionResult
except ImportError:
    # 직접 실행될 때 (python agent.py)
    from adapters import run_speech_to_text, run_emotion_analysis, EmotionResult


# ============================================================================
# 1. In-Memory Conversation Store
# ============================================================================

class InMemoryConversationStore:
    """
    세션별 대화 히스토리를 메모리에 저장하는 클래스
    
    v1.0에서는 간단한 in-memory 구현만 제공.
    나중에 DB/Redis로 교체 가능하도록 인터페이스를 정의.
    """
    
    def __init__(self):
        """초기화"""
        # session_id -> list[dict] 형태로 히스토리 보관
        self._store: dict[str, list[dict]] = {}
        
    def add_message(self, session_id: str, role: str, content: str, metadata: Optional[dict] = None):
        """
        메시지 추가
        
        Args:
            session_id: 세션 ID
            role: 역할 ("user" 또는 "assistant")
            content: 메시지 내용
            metadata: 추가 메타데이터 (선택)
        """
        if session_id not in self._store:
            self._store[session_id] = []
            
        message = {
            "role": role,
            "content": content,
            "timestamp": datetime.now().isoformat(),
        }
        
        if metadata:
            message["metadata"] = metadata
            
        self._store[session_id].append(message)
        
    def get_history(self, session_id: str, limit: Optional[int] = None) -> list[dict]:
        """
        대화 히스토리 조회
        
        Args:
            session_id: 세션 ID
            limit: 최근 N개만 가져오기 (선택)
            
        Returns:
            메시지 리스트
        """
        history = self._store.get(session_id, [])
        
        if limit:
            return history[-limit:]
        return history
        
    def clear_session(self, session_id: str):
        """
        특정 세션의 히스토리 삭제
        
        Args:
            session_id: 세션 ID
        """
        if session_id in self._store:
            del self._store[session_id]


# 전역 인스턴스
_conversation_store = InMemoryConversationStore()


def get_conversation_store() -> InMemoryConversationStore:
    """
    전역 대화 저장소 인스턴스 반환
    
    Returns:
        InMemoryConversationStore 인스턴스
    """
    return _conversation_store


def get_all_sessions() -> dict[str, Any]:
    """
    모든 세션 정보 반환
    
    Returns:
        세션별 대화 개수 및 최근 메시지 정보
    """
    store = get_conversation_store()
    sessions_info = {}
    
    for session_id, messages in store._store.items():
        if messages:
            sessions_info[session_id] = {
                "message_count": len(messages),
                "last_message_time": messages[-1].get("timestamp"),
                "last_message_preview": messages[-1].get("content", "")[:50] + "..." if len(messages[-1].get("content", "")) > 50 else messages[-1].get("content", "")
            }
    
    return sessions_info


# ============================================================================
# 2. Tool Router
# ============================================================================

class ToolRouter:
    """
    Tool 호출을 라우팅하는 클래스
    
    v1.0에서는 emotion-analysis만 사용하지만,
    나중에 routine_recommend, health_advisor 등을 쉽게 추가할 수 있게 설계
    """
    
    def __init__(self):
        """초기화"""
        pass
        
    def run(self, user_text: str) -> dict[str, Any]:
        """
        사용자 텍스트를 분석하여 필요한 Tool 실행
        
        v1.0: 무조건 emotion-analysis 실행
        
        Args:
            user_text: 사용자 입력 텍스트
            
        Returns:
            Tool 실행 결과
        """
        # emotion-analysis 실행
        emotion_result = run_emotion_analysis(user_text)
        
        return {
            "emotion_result": emotion_result,
            "used_tools": ["emotion_analysis"],
        }


# ============================================================================
# 3. LLM 호출 (GPT-4o)
# ============================================================================

def create_llm_chain():
    """
    LLM 체인 생성
    
    Returns:
        LangChain의 LLM 체인
    """
    # 환경변수에서 설정 가져오기
    model_name = os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini")
    api_key = os.getenv("OPENAI_API_KEY")
    
    if not api_key:
        raise ValueError("OPENAI_API_KEY 환경변수가 설정되지 않았습니다.")
    
    # ChatOpenAI 초기화
    llm = ChatOpenAI(
        model=model_name,
        temperature=0.7,
        api_key=api_key
    )
    
    # System Prompt 정의
    system_prompt = """너는 감정 케어 AI "AI 봄이"다.

**역할:**
- 사용자의 감정 분석 결과를 참고해서, 사용자의 기분을 인정하고 공감하거나 가볍게 격려하는 한국어 답변을 준다.
- 상담사처럼 무겁게 말하기보다는, 일상을 함께 나누는 따뜻한 친구처럼 부드럽게 이야기한다.
- 답변은 3~5문장 정도로 한다.

**답변 스타일:**
- 공감과 이해를 우선으로 한다.
- 사용자의 감정을 판단하거나 비난하지 않는다.
- 필요하면 가볍게 격려하되, 강요하지 않는다.
- 자연스럽고 따뜻한 말투를 사용한다.
"""
    
    # User Prompt 템플릿
    user_prompt_template = """사용자가 다음과 같이 말했어:

"{user_text}"

감정 분석 결과:
- 전체 감정: {sentiment_overall}
- 주요 감정: {primary_emotion_name} (강도: {primary_emotion_intensity}/5, 신뢰도: {primary_emotion_confidence})
- 추천 응답 스타일: {recommended_response_style}

위 정보를 참고해서, 사용자에게 따뜻하고 공감적인 답변을 해줘.
"""
    
    # ChatPromptTemplate 생성
    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("user", user_prompt_template)
    ])
    
    # 체인 구성
    chain = prompt | llm | StrOutputParser()
    
    return chain


def generate_llm_response(user_text: str, emotion_result: EmotionResult) -> str:
    """
    LLM을 호출하여 응답 생성
    
    Args:
        user_text: 사용자 입력 텍스트
        emotion_result: 감정 분석 결과
        
    Returns:
        AI 봄이의 응답 텍스트
    """
    # LLM 체인 생성
    chain = create_llm_chain()
    
    # 감정 분석 결과에서 필요한 정보 추출
    primary_emotion = emotion_result.get("primary_emotion", {})
    sentiment_overall = emotion_result.get("sentiment_overall", "neutral")
    recommended_response_style = emotion_result.get("recommended_response_style", [])
    
    # 응답 스타일을 문자열로 변환
    style_str = ", ".join(recommended_response_style) if recommended_response_style else "공감적이고 따뜻한 답변"
    
    # LLM 호출
    response = chain.invoke({
        "user_text": user_text,
        "sentiment_overall": sentiment_overall,
        "primary_emotion_name": primary_emotion.get("name_ko", "알 수 없음"),
        "primary_emotion_intensity": primary_emotion.get("intensity", 3),
        "primary_emotion_confidence": primary_emotion.get("confidence", 0.7),
        "recommended_response_style": style_str
    })
    
    return response


# ============================================================================
# 4. 메인 Agent 함수들
# ============================================================================

def run_ai_bomi_from_text(
    user_text: str,
    session_id: Optional[str] = None
) -> dict[str, Any]:
    """
    텍스트 입력으로 AI 봄이 실행
    
    전체 플로우:
    1. 입력 수신 및 전처리
    2. Agent Memory 조회/업데이트
    3. Tool Router → emotion-analysis 호출
    4. LLM(GPT-4o) 호출, 한국어 응답 생성
    5. 결과 묶어서 반환
    
    Args:
        user_text: 사용자 입력 텍스트
        session_id: 세션 ID (선택, 없으면 "default" 사용)
        
    Returns:
        AI 봄이의 응답 결과
    """
    # 세션 ID 기본값
    if not session_id:
        session_id = "default"
    
    # 1. 입력 전처리
    user_text = user_text.strip()
    if not user_text:
        return {
            "reply_text": "무슨 말씀을 하고 싶으신가요? 편하게 이야기해주세요.",
            "input_text": "",
            "emotion_result": None,
            "meta": {
                "model": os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
                "used_tools": [],
                "session_id": session_id,
                "error": "empty_input"
            }
        }
    
    # 연속 공백 제거
    user_text = " ".join(user_text.split())
    
    # 2. Agent Memory 조회 (v1.0에서는 단순 저장만)
    conversation_store = get_conversation_store()
    # 이전 대화 히스토리 조회 (필요시 사용)
    # history = conversation_store.get_history(session_id, limit=5)
    
    # 3. Tool Router 실행
    print(f"\n🔧 Tool Router 실행 중...")
    tool_result = ToolRouter().run(user_text)
    emotion_result = tool_result["emotion_result"]
    used_tools = tool_result["used_tools"]
    
    print(f"✅ 3-4 감정 분석 완료: {emotion_result['primary_emotion']['name_ko']} ({emotion_result['sentiment_overall']})")
    
    # 4. LLM 호출
    print(f"\n🤖 LLM 응답 생성 중...")
    reply_text = generate_llm_response(user_text, emotion_result)
    print(f"✅ 응답 생성 완료")
    
    # 5. Memory 업데이트
    conversation_store.add_message(
        session_id=session_id,
        role="user",
        content=user_text,
        metadata={"emotion_result": emotion_result}
    )
    conversation_store.add_message(
        session_id=session_id,
        role="assistant",
        content=reply_text
    )
    
    # 6. 최종 결과 반환
    result = {
        "reply_text": reply_text,
        "input_text": user_text,
        "emotion_result": emotion_result,
        "meta": {
            "model": os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
            "used_tools": used_tools,
            "session_id": session_id,
        }
    }
    
    return result


def run_ai_bomi_from_audio(
    audio_bytes: bytes,
    session_id: Optional[str] = None
) -> dict[str, Any]:
    """
    음성 입력으로 AI 봄이 실행
    
    전체 플로우:
    1. STT 엔진 호출 (adapters.stt_adapter.run_speech_to_text)
    2. 텍스트로 변환된 결과를 run_ai_bomi_from_text(...)에 위임
    
    Args:
        audio_bytes: 오디오 데이터 (바이트열)
        session_id: 세션 ID (선택)
        
    Returns:
        AI 봄이의 응답 결과
    """
    # 1. STT 실행
    print(f"\n🎤 3-3 STT 실행 중...")
    user_text = run_speech_to_text(audio_bytes)
    print(f"✅ 3-3 STT 완료: {user_text}")
    
    # 2. 텍스트 입력 함수에 위임
    result = run_ai_bomi_from_text(user_text, session_id)
    
    # used_tools에 speech_to_text 추가
    result["meta"]["used_tools"].insert(0, "speech_to_text")
    
    return result


# ============================================================================
# 5. 테스트 코드
# ============================================================================

if __name__ == "__main__":
    print("=" * 80)
    print("마음봄 - LangChain Agent v1.0 테스트")
    print("=" * 80)
    
    # 테스트 1: 텍스트 입력
    print("\n\n[테스트 1] 텍스트 입력 - 긍정적인 감정")
    print("-" * 80)
    
    test_text_1 = "아침에 눈을 뜨자 햇살이 방 안을 가득 채우고 있었고, 오랜만에 상쾌한 기분이 들어 따뜻한 커피를 한 잔 들고 여유롭게 집을 나설 수 있었다."
    
    result_1 = run_ai_bomi_from_text(test_text_1, session_id="test_session_1")
    
    print(f"\n📝 입력: {result_1['input_text']}")
    print(f"\n💬 AI 봄이 응답:\n{result_1['reply_text']}")
    print(f"\n📊 3-4 감정 분석:")
    print(f"  - 주요 감정: {result_1['emotion_result']['primary_emotion']['name_ko']} "
          f"(강도: {result_1['emotion_result']['primary_emotion']['intensity']}/5, "
          f"신뢰도: {result_1['emotion_result']['primary_emotion']['confidence']})")
    print(f"  - 전체 감정: {result_1['emotion_result']['sentiment_overall']}")
    print(f"  - 위험 수준: {result_1['emotion_result']['service_signals']['risk_level']}")
    print(f"\n🔧 사용된 도구: {result_1['meta']['used_tools']}")
    print(f"🤖 모델: {result_1['meta']['model']}")
    
    # 테스트 2: 텍스트 입력 - 부정적인 감정
    print("\n\n[테스트 2] 텍스트 입력 - 부정적인 감정")
    print("-" * 80)
    
    test_text_2 = "오늘 하루 정말 힘들었어요. 아무것도 하기 싫고 기운이 없네요."
    
    result_2 = run_ai_bomi_from_text(test_text_2, session_id="test_session_2")
    
    print(f"\n📝 입력: {result_2['input_text']}")
    print(f"\n💬 AI 봄이 응답:\n{result_2['reply_text']}")
    print(f"\n📊 3-4 감정 분석:")
    print(f"  - 주요 감정: {result_2['emotion_result']['primary_emotion']['name_ko']} "
          f"(강도: {result_2['emotion_result']['primary_emotion']['intensity']}/5, "
          f"신뢰도: {result_2['emotion_result']['primary_emotion']['confidence']})")
    print(f"  - 전체 감정: {result_2['emotion_result']['sentiment_overall']}")
    print(f"  - 위험 수준: {result_2['emotion_result']['service_signals']['risk_level']}")
    print(f"  - 추천 루틴: {result_2['emotion_result']['recommended_routine_tags']}")
    print(f"\n🔧 사용된 도구: {result_2['meta']['used_tools']}")
    
    # 테스트 3: 음성 입력 (더미 바이트)
    print("\n\n[테스트 3] 음성 입력 (더미 데이터)")
    print("-" * 80)
    
    dummy_audio = b"dummy audio bytes for testing"
    
    result_3 = run_ai_bomi_from_audio(dummy_audio, session_id="test_session_3")
    
    print(f"\n📝 입력 (3-3 STT 결과): {result_3['input_text']}")
    print(f"\n💬 AI 봄이 응답:\n{result_3['reply_text']}")
    print(f"\n📊 3-4 감정 분석:")
    print(f"  - 주요 감정: {result_3['emotion_result']['primary_emotion']['name_ko']}")
    print(f"  - 전체 감정: {result_3['emotion_result']['sentiment_overall']}")
    print(f"\n🔧 사용된 도구: {result_3['meta']['used_tools']}")
    
    # 대화 히스토리 확인
    print("\n\n[대화 히스토리 확인]")
    print("-" * 80)
    
    store = get_conversation_store()
    history = store.get_history("test_session_1")
    print(f"\ntest_session_1의 대화 개수: {len(history)}")
    for i, msg in enumerate(history, 1):
        print(f"{i}. [{msg['role']}] {msg['content'][:50]}...")
    
    print("\n" + "=" * 80)
    print("테스트 완료!")
    print("=" * 80)

