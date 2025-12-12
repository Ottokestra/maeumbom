"""
Orchestrator LLM Implementation

Analyzes user intent and selects appropriate tools to execute.
Phase 2 of the 2-Tier Orchestrator architecture.
"""
from openai import OpenAI
import json
import os
import logging
from typing import List, Dict, Optional, Any
from datetime import datetime

from .tools import TOOLS
from .emotion_cache import get_emotion_cache
from app.db.models import AgentPlan

logger = logging.getLogger(__name__)


async def orchestrator_llm(
    user_text: str,
    context: Dict
) -> List:
    """
    Orchestrator: 사용자 의도 파악 및 도구 선택
    
    Args:
        user_text: 사용자 입력
        context: 대화 컨텍스트 (memory, history 등)
        
    Returns:
        tool_calls: OpenAI tool_calls 리스트
    """
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    
    # Build system prompt with context
    system_prompt = f"""You are an **Orchestrator** for an AI companion assisting middle-aged women experiencing menopause.

Your role is to analyze user input and select appropriate tools to execute.

[Tool Selection Principles]
1. **Emotion Analysis** (if emotional content detected):
   - ALWAYS try search_emotion_cache() FIRST
   - Only call analyze_emotion() if you predict cache will miss
   
2. **Routine Recommendation**:
   - User expresses difficulty/stress or explicitly requests recommendations
   - Requires emotion analysis result first
   
3. **Plan Saving**:
   - User mentions future plans: "내일 ~하려고", "~하기로 했어", "~할 예정"
   - Examples: "내일 아침 명상하려고 해" → save_plan(type="routine", ...)
   
4. **Memory Search**:
   - Need past conversation context or user information
   - Examples: "지난주에 뭐라고 했지?" → search_memory()

[User Input]
{user_text}

[Context]
- Session: {context.get('session_id', 'unknown')}
- Recent Memory Exists: {bool(context.get('memory', ''))}

**Instructions:**
- Select tools based on user intent analysis
- Call tools in logical dependency order (cache before analysis, emotion before routine)
- Do NOT call tools unnecessarily (avoid over-engineering)
- You can call 0 tools if just responding is sufficient
"""

    messages = [{"role": "system", "content": system_prompt}]
    
    # Add recent history for better context
    history = context.get('history', [])
    if history:
        for msg in history[-3:]:  # Last 3 messages
            role = "assistant" if msg.get("role") == "assistant" else "user"
            content = msg.get("content", "")
            if content:  # Skip empty messages
                messages.append({"role": role, "content": content})
    
    # Current user message
    messages.append({"role": "user", "content": user_text})
    
    try:
        logger.warning(f"🎯 [Orchestrator] Analyzing intent...")
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            tools=TOOLS,
            tool_choice="auto",
            temperature=0.3  # Low temperature for consistent tool selection
        )
        
        tool_calls = response.choices[0].message.tool_calls or []
        
        tool_names = [tc.function.name for tc in tool_calls]
        logger.warning(
            f"🎯 [Orchestrator] Selected {len(tool_calls)} tools: {tool_names}"
        )
        
        return tool_calls
        
    except Exception as e:
        logger.error(f"❌ [Orchestrator] Failed: {e}", exc_info=True)
        return []


async def execute_tools(
    tool_calls: List,
    user_id: int,
    session_id: str,
    user_text: str,
    db_session  # SQLAlchemy session
) -> Dict[str, Any]:
    """
    도구 실행 및 결과 집계
    
    Args:
        tool_calls: Orchestrator가 선택한 도구 목록
        user_id: 사용자 ID
        session_id: 세션 ID
        user_text: 원본 사용자 입력
        db_session: SQLAlchemy session
        
    Returns:
        results: 도구 실행 결과 딕셔너리
    """
    if not tool_calls:
        logger.warning("ℹ️  [Tools] No tools selected by orchestrator")
        return {}
    
    results = {}
    
    # Import dependencies
    try:
        from ...emotion_analysis.src.emotion_analyzer import EmotionAnalyzer
    except ImportError:
        try:
            from emotion_analysis.src.emotion_analyzer import EmotionAnalyzer
        except ImportError:
            logger.error("Failed to import EmotionAnalyzer")
            EmotionAnalyzer = None
    
    try:
        from .db_conversation_store import get_conversation_store
    except ImportError:
        from db_conversation_store import get_conversation_store
    
    try:
        from .adapters.memory_adapter import get_memories_for_prompt
    except ImportError:
        from adapters.memory_adapter import get_memories_for_prompt
    
    try:
        from engine.routine_recommend.engine import RoutineRecommendFromEmotionEngine
        from engine.routine_recommend.models.schemas import EmotionAnalysisResult
    except ImportError:
        logger.warning("RoutineRecommendFromEmotionEngine not available")
        RoutineRecommendFromEmotionEngine = None
        EmotionAnalysisResult = None
    
    store = get_conversation_store()
    cache = get_emotion_cache()
    
    for tool_call in tool_calls:
        func_name = tool_call.function.name
        
        try:
            args = json.loads(tool_call.function.arguments)
            logger.warning(f"🔧 [Tool] Executing: {func_name}")
            
            # ===== 1. search_emotion_cache =====
            if func_name == "search_emotion_cache":
                cache_result = cache.search(
                    query_text=args.get("text", user_text),
                    user_id=user_id,
                    threshold=0.85,
                    freshness_days=30
                )
                
                if cache_result:
                    results["emotion"] = cache_result
                    logger.warning(
                        f"✅ [search_emotion_cache] Hit! "
                        f"Similarity: {cache_result['similarity']:.2%}, "
                        f"Age: {cache_result['age_days']} days"
                    )
                else:
                    results["emotion_cache_miss"] = True
                    logger.warning("❌ [search_emotion_cache] Miss")
            
            # ===== 2. analyze_emotion =====
            elif func_name == "analyze_emotion":
                # Check if EmotionAnalyzer is available
                if not EmotionAnalyzer:
                    logger.error("❌ [analyze_emotion] EmotionAnalyzer not available")
                    results["analyze_emotion_error"] = "EmotionAnalyzer import failed"
                    continue
                
                # Skip if already cached
                if "emotion" in results and results["emotion"].get("cached"):
                    logger.warning("⏭️  [analyze_emotion] Skipped (cache hit)")
                    continue
                
                analyzer = EmotionAnalyzer()
                emotion_result = analyzer.analyze_emotion(args.get("text", user_text))
                
                # Save to DB
                try:
                    analysis_id = store.save_emotion_analysis(
                        user_id, user_text, emotion_result, check_root="conversation"
                    )
                    
                    # Save to cache for future use
                    if analysis_id:
                        cache.save(
                            user_id=user_id,
                            input_text=user_text,
                            emotion_result=emotion_result,
                            analysis_id=analysis_id
                        )
                        logger.warning(f"💾 [analyze_emotion] Saved to cache (ID: {analysis_id})")
                except Exception as e:
                    logger.error(f"Failed to save emotion  analysis: {e}")
                
                results["emotion"] = {
                    "cached": False,
                    "result": emotion_result
                }
                logger.warning(f"✅ [analyze_emotion] Completed")
            
            # ===== 3. recommend_routine =====
            elif func_name == "recommend_routine":
                if not RoutineRecommendFromEmotionEngine:
                    logger.warning("⚠️  [recommend_routine] Engine not available")
                    continue
                
                emotion = results.get("emotion", {}).get("result")
                
                if not emotion:
                    logger.warning("⚠️  [recommend_routine] No emotion result available")
                    continue
                
                # Convert to EmotionAnalysisResult format
                try:
                    emotion_obj = EmotionAnalysisResult(
                        cluster_label=emotion.get("cluster_label", "neutral"),
                        polarity=emotion.get("polarity", "neutral"),
                        raw_distribution=emotion.get("raw_distribution", {}),
                        primary_emotion=emotion.get("primary_emotion", {}),
                        secondary_emotions=emotion.get("secondary_emotions", []),
                        sentiment_overall=emotion.get("sentiment_overall", "neutral"),
                        service_signals=emotion.get("service_signals", {}),
                        recommended_response_style=emotion.get("recommended_response_style", []),
                        recommended_routine_tags=emotion.get("recommended_routine_tags", [])
                    )
                    
                    engine = RoutineRecommendFromEmotionEngine()
                    routines = await engine.recommend(
                        emotion=emotion_obj,
                        hours_since_wake=None,
                        hours_to_sleep=None,
                        city=None,
                        country=None
                    )
                    
                    results["routines"] = routines
                    logger.warning(f"✅ [recommend_routine] {len(routines)} routines recommended")
                except Exception as e:
                    logger.error(f"Failed to recommend routines: {e}", exc_info=True)
                    results["recommend_routine_error"] = str(e)
            
            # ===== 4. save_plan =====
            elif func_name == "save_plan":
                try:
                    plan = AgentPlan(
                        USER_ID=user_id,
                        PLAN_TYPE=args["plan_type"],
                        TARGET_DATE=args.get("target_date"),
                        CONTENT=json.dumps(args["content"], ensure_ascii=False),
                        STATUS="pending",
                        SOURCE_SESSION_ID=session_id
                    )
                    
                    db_session.add(plan)
                    db_session.commit()
                    db_session.refresh(plan)
                    
                    results["plan_saved"] = {
                        "id": plan.ID,
                        "type": plan.PLAN_TYPE,
                        "target_date": str(plan.TARGET_DATE) if plan.TARGET_DATE else None,
                        "content": args["content"]
                    }
                    logger.warning(f"✅ [save_plan] Saved plan ID: {plan.ID} (type: {plan.PLAN_TYPE})")
                except Exception as e:
                    logger.error(f"Failed to save plan: {e}", exc_info=True)
                    db_session.rollback()
                    results["save_plan_error"] = str(e)
            
            # ===== 5. search_memory =====
            elif func_name == "search_memory":
                try:
                    query = args.get("query", "")
                    memories = get_memories_for_prompt(session_id, user_id)
                    
                    # Simple keyword search in memories
                    relevant = []
                    if query and memories:
                        for line in memories.split('\n'):
                            if query in line:
                                relevant.append(line)
                    
                    results["memory_search"] = {
                        "query": query,
                        "results": relevant if relevant else memories,
                        "found_count": len(relevant)
                    }
                    logger.warning(f"✅ [search_memory] Query: '{query}', Found: {len(relevant)} relevant items")
                except Exception as e:
                    logger.error(f"Failed to search memory: {e}", exc_info=True)
                    results["search_memory_error"] = str(e)
        
        except json.JSONDecodeError as e:
            logger.error(f"❌ [Tool] JSON parse error in {func_name}: {e}")
            results[f"{func_name}_error"] = "Invalid arguments (JSON parse failed)"
        
        except Exception as e:
            logger.error(f"❌ [Tool] Execution failed: {func_name} - {e}", exc_info=True)
            results[f"{func_name}_error"] = str(e)
    
    logger.warning(f"✅ [Tools] Execution complete. Results: {list(results.keys())}")
    return results
