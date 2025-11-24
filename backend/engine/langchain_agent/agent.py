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
import uuid

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
try:
    from .adapters import run_speech_to_text, run_emotion_analysis, EmotionResult, run_routine_recommend
    from .adapters.memory_adapter import should_store_memory, add_memory, get_memories_for_prompt
    from .conversation_vectorstore import add_message_to_rag, get_rag_context_for_prompt
except ImportError:
    from adapters import run_speech_to_text, run_emotion_analysis, EmotionResult, run_routine_recommend
    from adapters.memory_adapter import should_store_memory, add_memory, get_memories_for_prompt
    from conversation_vectorstore import add_message_to_rag, get_rag_context_for_prompt


# ============================================================================
# 1. In-Memory Conversation Store
# ============================================================================

class InMemoryConversationStore:
    """
    세션별 대화 히스토리를 메모리에 저장하는 클래스
    
    v1.1: 세션 메타데이터 관리 및 타임아웃 기능 추가
    
    메모리 누수 방지를 위해 세션 수 및 메시지 수 제한을 적용.
    """
    
    def __init__(self, max_sessions: int = 100, max_messages_per_session: int = 50, session_timeout_minutes: int = 60):
        """
        초기화
        
        Args:
            max_sessions: 최대 세션 수 (기본값: 100)
            max_messages_per_session: 세션당 최대 메시지 수 (기본값: 50)
            session_timeout_minutes: 세션 만료 시간 (분) (기본값: 60)
        """
        # session_id -> list[dict] 형태로 히스토리 보관
        self._store: dict[str, list[dict]] = {}
        # session_id -> dict 형태로 메타데이터 보관
        self._session_metadata: dict[str, dict] = {}
        self._speaker_profiles: dict[str, dict] = {}
        
        self.max_sessions = max_sessions
        self.max_messages_per_session = max_messages_per_session
        self.session_timeout_minutes = session_timeout_minutes
        
    def _init_session_metadata(self, session_id: str):
        """세션 메타데이터 초기화"""
        self._session_metadata[session_id] = {
            "created_at": datetime.now().isoformat(),
            "last_activity_at": datetime.now().isoformat(),
            "message_count": 0,
            "status": "active"
        }

    def _update_session_activity(self, session_id: str):
        """세션 활동 시간 업데이트"""
        if session_id in self._session_metadata:
            self._session_metadata[session_id]["last_activity_at"] = datetime.now().isoformat()
            self._session_metadata[session_id]["message_count"] = len(self._store.get(session_id, []))

    def _check_session_timeout(self, session_id: str) -> bool:
        """세션 타임아웃 확인"""
        if session_id not in self._session_metadata:
            return False
            
        try:
            last_activity = datetime.fromisoformat(self._session_metadata[session_id]["last_activity_at"])
            elapsed = datetime.now() - last_activity
            if elapsed.total_seconds() > self.session_timeout_minutes * 60:
                return True
        except Exception as e:
            logger.error(f"세션 타임아웃 체크 중 오류: {e}")
            
        return False

    def add_message(self, session_id: str, role: str, content: str, metadata: Optional[dict] = None):
        """
        메시지 추가
        
        Args:
            session_id: 세션 ID
            role: 역할 ("user" 또는 "assistant")
            content: 메시지 내용
            metadata: 추가 메타데이터 (선택)
        """
        # 세션 초기화 및 메타데이터 설정
        if session_id not in self._store:
            self._store[session_id] = []
            self._init_session_metadata(session_id)
        
        # 타임아웃 체크
        if self._check_session_timeout(session_id):
            logger.info(f"⏳ 세션 {session_id} 만료됨 (마지막 활동 후 {self.session_timeout_minutes}분 경과).")
            # 만료된 세션 처리 정책:
            # 1. 로그를 남기고 계속 사용 (현재 방식)
            # 2. 아카이브 후 새 세션 시작 (향후 구현)
            self._session_metadata[session_id]["status"] = "expired"
        
        # 세션 수 제한 (LRU 방식)
        if len(self._store) > self.max_sessions:
            # 가장 오래된 활동 세션 찾기
            oldest_session = min(
                self._session_metadata.items(),
                key=lambda x: x[1]['last_activity_at']
            )[0]
            if oldest_session != session_id: # 현재 세션은 삭제하지 않음
                del self._store[oldest_session]
                del self._session_metadata[oldest_session]
                logger.warning(f"🧹 세션 수 제한 도달. 가장 오래된 세션 제거: {oldest_session}")
        
        # 메시지 수 제한 (FIFO)
        if len(self._store[session_id]) >= self.max_messages_per_session:
            self._store[session_id].pop(0)
            logger.warning(f"🧹 메시지 수 제한 도달. 가장 오래된 메시지 제거 (세션: {session_id})")
        
        message = {
            "role": role,
            "content": content,
            "timestamp": datetime.now().isoformat(),
        }
        
        if metadata:
            message["metadata"] = metadata
            
        self._store[session_id].append(message)
        self._update_session_activity(session_id)
        
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
        
        # 활동 시간 업데이트 (조회도 활동으로 간주할지 여부는 정책에 따름, 여기서는 업데이트 안 함)
        
        if limit:
            return history[-limit:]
        return history
        
    def get_session_metadata(self, session_id: str) -> Optional[dict]:
        """세션 메타데이터 조회"""
        return self._session_metadata.get(session_id)
        
    def clear_session(self, session_id: str):
        """
        특정 세션의 히스토리 삭제
        
        Args:
            session_id: 세션 ID
        """
        if session_id in self._store:
            del self._store[session_id]
        if session_id in self._session_metadata:
            del self._session_metadata[session_id]

    def add_speaker_profile(self, speaker_id: str, embedding: Any, quality: str, session_id: Optional[str] = None):
        """화자 프로필 추가"""
        self._speaker_profiles[speaker_id] = {
            "embedding": embedding,
            "quality": quality,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "session_id": session_id
        }

    def update_speaker_embedding(self, speaker_id: str, new_embedding: Any, quality: str):
        """화자 임베딩 업데이트"""
        if speaker_id in self._speaker_profiles:
            self._speaker_profiles[speaker_id]["embedding"] = new_embedding
            self._speaker_profiles[speaker_id]["quality"] = quality
            self._speaker_profiles[speaker_id]["updated_at"] = datetime.now().isoformat()

    def get_all_speaker_ids(self) -> list[str]:
        """등록된 모든 화자 ID 반환"""
        return list(self._speaker_profiles.keys())


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
        세션별 메타데이터 및 상태 정보
    """
    store = get_conversation_store()
    sessions_info = {}
    
    # 메타데이터가 있는 세션 우선 조회
    for session_id, metadata in store._session_metadata.items():
        sessions_info[session_id] = metadata.copy()
        # 메시지 미리보기 추가
        history = store.get_history(session_id, limit=1)
        if history:
            last_msg = history[-1]
            sessions_info[session_id]["last_message_preview"] = (
                last_msg.get("content", "")[:50] + "..." 
                if len(last_msg.get("content", "")) > 50 
                else last_msg.get("content", "")
            )
            
    # 메타데이터에는 없지만 store에는 있는 세션 (하위 호환성)
    for session_id, messages in store._store.items():
        if session_id not in sessions_info and messages:
            sessions_info[session_id] = {
                "created_at": messages[0].get("timestamp"),
                "last_activity_at": messages[-1].get("timestamp"),
                "message_count": len(messages),
                "status": "active",
                "last_message_preview": messages[-1].get("content", "")[:50] + "..."
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
너는 감정 공감을 기반으로 사용자의 하루를 따뜻하게 돌봐주는 케어 AI 친구 "AI 봄이"이다.

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
  "어떤 상황인지 조금 더 들어보고 싶어" 같은 부드러운 질문 1문장으로 먼저 탐색 가능.
- 단, 사용자의 발화가 감정적으로 매우 명확하고 이미 고통을 표현하는 경우에는
  질문보다는 바로 감정 공감 단계로 넘어가도 된다.
- 탐색 질문은 최대 1문장, 짧고 부담 없게.
예)  
- "그때 어떤 상황이었는지 조금 더 이야기해줄래?"  
- "혹시 언제부터 그런 느낌이 들었어?"  
- "조금만 더 말해주면 더 잘 이해할 수 있을 것 같아."

[갱년기 특화 공감 규칙]
- 갱년기인 걸 확인하지만, 사용자에게 갱년기라는걸 티내지 않도록 답변한다.
- 신체 반응(열감, 안면홍조, 피곤함, 갑작스러운 기분 변화)에 민감하게 공감해준다.
- "나만 이런가?"라는 걱정에 자연스럽게 안심을 준다.
- 조심스럽게 "괜찮다면…", "도움이 될 수도 있어" 같은 선택형 제안을 활용한다.
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
- 강요하지 않고 "해볼 수도 있을 것 같아" 정도로 완만하게 제시.

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
{memory_context}

{rag_context}

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
- [중요] Memory Layer와 RAG Context에 있는 사용자의 과거 정보나 고민을 자연스럽게 반영하여, "기억하고 있다"는 느낌을 준다.
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
    conversation_history: list[dict] | None = None,
    memory_context: str = "",
    rag_context: str = ""
) -> str:
    """
    LLM을 호출하여 응답 생성
    
    Args:
        user_text: 사용자 입력 텍스트
        emotion_result: 감정 분석 결과
        routine_result: 루틴 추천 결과 (선택)
        conversation_history: 대화 히스토리 (선택)
        memory_context: Memory Layer 조회 결과 문자열 (선택)
        rag_context: RAG 검색 결과 문자열 (선택)
        
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
        "memory_context": memory_context,
        "rag_context": rag_context,
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
    session_id: str = "default",
    stt_quality: str = "success",
    speaker_id: Optional[str] = None
) -> dict[str, Any]:
    """
    텍스트 입력 기반 AI 봄이 실행 (Memory + RAG 통합)
    """
    logger.info(f"🚀 [Agent] 텍스트 입력 처리 시작 (세션: {session_id})")
    
    store = get_conversation_store()
    
    # 1. 사용자 메시지 저장
    store.add_message(session_id, "user", user_text)
    
    # 2. Tool Routing (감정 분석 등)
    tool_results = route_tools(user_text)
    emotion_result = tool_results["emotion_result"]
    routine_result = tool_results["routine_result"]
    
    # 3. Memory Layer & RAG Context Retrieval
    memory_context = ""
    rag_context = ""
    
    try:
        # 3-1. Memory Layer (장기 기억)
        # 저장 여부 판단 및 저장
        if should_store_memory(user_text, emotion_result):
            add_memory(user_text, emotion_result, session_id)
            
        # 관련 기억 조회
        memories = get_memories_for_prompt(user_text)
        if memories:
            memory_context = f"[기억된 정보]\n{memories}\n"
            
        # 3-2. Conversation RAG (과거 대화)
        # 현재 메시지를 RAG에 저장 (비동기로 하면 좋지만 일단 동기 처리)
        msg_id_user = f"msg_{session_id}_{uuid.uuid4().hex[:8]}"
        add_message_to_rag(msg_id_user, session_id, "user", user_text, emotion_result)
        
        # 관련 대화 조회
        rag_docs = get_rag_context_for_prompt(user_text, session_id)
        if rag_docs:
            rag_context = f"[과거 대화]\n{rag_docs}\n"
            
    except Exception as e:
        logger.error(f"Memory/RAG 처리 중 오류 (무시하고 진행): {e}")
    
    # 4. 대화 히스토리 조회 (전체 세션 대화)
    conversation_history = store.get_history(session_id, limit=None)
    
    # 5. LLM 응답 생성
    ai_response_text = generate_llm_response(
        user_text=user_text,
        emotion_result=emotion_result,
        routine_result=routine_result,
        conversation_history=conversation_history,
        memory_context=memory_context,
        rag_context=rag_context
    )
    
    # 6. AI 응답 저장
    store.add_message(session_id, "assistant", ai_response_text)
    
    # RAG에도 AI 응답 저장
    try:
        msg_id_ai = f"msg_{session_id}_{uuid.uuid4().hex[:8]}"
        add_message_to_rag(msg_id_ai, session_id, "assistant", ai_response_text)
    except Exception as e:
        logger.error(f"RAG 저장 중 오류: {e}")
    
    logger.info(f"✅ [Agent] 응답 생성 완료: {ai_response_text[:50]}...")
    
    return {
        "reply_text": ai_response_text,
        "input_text": user_text,
        "emotion_result": emotion_result,
        "routine_result": routine_result,
        "meta": {
            "model": os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
            "used_tools": tool_results["used_tools"],
            "session_id": session_id,
            "stt_quality": stt_quality,
            "speaker_id": speaker_id,
            "memory_used": bool(memory_context),
            "rag_used": bool(rag_context)
        }
    }


def run_ai_bomi_from_audio(audio_bytes: bytes, session_id: str = "default") -> dict[str, Any]:
    """
    음성 입력 기반 AI 봄이 실행
    """
    logger.info(f"🎤 [Agent] 음성 입력 처리 시작 (세션: {session_id})")
    
    # 1. STT 실행
    stt_result = run_speech_to_text(audio_bytes)
    user_text = stt_result["text"]
    stt_quality = stt_result["quality"]
    
    # 음성 인식 실패 시 조기 종료
    if not user_text:
        return {
            "reply_text": "죄송해요, 잘 들리지 않았어요. 다시 말씀해주시겠어요?",
            "input_text": "",
            "emotion_result": None,
            "routine_result": None,
            "meta": {
                "stt_quality": stt_quality,
                "session_id": session_id
            }
        }
        
    # 2. 텍스트 기반 처리로 위임
    return run_ai_bomi_from_text(user_text, session_id, stt_quality)


if __name__ == "__main__":
    # 간단한 테스트
    print("Agent 테스트 시작...")
    
    # 1. 텍스트 테스트
    result = run_ai_bomi_from_text("요즘 잠이 잘 안 와서 너무 피곤해.", session_id="test_session")
    print("\n[테스트 결과]")
    print(f"사용자: {result['input_text']}")
    print(f"AI 봄이: {result['reply_text']}")
    print(f"감정: {result['emotion_result']['primary_emotion']['name_ko']}")
    
    # 2. 연속 대화 테스트
    print("\n[연속 대화 테스트]")
    result2 = run_ai_bomi_from_text("그래서 낮에도 계속 멍하고 집중이 안 돼.", session_id="test_session")
    print(f"사용자: {result2['input_text']}")
    print(f"AI 봄이: {result2['reply_text']}")