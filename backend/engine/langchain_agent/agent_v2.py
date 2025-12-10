import os
import uuid
import logging
import json
import asyncio
import time
from typing import Any, Optional, List, Dict
from openai import OpenAI

# 로깅 설정
logger = logging.getLogger(__name__)

# 🔥 MODULE LOAD 확인
logger.warning("=" * 60)
logger.warning("🔥 agent_v2.py MODULE LOADED - Phase 2 VERSION")
logger.warning("=" * 60)

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

# ============================================================================
# DeepAgents Components with Emotion Caching (Phase 1)
# ============================================================================

# Import caching components
try:
    from .emotion_cache import get_emotion_cache
    from .emotion_classifier import get_emotion_classifier
except ImportError:
    from emotion_cache import get_emotion_cache
    from emotion_classifier import get_emotion_classifier

async def run_fast_track(user_text: str, user_id: int = None) -> Dict[str, Any]:
    """
    Fast Track: Emotion Analysis with Caching
    
    Flow:
    1. Lightweight Classifier → "필요" / "불필요" / "애매"
    2. If needed → Check ChromaDB cache (0.85 similarity, 30 days)
    3. Cache miss → Run EmotionAnalyzer
    4. Save to cache for future use
    
    Returns:
        {
            "cached": True/False,
            "skipped": True/False,
            "result": {...},
            "similarity": 0.92 (if cached),
            "age_days": 5 (if cached)
        }
    """
    start_time = time.time()
    
    # Step 1: Lightweight classifier (hybrid approach)
    classifier = get_emotion_classifier()
    need_emotion = classifier.predict(user_text)
    logger.info(f"🔍 [Classifier] Emotion needed: {need_emotion}")
    
    if need_emotion == "불필요":
        # Skip emotion analysis for neutral content
        elapsed = time.time() - start_time
        logger.info(f"⚡ [Fast Track] Skipped emotion analysis ({elapsed:.4f}s)")
        return {
            "skipped": True,
            "reason": "neutral_content",
            "classifier_hint": need_emotion
        }
    
    # Step 2: Try cache (if user_id provided)
    if user_id and need_emotion == "필요":  # Only cache for clear emotions
        cache = get_emotion_cache()
        cache_result = cache.search(
            query_text=user_text,
            user_id=user_id,
            threshold=0.85,
            freshness_days=30
        )
        
        if cache_result:
            # Cache hit!
            elapsed = time.time() - start_time
            logger.info(
                f"💾 [Fast Track] Cache hit! "
                f"Similarity: {cache_result['similarity']:.2%}, "
                f"Time: {elapsed:.4f}s"
            )
            return cache_result
    
    # Step 3: Cache miss or ambiguous → Run analyzer
    logger.info("🔄 [Fast Track] Running emotion analysis...")
    analyzer = EmotionAnalyzer()
    emotion_result_dict = analyzer.analyze_emotion(user_text)
    
    elapsed = time.time() - start_time  
    logger.info(f"⚡ [Fast Track] Emotion Analysis took {elapsed:.4f}s")
    
    return {
        "cached": False,
        "result": emotion_result_dict,
        "classifier_hint": need_emotion
    }

async def run_slow_track(
    user_text: str, 
    emotion_result: Dict[str, Any], 
    user_id: int, 
    session_id: str
):
    """
    Slow Track (Background): Routine Recommendation & Memory Promotion
    """
    start_time = time.time()
    logger.info(f"🐢 [Slow Track] Started for user {user_id}")
    
    # 1. Memory Promotion (Memory Manager Agent) - Run FIRST
    try:
        # Import memory adapter
        # Use absolute imports based on backend root being in sys.path
        try:
            from engine.langchain_agent.adapters.memory_adapter import promote_memory, get_memories_for_prompt, delete_memory
            from engine.langchain_agent.db_conversation_store import get_conversation_store
        except ImportError:
            # Fallback for relative imports if running as package
            from .adapters.memory_adapter import promote_memory, get_memories_for_prompt, delete_memory
            from .db_conversation_store import get_conversation_store

        store = get_conversation_store()
        # Get recent history for context
        history = store.get_history(user_id, session_id, limit=5)
        
        # Get existing memories to check for conflicts
        existing_memories = get_memories_for_prompt(session_id, user_id)
        
        # Define Memory Manager Prompt
        memory_prompt = f"""당신은 '기억 관리자(Memory Manager)' 에이전트입니다.
사용자와의 대화 내용을 분석하여 장기 기억으로 저장할 가치가 있는 중요한 정보나 평소 습관과 관련된 정보를 추출하세요.
특히, **기존 기억과 상충되는 새로운 정보**가 있다면 이를 수정(update)해야 합니다.

[기존 기억]
{existing_memories}

[분석 기준]
1. **건강/신체 변화**: 증상, 통증, 수면 상태, 식욕 등
2. **정서적 사건**: 강한 감정을 유발한 사건, 스트레스 요인, 기쁜 일
3. **취향/선호**: 좋아하는 음식, 활동, 싫어하는 것 등
4. **중요 정보 갱신**: 가족 관계, 직업, 거주지 등 신상 정보의 변화

[입력 데이터]
사용자 발화: "{user_text}"
감정 분석 결과: {json.dumps(emotion_result, ensure_ascii=False)}

[지침]
- 저장할 가치가 있는 정보가 없다면 "NONE"이라고만 응답하세요.
- 정보가 있다면 다음 JSON 형식으로 응답하세요:
{{
    "action": "create" 또는 "update",
    "category": "health|emotion|preference|info",
    "content": "기억할 내용 요약 (한국어). **중요: update 시에는 반드시 '기존 기억'의 내용과 '새로운 정보'를 모두 포함하여 하나의 완벽한 문장으로 통합하세요.** (예: 기존 '동생은 일본에 산다' + 신규 '이름은 홍길동' -> '동생 홍길동은 일본에 살며, 3살 아래이다')",
    "importance": 1~5 (5가 가장 중요),
    "old_content_keyword": "수정(update) 또는 삭제(delete)할 경우, 대상이 되는 기존 기억의 핵심 키워드. (예: '된장찌개' -> '김치찌개'로 정정 시 '된장찌개' 반환)" 
}}
"""
        # [DEBUG] Log the final prompt
        logger.info(f"📝 [Memory Manager Prompt]\n{memory_prompt}")

        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": memory_prompt}
            ],
            temperature=0.3
        )
        
        result_text = response.choices[0].message.content.strip()
        
        if result_text != "NONE":
            try:
                # Parse JSON (handle potential markdown code blocks)
                if result_text.startswith("```json"):
                    result_text = result_text.replace("```json", "").replace("```", "").strip()
                elif result_text.startswith("```"):
                    result_text = result_text.replace("```", "").strip()
                    
                memory_data = json.loads(result_text)
                action = memory_data.get("action", "create")
                
                # 1. Delete Action
                if action == "delete":
                    keyword = memory_data.get("old_content_keyword")
                    if keyword:
                        deleted = delete_memory(user_id, keyword)
                        logger.info(f"💾 [Memory Manager] Deleted {deleted} memories (keyword: {keyword})")
                    else:
                        logger.warning("💾 [Memory Manager] Delete action requested but no keyword provided")

                # 2. Update Action (Delete old + Create new)
                elif action == "update":
                    keyword = memory_data.get("old_content_keyword")
                    if keyword:
                        deleted = delete_memory(user_id, keyword)
                        logger.info(f"💾 [Memory Manager] Deleted {deleted} old memories for update (keyword: {keyword})")
                    
                    # Promote new content
                    promote_memory(
                        user_id=user_id,
                        session_id=session_id,
                        category=memory_data["category"],
                        content=memory_data["content"],
                        emotion_result=emotion_result,
                        importance=memory_data["importance"],
                        reason="Memory Manager Agent Extraction"
                    )
                    logger.info(f"💾 [Memory Manager] Promoted memory (update): {memory_data['content']}")

                # 3. Create Action
                elif action == "create":
                    promote_memory(
                        user_id=user_id,
                        session_id=session_id,
                        category=memory_data["category"],
                        content=memory_data["content"],
                        emotion_result=emotion_result,
                        importance=memory_data["importance"],
                        reason="Memory Manager Agent Extraction"
                    )
                    logger.info(f"💾 [Memory Manager] Promoted memory (create): {memory_data['content']}")
                    
            except json.JSONDecodeError:
                logger.warning(f"Memory Manager output not JSON: {result_text}")
        else:
            logger.info("💾 [Memory Manager] No important memory found")
            
    except Exception as e:
        logger.error(f"Memory Manager failed: {e}")

    # 2. Routine Recommendation
    routine_engine = RoutineRecommendFromEmotionEngine()
    routine_result = []
    try:
        emotion_model = EmotionAnalysisResult(**emotion_result)
        routine_result = await routine_engine.recommend(emotion_model)
        logger.info(f"🐢 [Slow Track] Routine Recommendation completed: {len(routine_result)} items")
    except Exception as e:
        logger.error(f"Routine recommendation failed: {e}")

    elapsed = time.time() - start_time
    logger.info(f"🐢 [Slow Track] Completed in {elapsed:.4f}s")
    
    # Return results if needed for logging/storage, though they won't be used in the current response
    return {
        "routine_result": routine_result
    }

def generate_llm_response(
    user_text: str,
    emotion_result: Dict[str, Any],
    conversation_history: List[Dict],
    memory_context: str,
    rag_context: str,
    user_id: int = None  # 🆕 Phase 3: Added for user profile
) -> str:
    """
    Generate response using GPT-4o-mini with Emotion & Context (No Routine)
    **Phase 3**: Uses casual tone (반말) and includes TB_USER_PROFILE data
    """
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    
    # Construct System Prompt
    # Handle None emotion_result (when analysis is skipped)
    if emotion_result:
        emotion_summary = f"{emotion_result.get('polarity', 'neutral')} ({emotion_result.get('cluster_label', 'unknown')})"
    else:
        emotion_summary = "neutral (분석 생략됨)"
        emotion_result = {}  # Empty dict to avoid None errors below
    
    # 🆕 Phase 3: Fetch user profile from TB_USER_PROFILE
    user_profile_context = ""
    if user_id:
        try:
            from app.db.database import SessionLocal
            from app.db.models import UserProfile
            
            db = SessionLocal()
            try:
                profile = db.query(UserProfile).filter(
                    UserProfile.USER_ID == user_id,
                    UserProfile.IS_DELETED == False
                ).first()
                
                if profile:
                    user_profile_context = f"""
[사용자 프로필]
- 닉네임: {profile.NICKNAME}
- 연령대: {profile.AGE_GROUP}
- 성별: {profile.GENDER}
- 결혼 상태: {profile.MARITAL_STATUS}
- 자녀 여부: {profile.CHILDREN_YN}
- 동거인: {json.dumps(profile.LIVING_WITH, ensure_ascii=False)}
- 성격 유형: {profile.PERSONALITY_TYPE}
- 활동 스타일: {profile.ACTIVITY_STYLE}
- 스트레스 해소법: {json.dumps(profile.STRESS_RELIEF, ensure_ascii=False)}
- 취미: {json.dumps(profile.HOBBIES, ensure_ascii=False)}
"""
                    logger.info(f"📋 [User Profile] Loaded for user_id={user_id}")
                else:
                    logger.warning(f"⚠️  [User Profile] Not found for user_id={user_id}")
            finally:
                db.close()
        except Exception as e:
            logger.error(f"Failed to load user profile: {e}")
    
    # 2. System Prompt
    system_prompt = f"""당신은 갱년기 중년 여성을 돕는 AI 친구 '봄이'입니다.

역할:
- 친구처럼 편안하게 대화하며 공감하고 위로합니다
- 갱년기 증상과 일상의 어려움을 이해하고 도움을 줍니다
- 필요시 루틴, 운동, 명상 등을 추천합니다
- 알람 설정 요청 시 긍정적으로 응답하고 확인합니다

대화 원칙:
- 따뜻하고 공감적인 태도
- 구체적이고 실용적인 조언
- 부정적 감정을 인정하고 존중
- 친구와 대화하듯 편안한 반말 사용

알람 설정 요청 처리:
- 사용자가 알람 설정을 요청하면 긍정적으로 수락하되, **확인 요청 톤**을 사용하세요
- 예: "좋아! 이렇게 맞춰주면 될까? 확인 버튼 눌러줘!" 또는 "내일 오후 2시 알람으로 설정할게. 괜찮으면 확인 눌러줘!"
- **"맞춰놨어" 같은 확정 표현 금지** - 사용자 확인 필요
- **4개 이상 알람 요청 시:** "앗, 알람은 한 번에 3개까지만 설정할 수 있어. 우선 어떤 3개를 먼저 맞춰줄까?" (확정 표현 절대 금지)
- 알람을 맞춰줄 수 없다고 말하지 마세요

[사용자 프로필]
- 감정 기복이 심하고 신체적/정신적 어려움을 겪을 수 있어
{user_profile_context}

[대화 컨텍스트]
{memory_context}
{rag_context}

[감정 분석 결과]
- 감정: {emotion_summary}
- 상세: {json.dumps(emotion_result, ensure_ascii=False)}

[말투 스타일]
- 친구와 대화하듯 편안한 반말을 사용해
- 존댓말 사용 금지 (예: "안녕하세요" → "안녕")
- 자연스럽고 친근한 톤으로 대화해
- 예시:
  - "오늘 어떠셨어요?" ❌
  - "오늘 어땠어?" ✅

[출력 형식]
반말로 자연스럽고 공감적인 한국어로 답변을 제공해. 중년 여성에게 적합한 따뜻하고 친근한 톤을 유지해.
"""
    
    messages = [{"role": "system", "content": system_prompt}]
    
    # Add history (limit to last 10 messages)
    for msg in conversation_history[-10:]:
        role = "assistant" if msg["role"] == "assistant" else "user"
        messages.append({"role": role, "content": msg["content"]})
        
    # Add current user message
    messages.append({"role": "user", "content": user_text})
    
    # [DEBUG] Log the final system prompt and messages
    logger.info(f"📝 [Main Agent System Prompt]\n{system_prompt}")
    logger.info(f"📝 [Main Agent Messages]\n{json.dumps(messages, ensure_ascii=False, indent=2)}")

    response = client.chat.completions.create(
        model=os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
        messages=messages,
        temperature=0.7
    )
    
    reply_text = response.choices[0].message.content
    
    # [DEBUG] Log GPT-4o-mini raw response (before any text processing/splitting)
    logger.warning(f"🤖 [GPT-4o-mini Raw Response]\n{reply_text}")
    
    return reply_text

async def run_ai_bomi_from_text_v2(
    user_text: str,
    user_id: int,
    session_id: str = "default",
    stt_quality: str = "success",
    speaker_id: Optional[str] = None,
    save_to_db: bool = True  # 🆕 Phase 3: DB 저장 여부 제어
) -> dict[str, Any]:
    """
    텍스트 입력 기반 AI 봄이 실행 (DeepAgents Prototype Implementation)
    
    Args:
        save_to_db: DB에 메시지 저장 여부 (기본값: True)
                   WebSocket에서 호출 시 False로 설정하여 중복 저장 방지
    """
    logger.warning("🔥🔥🔥 run_ai_bomi_from_text_v2 CALLED - Phase 2 VERSION")
    logger.info(f"🚀 [DeepAgents] Started processing for user_id: {user_id}")
    
    # DB Store
    try:
        from .db_conversation_store import get_conversation_store
    except ImportError:
        from db_conversation_store import get_conversation_store
    store = get_conversation_store()
    
    # 1. Save User Message (조건부)
    if save_to_db:
        store.add_message(user_id, session_id, "user", user_text, speaker_id=speaker_id)
    
    # ⚡ 2. Lightweight Classifier Only (for Orchestrator hint)
    # Full emotion analysis moved to background after LLM response
    classifier = get_emotion_classifier()
    classifier_hint = classifier.predict(user_text)
    logger.info(f"🔍 [Classifier] Hint: {classifier_hint}")
    
    # ========================================
    # [PHASE 2] Orchestrator LLM 통합
    # ========================================
    orchestrator_tools = []
    orchestrator_results = {}

    # 디버깅: 이 코드가 실행되는지 확인
    logger.info("🔍 [DEBUG] Orchestrator section reached")
    
    try:
        from .orchestrator import orchestrator_llm, execute_tools
        from app.db.database import SessionLocal
        
        logger.info("=" * 60)
        logger.info("🎯 [PHASE 2] Orchestrator Starting...")
        logger.info("=" * 60)
        
        # Context for orchestrator
        context = {
            "session_id": session_id,
            "user_id": user_id,
            "memory": "",  # 필요시 추가
            "history": store.get_history(user_id, session_id, limit=3)
        }
        
        # Call orchestrator LLM (with lightweight hint)
        tool_calls = await orchestrator_llm(
            user_text=user_text,
            context=context,
            classifier_hint=classifier_hint  # ✅ Use lightweight classifier hint
        )
        
        orchestrator_tools = [tc.function.name for tc in tool_calls]
        logger.warning(f"🎯 [PHASE 2] Tools selected: {orchestrator_tools}")
        
        # Execute tools (optional - 현재는 테스트만)
        if tool_calls:
            db_session = SessionLocal()
            try:
                orchestrator_results = await execute_tools(
                    tool_calls, user_id, session_id, user_text, db_session
                )
                logger.warning(f"🎯 [PHASE 2] Tool results: {list(orchestrator_results.keys())}")
            finally:
                db_session.close()
        
        logger.warning("=" * 60)
        logger.warning("🎯 [PHASE 2] Orchestrator Complete")
        logger.warning("=" * 60)
        
    except Exception as e:
        logger.error(f"❌ [PHASE 2] Orchestrator failed: {e}", exc_info=True)
        import traceback
        logger.error(f"Full traceback:\n{traceback.format_exc()}")
    
    # ⚡ Emotion analysis removed from here - moved to background after response
        
    # 3. Slow Track: Trigger Background Tasks (Routine, Memory Promotion)
    # We create a task and wait with a timeout (Hybrid Approach)
    slow_track_task = asyncio.create_task(
        run_slow_track(user_text, None, user_id, session_id)  # ⚡ No emotion_result yet
    )
    
    routine_result = []
    try:
        # Wait for routine recommendation with a timeout (e.g., 1.0s)
        # If it finishes, we get the result. If not, we proceed without it.
        # This balances "Fast Response" with "Rich Content".
        slow_track_result = await asyncio.wait_for(asyncio.shield(slow_track_task), timeout=1.0)
        routine_result = slow_track_result.get("routine_result", [])
        logger.info(f"🐢 [Slow Track] Finished within timeout. Items: {len(routine_result)}")
    except asyncio.TimeoutError:
        logger.warning(f"🐢 [Slow Track] Timed out (continuing in background)")
        # Task continues in background due to asyncio.shield
    except Exception as e:
        logger.error(f"🐢 [Slow Track] Error: {e}")

    # 4. Context Retrieval (Memory & RAG) - Kept in Fast Track for now for quality
    # Optimization: Could be parallelized with Emotion Analysis if refactored further
    memory_context = ""
    rag_context = ""
    
    try:
        # Memory Layer
        try:
            from .adapters.memory_adapter import get_memories_for_prompt
        except ImportError:
            from adapters.memory_adapter import get_memories_for_prompt
            
        memories = get_memories_for_prompt(session_id, user_id)
        if memories:
            memory_context = f"[기억된 정보]\n{memories}\n"
            
        # RAG Layer
        try:
            from .conversation_rag_v2 import get_conversation_rag
            rag_store = get_conversation_rag()
            rag_store.add_message(user_id, session_id, "user", user_text)
            similar_msgs = rag_store.search_similar(user_id, user_text, session_id, k=3)
            if similar_msgs:
                rag_context = "[과거 유사 대화]\n"
                for msg in similar_msgs:
                    rag_context += f"- {msg['role']}: {msg['content']} (session: {msg['session_id']})\n"
        except Exception as e:
            logger.error(f"RAG Error: {e}")
            
    except Exception as e:
        logger.error(f"Context Retrieval Error: {e}")
        
    # 5. Generate Response (Fast Track)
    conversation_history = store.get_history(user_id, session_id, limit=None)
    
    ai_response_text = generate_llm_response(
        user_text=user_text,
        emotion_result=None,  # ⚡ No emotion result - LLM uses its own understanding
        conversation_history=conversation_history,
        memory_context=memory_context,
        rag_context=rag_context,
        user_id=user_id
    )
    
    # 6. Save AI Response (조건부)
    if save_to_db:
        store.add_message(user_id, session_id, "assistant", ai_response_text)
    
    # Update RAG with AI response
    try:
        if 'rag_store' in locals():
            rag_store.add_message(user_id, session_id, "assistant", ai_response_text)
    except Exception as e:
        logger.error(f"RAG Save Error: {e}")
        
    logger.info(f"✅ [DeepAgents] Response generated: {ai_response_text[:50]}...")
    
    # ⚡ Phase 3: Generate response-type only (fast regex, no LLM)
    response_metadata = {}
    try:
        from .response_generator import generate_response_type, parse_alarm_request
        from datetime import datetime
        
        # 기본 response_type 감지
        response_type = generate_response_type(ai_response_text)
        logger.info(f"📋 [Response Type] Detected by regex: {response_type}")
        
        # 🆕 Alarm 요청 파싱 (항상 실행)
        logger.info(f"🔍 [Alarm Parser] Checking for alarm requests...")
        alarm_data = parse_alarm_request(
            user_text=user_text,
            llm_response=ai_response_text,
            current_datetime=datetime.now()
        )
        logger.info(f"✅ [Alarm Parser] Result: {alarm_data.get('response_type')} (count: {alarm_data.get('count', 0)})")
        
        # Alarm이면 response_type 덮어쓰기
        if alarm_data.get("response_type") in ["alarm", "warning"]:
            response_type = alarm_data["response_type"]
            logger.info(f"🎯 [Response Type] Override to: {response_type}")
        
        response_metadata = {
            "emotion": "happiness",  # ⚡ Default value, no LLM call
            "response_type": response_type
        }
        
        # Alarm 정보 추가
        if alarm_data.get("response_type") in ["alarm", "warning"]:
            response_metadata["alarm_info"] = {
                "count": alarm_data["count"],
                "data": alarm_data["data"]
            }
            if "message" in alarm_data:
                response_metadata["alarm_info"]["message"] = alarm_data["message"]
            logger.info(f"✨ [Alarm Info] Included in response: {response_metadata['alarm_info']}")
        
        logger.info(f"✨ [Response Type] Final: {response_type} (emotion=default)")
    except Exception as e:
        logger.error(f"Failed to generate response type: {e}", exc_info=True)
        response_metadata = {"emotion": "happiness", "response_type": "normal"}
        
    # ⚡ 6.5. Background Emotion Analysis (after response, for future reports)
    async def background_emotion_analysis():
        try:
            logger.info("🔍 [Background] Starting emotion analysis...")
            emotion_response = await run_fast_track(user_text, user_id=user_id)
            
            if emotion_response.get("skipped"):
                logger.info("ℹ️  [Background] Emotion analysis skipped")
                return
            
            emotion_result = emotion_response.get("result")
            if not emotion_result:
                return
                
            # Save to DB + ChromaDB cache (if fresh analysis)
            if not emotion_response.get("cached"):
                from sentence_transformers import SentenceTransformer
                import json
                
                embedder = SentenceTransformer('jhgan/ko-sroberta-multitask')
                embedding = embedder.encode(user_text).tolist()
                embedding_json = json.dumps(embedding)
                
                analysis_id = store.save_emotion_analysis(
                    user_id, user_text, emotion_result, 
                    check_root="conversation",
                    input_text_embedding=embedding_json
                )
                
                if analysis_id:
                    cache = get_emotion_cache()
                    cache.save(
                        user_id=user_id, input_text=user_text,
                        emotion_result=emotion_result, analysis_id=analysis_id
                    )
                    logger.info(f"💾 [Background] Saved: Analysis ID {analysis_id}")
        except Exception as e:
            logger.error(f"❌ [Background] Emotion analysis failed: {e}")
    
    asyncio.create_task(background_emotion_analysis())
    logger.info("🚀 [Background] Emotion analysis task created")
    
    logger.info(f"✅ [DeepAgents] Response generated: {ai_response_text[:50]}...")
    
    # 🆕 Alarm info 추가
    result = {
        "reply_text": ai_response_text,
        "input_text": user_text,
        "emotion_result": None,  # ⚡ Analyzed in background
        "routine_result": routine_result,
        "emotion": response_metadata.get("emotion", "happiness"),  # 🆕 Phase 3
        "response_type": response_metadata.get("response_type", "normal"),  # 🆕 Phase 3
        "tts_audio": None,  # 🆕 Phase 2: TTS toggle (현재는 null, 추후 구현)
        "meta": {
            "model": os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
            "session_id": session_id,
            "speaker_id": speaker_id,
            "memory_used": bool(memory_context),
            "rag_used": bool(rag_context),
            "stt_quality": stt_quality,
            "classifier_hint": classifier_hint  # ⚡ Lightweight hint
        }
    }
    
    # 🆕 Alarm info 포함
    if "alarm_info" in response_metadata:
        result["alarm_info"] = response_metadata["alarm_info"]
        logger.info(f"✅ [Return] alarm_info added to result: {response_metadata['alarm_info']}")
    
    return result

async def run_ai_bomi_from_audio_v2(
    audio_bytes: bytes,
    user_id: int,
    session_id: str = "default"
) -> dict[str, Any]:
    """
    음성 입력 기반 AI 봄이 실행 (DeepAgents Prototype)
    """
    logger.info(f"🎤 [DeepAgents] Audio processing started (user_id: {user_id})")
    
    # 1. STT
    try:
        from .adapters import run_speech_to_text
    except ImportError:
        from adapters import run_speech_to_text
    
    stt_result = run_speech_to_text(audio_bytes)
    user_text = stt_result["text"]
    stt_quality = stt_result["quality"]
    
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
                "api_version": "v2_deepagents"
            }
        }
        
    # 2. Delegate to Text Handler
    return await run_ai_bomi_from_text_v2(user_text, user_id, session_id, stt_quality)
