"""
마음봄 - LangChain Agent v1.0

STT → 감정 분석 → GPT-4o-mini 응답 생성의 전체 플로우를 orchestration하는 Agent
"""
import os
import sys
import logging
from pathlib import Path
from typing import Any, Optional
from datetime import datetime

# 로깅 설정
logger = logging.getLogger(__name__)
ENABLE_DEBUG_LOGS = os.getenv("LANGCHAIN_DEBUG", "false").lower() == "true"

if ENABLE_DEBUG_LOGS:
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

# 프로젝트 루트 경로 설정
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# 환경변수 로드
from dotenv import load_dotenv
env_path = project_root / ".env"
if env_path.exists():
    load_dotenv(dotenv_path=env_path)

# 어댑터 imports
# 직접 실행 시와 모듈로 import 시 모두 작동하도록 처리
try:
    # 모듈로 import될 때 (from engine.langchain_agent import ...)
    from .adapters import run_speech_to_text, run_emotion_analysis, EmotionResult, run_routine_recommend
except ImportError:
    # 직접 실행될 때 (python agent.py)
    from adapters import run_speech_to_text, run_emotion_analysis, EmotionResult, run_routine_recommend


# ============================================================================
# 1. In-Memory Conversation Store
# ============================================================================

class InMemoryConversationStore:
    """
    세션별 대화 히스토리를 메모리에 저장하는 클래스
    
    v1.0에서는 간단한 in-memory 구현만 제공.
    나중에 DB/Redis로 교체 가능하도록 인터페이스를 정의.
    
    메모리 누수 방지를 위해 세션 수 및 메시지 수 제한을 적용.
    """
    
    def __init__(self, max_sessions: int = 100, max_messages_per_session: int = 50):
        """
        초기화
        
        Args:
            max_sessions: 최대 세션 수 (기본값: 100)
            max_messages_per_session: 세션당 최대 메시지 수 (기본값: 50)
        """
        # session_id -> list[dict] 형태로 히스토리 보관
        self._store: dict[str, list[dict]] = {}
        self.max_sessions = max_sessions
        self.max_messages_per_session = max_messages_per_session
        
    def add_message(self, session_id: str, role: str, content: str, metadata: Optional[dict] = None):
        """
        메시지 추가
        
        Args:
            session_id: 세션 ID
            role: 역할 ("user" 또는 "assistant")
            content: 메시지 내용
            metadata: 추가 메타데이터 (선택)
        """
        # 세션 수 제한 (LRU 방식: 가장 오래된 세션 제거)
        if len(self._store) >= self.max_sessions and session_id not in self._store:
            # 가장 오래된 메시지를 가진 세션 찾기
            oldest_session = min(
                self._store.items(),
                key=lambda x: x[1][-1]['timestamp'] if x[1] else ''
            )[0]
            del self._store[oldest_session]
            logger.warning(f"세션 수 제한 도달. 가장 오래된 세션 제거: {oldest_session}")
        
        if session_id not in self._store:
            self._store[session_id] = []
        
        # 메시지 수 제한 (FIFO: 가장 오래된 메시지 제거)
        if len(self._store[session_id]) >= self.max_messages_per_session:
            removed = self._store[session_id].pop(0)
            logger.warning(f"메시지 수 제한 도달. 가장 오래된 메시지 제거 (세션: {session_id})")
        
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
        print(f"[DEBUG] 대화 히스토리 조회: session_id={session_id}, 총 {len(history)}개 메시지")
        if history:
            print(f"[DEBUG] 히스토리 미리보기: {[{k: v[:50] if k == 'content' else v for k, v in msg.items() if k in ['role', 'content']} for msg in history]}")
        
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

def route_tools(user_text: str) -> dict[str, Any]:
    """
    사용자 텍스트를 분석하여 필요한 Tool 실행
    
    ToolRouter를 함수로 단순화 (상태가 없으므로 클래스 불필요)
    v1.1: emotion-analysis 실행 후 routine-recommend 자동 실행 (need_routine_recommend=True일 때)
    향후: health_advisor 등 추가 가능
    
    Args:
        user_text: 사용자 입력 텍스트
        
    Returns:
        Tool 실행 결과 딕셔너리
            - emotion_result: 감정 분석 결과
            - routine_result: 루틴 추천 결과 (있는 경우)
            - used_tools: 사용된 도구 목록
    """
    # 1. emotion-analysis 실행
    emotion_result = run_emotion_analysis(user_text)
    
    used_tools = ["emotion_analysis"]
    routine_result = None
    
    # 2. routine-recommend 실행 (감정 분석 결과 기반)
    try:
        # service_signals에서 need_routine_recommend 확인
        service_signals = emotion_result.get("service_signals", {})
        need_routine = service_signals.get("need_routine_recommend", False)
        
        if need_routine:
            logger.debug("🔄 루틴 추천이 필요합니다. routine-recommend 실행 중...")
            routine_result = run_routine_recommend(emotion_result)
            used_tools.append("routine_recommend")
            logger.info(f"✅ 루틴 추천 완료: {len(routine_result)}개")
        else:
            logger.debug("ℹ️  루틴 추천이 필요하지 않습니다.")
    except Exception as e:
        logger.warning(f"⚠️  루틴 추천 중 오류 발생 (무시하고 계속): {e}")
        # graceful degradation: 루틴 추천 실패해도 계속 진행
    
    return {
        "emotion_result": emotion_result,
        "routine_result": routine_result,
        "used_tools": used_tools,
    }


# ============================================================================
# 3. LLM 호출 (GPT-4o-mini)
# ============================================================================

# LLM 체인 캐시 (매번 재생성 방지 - 성능 최적화)
_llm_chain_cache = None


def create_llm_chain():
    """
    LLM 체인 생성
    
    LangChain을 Lazy Import하여 모듈 로딩 시간 단축 및 메모리 최적화
    
    Returns:
        LangChain의 LLM 체인
    """
    # LangChain Lazy Import (필요 시점에만 로드)
    from langchain_openai import ChatOpenAI
    from langchain_core.prompts import ChatPromptTemplate
    from langchain_core.output_parsers import StrOutputParser
    
    # 환경변수에서 설정 가져오기
    model_name = os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini")
    api_key = os.getenv("OPENAI_API_KEY")
    
    if not api_key:
        raise ValueError("OPENAI_API_KEY 환경변수가 설정되지 않았습니다.")
    
    logger.debug(f"LLM 체인 생성 중... (모델: {model_name})")
    
    # ChatOpenAI 초기화
    llm = ChatOpenAI(
        model=model_name,
        temperature=0.7,
        api_key=api_key
    )
    
    # System Prompt 정의
    system_prompt = """
너는 감정 공감을 기반으로 사용자의 하루를 따뜻하게 돌봐주는 케어 AI 친구 “AI 봄이"이다.

[정체성]
- 전문 상담사가 아니라, 사용자의 마음을 편하게 들어주는 일상 속 따뜻한 친구.
- 주요 타겟은 '갱년기 여성'이므로 신체·감정 변화(열감, 불면, 감정 기복 등)에 친숙하게 반응해야 함.
- 진단·치료 조언은 하지 않는다.

[대화 목적]
- 불안·혼란·민망함 등 복합적인 감정을 인정해주고, 필요할 경우 가벼운 안심과 일상 속 작은 루틴을 제안한다.
- 사용자의 기분을 조금이라도 편안하게 만들어주는 데 집중한다.
- 사용자가 바로 솔루션을 원하지 않을 수도 있으므로, 먼저 상황을 가볍게 물어보고 자연스럽게 대화를 이어가는 것이 우선이다.
- 이후 감정 분석 결과를 활용해 공감·안정·격려를 전달한다.

[기본 말투 규칙]
- 부드럽고 자연스러운 한국어 사용.
- 전체 톤: 부드럽고 따뜻하며 부담 없는 친구 같은 대화.
- 1) 상황 가벼운 탐색 → 2) 감정 공감 → 3) 부드러운 격려 순서.
- 공감 → 감정 이해 → 가벼운 격려 또는 선택형 제안 순서.
- 분석적 조언, 위험 표현, 강요 금지.
- 존댓말/반말은 사용자의 말투에 자동 맞춤.
- 전체 문장은 1~3문장으로 간단하게.

[상황 탐색 규칙]
- 사용자의 발화가 막연하거나 단편적일 때는 바로 위로하지 말고,
  “어떤 상황인지 조금 더 들어보고 싶어” 같은 부드러운 질문 1문장으로 먼저 탐색 가능.
- 단, 사용자의 발화가 감정적으로 매우 명확하고 이미 고통을 표현하는 경우에는
  질문보다는 바로 감정 공감 단계로 넘어가도 된다.
- 탐색 질문은 최대 1문장, 짧고 부담 없게.
예)  
- “그때 어떤 상황이었는지 조금 더 이야기해줄래?”  
- “혹시 언제부터 그런 느낌이 들었어?”  
- “조금만 더 말해주면 더 잘 이해할 수 있을 것 같아.”

[갱년기 특화 공감 규칙]
- 갱년기인 걸 확인하지만, 사용자에게 갱년기라는걸 티내지 않도록 답변한다.
- 신체 반응(열감, 안면홍조, 피곤함, 갑작스러운 기분 변화)에 민감하게 공감해준다.
- “나만 이런가?”라는 걱정에 자연스럽게 안심을 준다.
- 조심스럽게 “괜찮다면…”, “도움이 될 수도 있어” 같은 선택형 제안을 활용한다.
- 사용자가 스스로를 탓하지 않도록 돕는다.

[감정 기반 답변 정책]
- positive: 함께 기뻐하며 따뜻하게 반응.
- neutral: 편안한 분위기로 대화를 이어가기.
- negative: 감정을 인정하고, 불안·혼란을 다독이는 말투.
- primary emotion, secondary emotions를 자연스럽게 반영하되 직접 나열하지 않는다.
- risk_level이 높을 경우:
  - "위험하다" 같은 단어는 금지.
  - 부담 없는 도움 가능성만 은근히 열어둔다.
  - 전체 톤은 더욱 안정적이고 포근하게.

[루틴 정보 활용 규칙]
- routine_suggestion이 제공된 경우에만 자연스럽게 1문장 정도로 제안.
- 강요하지 않고 “해볼 수도 있을 것 같아” 정도로 완만하게 제시.

[음성 입력의 경우]
- 별도 안내 없이 텍스트 입력과 동일하게 처리.
- 음성 감정 신호(속도/톤 등)가 제공되면, 텍스트 감정과 동일한 방식으로 통합하여 응답.

[대화 히스토리 활용 규칙]
- 이전 대화 맥락이 제공되면 자연스럽게 기억하고 반영한다.
- 사용자가 이전에 언급한 감정이나 상황을 기억하고 있는 듯한 반응을 보인다.
- 단, "지난번에 말씀하셨듯이" 같은 명시적 표현은 피한다.
- 반복되는 패턴이나 감정 변화를 자연스럽게 감지하여 언급할 수 있다.
- 대화가 처음인 경우 히스토리 정보가 없으므로 현재 입력에만 집중한다.

답변 형식:
1) 사용자 감정 인정
2) 감정을 받아주는 공감 표현
3) 필요 시 가벼운 격려 또는 부드러운 제안
4) 문장 1~3개
"""
    
    # User Prompt 템플릿
    user_prompt_template = """
{conversation_history}

사용자 입력:
"{user_text}"

감정 분석 결과:
- 전체 감정: {sentiment_overall}
- 주요 감정: {primary_emotion_name} 
  (강도: {primary_emotion_intensity}/5, 신뢰도: {primary_emotion_confidence})
- 추천 응답 스타일: {recommended_response_style}
- 위험 수준: {risk_level}

루틴 신호:
{routine_info}

아래 규칙에 따라 따뜻하고 자연스러운 봄이의 답변을 만들어라:
- 감정 분석(primary emotion 및 부정 감정 포함)을 최우선으로 반영한다.
- 사용자가 느낀 신체적·감정적 불편이 갱년기적 특성과 연관될 수 있다면 자연스럽게 이해해주는 톤을 사용한다.
- routine_suggestion이 있을 경우 마지막 문장에 선택형으로 자연스럽게 포함한다.
- 이전 대화 맥락이 있다면 자연스럽게 반영하되, 명시적으로 언급하지 않는다.
- 전체 답변은 2~3문장으로 간결하고 포근하게 작성한다.
"""
    
    # ChatPromptTemplate 생성
    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("user", user_prompt_template)
    ])
    
    # 체인 구성
    chain = prompt | llm | StrOutputParser()
    
    return chain


def get_llm_chain():
    """
    LLM 체인을 캐시하여 재사용 (성능 최적화)
    
    매번 ChatOpenAI 객체를 생성하는 것은 비효율적이므로,
    한 번 생성된 체인을 캐시하여 재사용합니다.
    
    Returns:
        캐시된 LLM 체인
    """
    global _llm_chain_cache
    if _llm_chain_cache is None:
        _llm_chain_cache = create_llm_chain()
    return _llm_chain_cache


def generate_llm_response(
    user_text: str, 
    emotion_result: EmotionResult, 
    routine_result: list[dict] | None = None,
    conversation_history: list[dict] | None = None
) -> str:
    """
    LLM을 호출하여 응답 생성
    
    Args:
        user_text: 사용자 입력 텍스트
        emotion_result: 감정 분석 결과
        routine_result: 루틴 추천 결과 (선택)
        conversation_history: 대화 히스토리 (선택)
        
    Returns:
        AI 봄이의 응답 텍스트
    """
    # LLM 체인 가져오기 (캐시 사용)
    chain = get_llm_chain()
    
    # 감정 분석 결과에서 필요한 정보 추출
    primary_emotion = emotion_result.get("primary_emotion", {})
    sentiment_overall = emotion_result.get("sentiment_overall", "neutral")
    recommended_response_style = emotion_result.get("recommended_response_style", [])
    risk_level = emotion_result.get("risk_level", "low")
    
    # 응답 스타일을 문자열로 변환
    style_str = ", ".join(recommended_response_style) if recommended_response_style else "공감적이고 따뜻한 답변"
    
    # 대화 히스토리 포맷팅
    history_text = ""
    if conversation_history and len(conversation_history) > 0:
        history_text = "최근 대화 맥락:\n"
        for msg in conversation_history:
            role_name = "사용자" if msg["role"] == "user" else "AI 봄이"
            content_preview = msg["content"][:100] + "..." if len(msg["content"]) > 100 else msg["content"]
            history_text += f"- {role_name}: {content_preview}\n"
        history_text += "\n"
    
    # 루틴 추천 정보 포맷팅
    routine_info = ""
    routine_suggestion = ""
    if routine_result and len(routine_result) > 0:
        routine_info = "추천 루틴:\n"
        for i, routine in enumerate(routine_result[:3], 1):  # 최대 3개만 표시
            routine_info += f"  {i}. {routine.get('title', 'N/A')}: {routine.get('reason', 'N/A')}\n"
        routine_suggestion = "가능하다면 추천 루틴을 자연스럽게 언급해줘. 단, 강요하지 말고 부드럽게 제안하는 톤으로."
    
    # LLM 호출
    response = chain.invoke({
        "conversation_history": history_text,
        "user_text": user_text,
        "sentiment_overall": sentiment_overall,
        "primary_emotion_name": primary_emotion.get("name_ko", "알 수 없음"),
        "primary_emotion_intensity": primary_emotion.get("intensity", 3),
        "primary_emotion_confidence": primary_emotion.get("confidence", 0.7),
        "recommended_response_style": style_str,
        "risk_level": risk_level,
        "routine_info": routine_info,
        "routine_suggestion": routine_suggestion
    })
    
    return response


# ============================================================================
# 4. 메인 Agent 함수들
# ============================================================================

def run_ai_bomi_from_text(
    user_text: str,
    session_id: Optional[str] = None,
    stt_quality: Optional[str] = None
) -> dict[str, Any]:
    """
    텍스트 입력으로 AI 봄이 실행
    
    전체 플로우:
    1. 입력 수신 및 전처리
    2. Agent Memory 조회/업데이트
    3. Tool Router → tool 호출(emotion-analysis, routine-recommend 등)
    4. LLM(GPT-4o) 호출, 한국어 응답 생성
    5. 결과 묶어서 반환
    
    Args:
        user_text: 사용자 입력 텍스트
        session_id: 세션 ID (선택, 없으면 "default" 사용)
        stt_quality: STT 품질 정보 (선택, "success" | "medium" | "low_quality" | "no_speech")
        
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
    
    # 2. Agent Memory 조회 및 히스토리 준비
    conversation_store = get_conversation_store()

    # 이전 대화 히스토리 조회 (최근 3개만 LLM에 전달)
    history = conversation_store.get_history(session_id, limit=3)
    print(f"[DEBUG] run_ai_bomi_from_text: 조회된 히스토리 개수 = {len(history)}")
    
    # 3. Tool Router 실행
    logger.debug("🔧 Tool Router 실행 중...")
    tool_result = route_tools(user_text)
    emotion_result = tool_result["emotion_result"]
    routine_result = tool_result.get("routine_result")
    used_tools = tool_result["used_tools"]
    
    logger.info(f"✅ 감정 분석 완료: {emotion_result['primary_emotion']['name_ko']} ({emotion_result['sentiment_overall']})")
    
    # 4. LLM 호출 (대화 히스토리 포함)
    logger.debug("🤖 LLM 응답 생성 중...")
    print(f"[DEBUG] LLM에 전달되는 히스토리: {len(history)}개")
    reply_text = generate_llm_response(
        user_text, 
        emotion_result, 
        routine_result,
        conversation_history=history
    )
    logger.info("✅ 응답 생성 완료")
    
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
        "routine_result": routine_result,  # 루틴 추천 결과 추가
        "meta": {
            "model": os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
            "used_tools": used_tools,
            "session_id": session_id,
        }
    }
    
    # STT quality 정보가 있으면 메타에 추가
    if stt_quality:
        result["meta"]["stt_quality"] = stt_quality
    
    return result


def run_ai_bomi_from_audio(
    audio_bytes: bytes,
    session_id: Optional[str] = None
) -> dict[str, Any]:
    """
    음성 입력으로 AI 봄이 실행
    
    ⚠️ DEPRECATED: 이 함수는 더 이상 권장되지 않습니다.
    현재 WebSocket 스트리밍 방식(/agent/stream)과 호환되지 않습니다.
    대신 /agent/stream WebSocket 엔드포인트를 사용하세요.
    
    전체 플로우:
    1. STT 엔진 호출 (adapters.stt_adapter.run_speech_to_text)
    2. 텍스트로 변환된 결과를 run_ai_bomi_from_text(...)에 위임
    
    Args:
        audio_bytes: 오디오 데이터 (바이트열)
        session_id: 세션 ID (선택)
        
    Returns:
        AI 봄이의 응답 결과
    """
    import warnings
    warnings.warn(
        "run_ai_bomi_from_audio is deprecated. Use /agent/stream WebSocket endpoint instead.",
        DeprecationWarning,
        stacklevel=2
    )
    # 1. STT 실행
    logger.debug("🎤 STT 실행 중...")
    user_text = run_speech_to_text(audio_bytes)
    logger.info(f"✅ STT 완료: {user_text}")
    
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
    print("\n" + "=" * 80)
    print("테스트 완료!")
    print("=" * 80)

