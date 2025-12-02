import os
import uuid
import logging
import json
from typing import Any, Optional, List, Dict
from openai import OpenAI

# 로깅 설정
logger = logging.getLogger(__name__)

# Tool Imports
import sys
from pathlib import Path

# Add backend root to sys.path to ensure engine imports work
current_file = Path(__file__).resolve()
backend_root = current_file.parent.parent.parent
if str(backend_root) not in sys.path:
    sys.path.insert(0, str(backend_root))

# Import EmotionAnalyzer (handling hyphen in directory name)
try:
    # Try standard import first (in case it's renamed or aliased)
    from engine.emotion_analysis.src.emotion_analyzer import EmotionAnalyzer
except ImportError:
    # Fallback: Add emotion-analysis/src to sys.path
    emotion_src = backend_root / "engine" / "emotion-analysis" / "src"
    if str(emotion_src) not in sys.path:
        sys.path.insert(0, str(emotion_src))
    try:
        from emotion_analyzer import EmotionAnalyzer
    except ImportError as e:
        logger.error(f"Failed to import EmotionAnalyzer: {e}")
        raise

# Import RoutineRecommendFromEmotionEngine and schemas
try:
    from engine.routine_recommend.engine import RoutineRecommendFromEmotionEngine
    from engine.routine_recommend.models.schemas import EmotionAnalysisResult
except ImportError as e:
    logger.error(f"Failed to import RoutineRecommendFromEmotionEngine or schemas: {e}")
    raise

async def route_tools(user_text: str) -> Dict[str, Any]:
    """
    Analyze text and route to appropriate tools (Emotion, Routine)
    """
    # 1. Emotion Analysis
    analyzer = EmotionAnalyzer()
    emotion_result_dict = analyzer.analyze_emotion(user_text)
    
    # 2. Routine Recommendation
    routine_engine = RoutineRecommendFromEmotionEngine()
    
    # Convert dict to Pydantic model for Routine Engine
    try:
        emotion_model = EmotionAnalysisResult(**emotion_result_dict)
        # recommend is async
        routine_result = await routine_engine.recommend(emotion_model)
    except Exception as e:
        logger.error(f"Routine recommendation failed: {e}")
        routine_result = []
    
    return {
        "emotion_result": emotion_result_dict,
        "routine_result": routine_result,
        "used_tools": ["emotion_analysis", "routine_recommend"]
    }

def generate_llm_response(
    user_text: str,
    emotion_result: Dict[str, Any],
    routine_result: List[Any],
    conversation_history: List[Dict],
    memory_context: str,
    rag_context: str
) -> str:
    """
    Generate response using GPT-4o-mini with all context
    """
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    
    # Construct System Prompt
    # 감정 분석 결과 요약
    emotion_summary = f"{emotion_result.get('polarity', 'neutral')} ({emotion_result.get('cluster_label', 'unknown')})"
    
    system_prompt = f"""당신은 갱년기 여성을 위한 공감형 AI 친구 '봄이'입니다.
사용자의 감정에 깊이 공감하고, 따뜻한 위로와 실질적인 조언을 제공하세요.

[사용자 프로필]
- 40~50대 갱년기 여성
- 감정 기복이 심하고 신체적/정신적 어려움을 겪을 수 있음

[대화 컨텍스트]
{memory_context}
{rag_context}

[감정 분석 결과]
- 감정: {emotion_summary}
- 상세: {json.dumps(emotion_result, ensure_ascii=False)}

[추천 루틴]
{json.dumps([r.dict() for r in routine_result] if routine_result else [], ensure_ascii=False)}

[지침]
1. 공감 우선: 사용자의 감정을 읽어주고 공감하는 말을 먼저 하세요.
2. 루틴 제안: 추천된 루틴이 있다면 자연스럽게 권유하세요. (강요하지 않음)
3. 짧고 간결하게: 너무 긴 답변보다는 대화하듯 편안하게 작성하세요.
4. 한국어 사용: 자연스러운 한국어 구어체를 사용하세요.
"""

    messages = [{"role": "system", "content": system_prompt}]
    
    # Add history (limit to last 10 messages to save tokens)
    for msg in conversation_history[-10:]:
        role = "assistant" if msg["role"] == "assistant" else "user"
        messages.append({"role": role, "content": msg["content"]})
        
    # Add current user message
    messages.append({"role": "user", "content": user_text})
    
    response = client.chat.completions.create(
        model=os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
        messages=messages,
        temperature=0.7
    )
    
    return response.choices[0].message.content

async def run_ai_bomi_from_text_v2(
    user_text: str,
    user_id: int,
    session_id: str = "default",
    stt_quality: str = "success",
    speaker_id: Optional[str] = None
) -> dict[str, Any]:
    """
    텍스트 입력 기반 AI 봄이 실행 (V2 - DB 저장)
    
    Args:
        user_text: 사용자 입력 텍스트
        user_id: User ID (for DB storage and data isolation)
        session_id: Session identifier
        stt_quality: STT quality indicator
        speaker_id: Speaker identifier (optional)
    
    Returns:
        Agent response dictionary
    """
    logger.info(f"🚀 [Agent V2] 텍스트 입력 처리 시작 (user_id: {user_id}, session: {session_id})")
    
    # DB 기반 저장소 가져오기
    try:
        from .db_conversation_store import get_conversation_store
    except ImportError:
        from db_conversation_store import get_conversation_store
    
    store = get_conversation_store()
    
    # 1. 사용자 메시지 저장 (DB에 저장)
    store.add_message(user_id, session_id, "user", user_text, speaker_id=speaker_id)
    
    # 2. Tool Routing (감정 분석 등)
    tool_results = await route_tools(user_text)
    emotion_result = tool_results["emotion_result"]
    routine_result = tool_results["routine_result"]
    
    # 2.5 Save Emotion Analysis
    try:
        store.save_emotion_analysis(user_id, user_text, emotion_result, check_root="conversation")
    except Exception as e:
        logger.error(f"Failed to save emotion analysis: {e}")
    
    # 3. Memory Layer & RAG Context Retrieval (기존 로직 재사용)
    memory_context = ""
    rag_context = ""
    
    try:
        # 3-1. Memory Layer (장기 기억) - 일단 기존 JSON 기반 사용
        try:
            from .adapters.memory_adapter import should_store_memory, add_memory, get_memories_for_prompt
        except ImportError:
            from adapters.memory_adapter import should_store_memory, add_memory, get_memories_for_prompt
        
        # 저장 여부 판단 및 저장
        if should_store_memory(user_text, emotion_result):
            add_memory(user_text, emotion_result, session_id, user_id)
            
        # 관련 기억 조회
        memories = get_memories_for_prompt(session_id, user_id)
        if memories:
            memory_context = f"[기억된 정보]\n{memories}\n"
            
        # 3-2. Conversation RAG (과거 대화) - V2 복구
        try:
            from .conversation_rag_v2 import get_conversation_rag
            rag_store = get_conversation_rag()
            
            # 현재 메시지를 RAG에 저장
            rag_store.add_message(user_id, session_id, "user", user_text)
            
            # 관련 대화 조회 (현재 세션 제외)
            similar_msgs = rag_store.search_similar(user_id, user_text, session_id, k=3)
            if similar_msgs:
                rag_context = "[과거 유사 대화]\n"
                for msg in similar_msgs:
                    rag_context += f"- {msg['role']}: {msg['content']} (session: {msg['session_id']})\n"
                rag_context += "\n"
                logger.info(f"🔍 [RAG] Found {len(similar_msgs)} similar messages")
                
        except Exception as e:
            logger.error(f"RAG 처리 중 오류 (무시하고 진행): {e}")
            
    except Exception as e:
        logger.error(f"Memory/RAG 처리 중 오류 (무시하고 진행): {e}")
    
    # 4. 대화 히스토리 조회 (DB에서 조회)
    conversation_history = store.get_history(user_id, session_id, limit=None)
    
    # 5. LLM 응답 생성
    ai_response_text = generate_llm_response(
        user_text=user_text,
        emotion_result=emotion_result,
        routine_result=routine_result,
        conversation_history=conversation_history,
        memory_context=memory_context,
        rag_context=rag_context
    )
    
    # 6. AI 응답 저장 (DB에 저장)
    store.add_message(user_id, session_id, "assistant", ai_response_text)
    
    # RAG에도 AI 응답 저장 (V2 복구)
    try:
        if 'rag_store' in locals():
            rag_store.add_message(user_id, session_id, "assistant", ai_response_text)
    except Exception as e:
        logger.error(f"RAG 저장 중 오류: {e}")
    
    logger.info(f"✅ [Agent V2] 응답 생성 완료 (DB 저장): {ai_response_text[:50]}...")
    
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
            "rag_used": bool(rag_context),
            "user_id": user_id,
            "storage": "database",  # V2 구분자
            "api_version": "v2"
        }
    }


async def run_ai_bomi_from_audio_v2(
    audio_bytes: bytes,
    user_id: int,
    session_id: str = "default"
) -> dict[str, Any]:
    """
    음성 입력 기반 AI 봄이 실행 (V2 - DB 저장)
    
    Args:
        audio_bytes: Audio data
        user_id: User ID (for DB storage)
        session_id: Session identifier
    """
    logger.info(f"🎤 [Agent V2] 음성 입력 처리 시작 (user_id: {user_id}, session: {session_id})")
    
    # 1. STT 실행 (기존 로직 재사용)
    try:
        from .adapters import run_speech_to_text
    except ImportError:
        from adapters import run_speech_to_text
    
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
                "session_id": session_id,
                "user_id": user_id,
                "storage": "database",
                "api_version": "v2"
            }
        }
        
    # 2. 텍스트 기반 처리로 위임 (V2 함수 사용)
    return await run_ai_bomi_from_text_v2(user_text, user_id, session_id, stt_quality)
