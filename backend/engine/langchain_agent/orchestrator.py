"""
Orchestrator LLM Implementation

Analyzes user intent and selects appropriate tools to execute.
Simplified to focus on routine recommendation and memory search.
"""
from openai import OpenAI
import json
import os
import logging
from typing import List, Dict, Any
from datetime import datetime

from .tools import TOOLS

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

[Available Tools]
1. **recommend_routine**: 건강 루틴 추천
   - When: User requests routine recommendations OR expresses stress/difficulty
   - Examples: "스트레스 받아", "아침 루틴 추천해줘", "운동 뭐하면 좋을까?"
   - Call with context parameter: "stressed", "morning_routine", "exercise", etc.

2. **search_memory**: 과거 대화/정보 검색
   - When: User asks about past conversations or requests information from history
   - Examples: "지난주에 뭐라고 했지?", "내 가족 이야기 기억해?"
   - Call with query parameter

[User Input]
{user_text}

[Context]
- Session: {context.get('session_id', 'unknown')}
- Memory Available: {bool(context.get('memory', ''))}

**Decision Rules:**
1. If user clearly requests a routine or expresses wellness needs → call recommend_routine()
2. If user asks about past conversations → call search_memory()
3. For general conversation, greetings, or simple questions → NO TOOLS (return empty array)

**IMPORTANT:** 
- You MUST either return tool calls OR empty array []
- Do NOT return both empty tools and empty text
- When in doubt, return empty array [] to let the main LLM handle it
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
        
        # 🆕 Step 1: Quick pre-check - do we need tools at all?
        # This avoids the "empty output" error from OpenAI
        needs_tools = _check_if_tools_needed(user_text)
        
        if not needs_tools:
            logger.warning("🎯 [Orchestrator] No tools needed - general conversation")
            return []
        
        # Step 2: Select specific tools
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            tools=TOOLS,
            tool_choice="required",  # 🆕 반드시 도구 선택 (empty output 방지)
            temperature=0.3  # Low temperature for consistent tool selection
        )
        
        # Handle empty response
        if not response.choices or not response.choices[0].message:
            logger.warning("⚠️  [Orchestrator] Empty response from LLM")
            return []
        
        tool_calls = response.choices[0].message.tool_calls or []
        
        tool_names = [tc.function.name for tc in tool_calls]
        logger.warning(
            f"🎯 [Orchestrator] Selected {len(tool_calls)} tools: {tool_names}"
        )
        
        return tool_calls
        
    except Exception as e:
        logger.error(f"❌ [Orchestrator] Failed: {e}", exc_info=True)
        return []


def _check_if_tools_needed(user_text: str) -> bool:
    """
    빠른 사전 체크: 도구가 필요한지 판단
    
    이를 통해 불필요한 API 호출과 "empty output" 에러를 방지합니다.
    """
    user_lower = user_text.lower()
    
    # Routine recommendation triggers
    routine_keywords = [
        "루틴", "추천", "운동", "명상", "스트레칭", "요가",
        "스트레스", "힘들", "지쳐", "피곤", "우울",
        "뭐하면", "어떻게", "도움"
    ]
    
    # Memory search triggers  
    memory_keywords = [
        "지난", "전에", "예전", "기억", "말했", "얘기했",
        "언제", "했었"
    ]
    
    # Check if any keyword matches
    for keyword in routine_keywords + memory_keywords:
        if keyword in user_lower:
            return True
    
    # 질문 형태 체크
    if any(q in user_lower for q in ["?", "어때", "좋을까", "추천"]):
        # 단순 인사나 확인이 아닌 경우
        if not any(g in user_lower for g in ["안녕", "고마워", "감사", "알겠어", "응", "네", "좋아"]):
            return True
    
    return False


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
    
    for tool_call in tool_calls:
        func_name = tool_call.function.name
        
        try:
            args = json.loads(tool_call.function.arguments)
            logger.warning(f"🔧 [Tool] Executing: {func_name}")
            
            # ===== 1. recommend_routine =====
            if func_name == "recommend_routine":
                if not RoutineRecommendFromEmotionEngine:
                    logger.warning("⚠️  [recommend_routine] Engine not available")
                    continue
                
                # 간단한 컨텍스트 기반 루틴 추천 (감정 분석 없이)
                context_type = args.get("context", "general")
                
                try:
                    # 기본 감정 객체 생성 (컨텍스트에 따라)
                    emotion_mapping = {
                        "stressed": {"cluster_label": "stressed", "polarity": "negative"},
                        "morning_routine": {"cluster_label": "calm", "polarity": "neutral"},
                        "exercise": {"cluster_label": "energetic", "polarity": "positive"},
                    }
                    
                    emotion_data = emotion_mapping.get(context_type, {"cluster_label": "neutral", "polarity": "neutral"})
                    
                    emotion_obj = EmotionAnalysisResult(
                        cluster_label=emotion_data["cluster_label"],
                        polarity=emotion_data["polarity"],
                        raw_distribution={},
                        primary_emotion={},
                        secondary_emotions=[],
                        sentiment_overall=emotion_data["polarity"],
                        service_signals={},
                        recommended_response_style=[],
                        recommended_routine_tags=[]
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
                    logger.warning(f"✅ [recommend_routine] {len(routines)} routines recommended (context: {context_type})")
                except Exception as e:
                    logger.error(f"Failed to recommend routines: {e}", exc_info=True)
                    results["recommend_routine_error"] = str(e)
            
            # ===== 2. search_memory =====
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
