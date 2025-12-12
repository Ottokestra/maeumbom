import os
import json
from typing import List, Dict, Any
from openai import OpenAI

def format_routine_recommendations_ko(
    user_text: str,
    emotion_summary: str,
    routines: List[Dict],
    max_items: int = 3,
) -> List[Dict]:
    """
    후보 루틴 리스트를 기반으로 LLM을 사용하여 사용자 친화적인 추천 메시지를 생성합니다.
    
    Args:
        user_text: 사용자 입력 텍스트
        emotion_summary: 감정 요약 문자열
        routines: 후보 루틴 리스트 (rule_selector 결과)
        max_items: 최대 반환 개수
        
    Returns:
        RoutineRecommendationItem에 매핑 가능한 dict 리스트
    """
    # 상위 max_items개만 사용
    top_routines = routines[:max_items]
    
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("Warning: OPENAI_API_KEY not found. Using fallback formatting.")
        return _fallback_formatting(top_routines)
        
    try:
        client = OpenAI(api_key=api_key)
        
        # 프롬프트 구성
        routines_json = json.dumps([{
            "id": r["id"],
            "title": r["title"],
            "tags": r.get("tags", []),
            "category": r.get("category", "")
        } for r in top_routines], ensure_ascii=False)
        
        system_prompt = "너는 시니어 사용자의 감정 상태에 맞춰 간단한 루틴을 추천해주는 한국어 상담 AI야."
        user_prompt = f"""
사용자 텍스트: "{user_text}"
감정 상태: {emotion_summary}

추천할 루틴 후보들:
{routines_json}

위 후보들을 바탕으로 사용자에게 추천할 루틴 3가지를 선정하고, 각 루틴에 대해 추천 이유(reason)와 사용자에게 건넬 따뜻한 말(ui_message)을 작성해줘.
응답은 반드시 아래와 같은 JSON 형식이어야 해.

{{
  "items": [
    {{
      "routine_id": "루틴ID",
      "title": "루틴 제목",
      "category": "카테고리",
      "sub_type": "하위타입(선택)",
      "duration_min": 5,
      "intensity_level": "low/medium/high",
      "reason": "추천 이유 (한 문장)",
      "ui_message": "사용자에게 건넬 따뜻한 제안 (존댓말, 친절하게)",
      "priority": 1,
      "suggested_time_window": "morning/day/evening/any",
      "followup_type": "none/check_completion"
    }}
  ]
}}
"""
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
        )
        
        content = response.choices[0].message.content
        result = json.loads(content)
        
        items = result.get("items", [])
        
        # 결과 검증 및 보정
        formatted_items = []
        for i, item in enumerate(items):
            # 원본 루틴 정보 찾기 (ID 매칭)
            original_routine = next((r for r in top_routines if r["id"] == item.get("routine_id")), None)
            
            # ID가 없거나 매칭되지 않으면 순서대로 매핑 시도
            if not original_routine and i < len(top_routines):
                original_routine = top_routines[i]
                item["routine_id"] = original_routine["id"]
                item["title"] = original_routine["title"]
                item["category"] = original_routine["category"]
            
            if original_routine:
                # 필수 필드 보장
                if "routine_id" not in item: item["routine_id"] = original_routine["id"]
                if "title" not in item: item["title"] = original_routine["title"]
                if "category" not in item: item["category"] = original_routine["category"]
                
                formatted_items.append(item)
                
        return formatted_items
        
    except Exception as e:
        print(f"LLM formatting failed: {e}")
        return _fallback_formatting(top_routines)

def _fallback_formatting(routines: List[Dict]) -> List[Dict]:
    """LLM 호출 실패 시 기본 포맷팅"""
    formatted = []
    for i, r in enumerate(routines):
        formatted.append({
            "routine_id": r["id"],
            "title": r["title"],
            "category": r["category"],
            "sub_type": None,
            "duration_min": 5,
            "intensity_level": "low",
            "reason": "현재 감정 상태에 도움이 되는 루틴입니다.",
            "ui_message": f"{r['title']}을(를) 해보시는 건 어떨까요?",
            "priority": i + 1,
            "suggested_time_window": r.get("time_tags", ["any"])[0] if r.get("time_tags") else "any",
            "followup_type": "check_completion"
        })
    return formatted
