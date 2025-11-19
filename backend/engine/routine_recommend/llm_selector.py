"""
LLM 기반 루틴 선택 및 설명 생성 모듈
GPT-4o-mini를 사용하여 후보 루틴 중 최종 추천 루틴을 선택하고 설명을 생성합니다.
"""
import os
import json
import re
from typing import List, Optional
from openai import OpenAI

from engine.routine_recommend.models.schemas import (
    EmotionAnalysisResult,
    RoutineCandidate,
    RoutineRecommendationItem,
)




# OpenAI 클라이언트 초기화
_client: Optional[OpenAI] = None


def _get_client() -> OpenAI:
    """OpenAI 클라이언트 싱글톤"""
    global _client
    if _client is None:
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY 환경변수가 설정되지 않았습니다.")
        _client = OpenAI(api_key=api_key)
    return _client


def select_and_explain_routines(
    emotion: EmotionAnalysisResult,
    candidates: List[RoutineCandidate],
    max_recommend: int = 3
) -> List[RoutineRecommendationItem]:
    """
    후보 루틴 중에서 최종 추천 루틴을 선택하고 설명을 생성합니다.
    
    Args:
        emotion: 감정 분석 결과
        candidates: 루틴 후보 리스트
        max_recommend: 최대 추천 개수
        
    Returns:
        최종 추천 루틴 리스트 (reason, ui_message 포함)
    """
    try:
        client = _get_client()
    except ValueError as e:
        print(f"Warning: {e}. Fallback 모드로 진행합니다.")
        return _fallback_recommendations(candidates, max_recommend)
    
    # 1. 감정 요약 생성
    primary_name = emotion.primary_emotion.name_ko
    secondary_names = [sec.name_ko for sec in emotion.secondary_emotions[:2]]
    sentiment_ko = {
        "positive": "긍정적인",
        "negative": "부정적인",
        "neutral": "중립적인"
    }.get(emotion.sentiment_overall, emotion.sentiment_overall)
    
    if secondary_names:
        emotion_summary = f"{primary_name}과 {', '.join(secondary_names)}이(가) 섞인 {sentiment_ko} 상태"
    else:
        emotion_summary = f"{primary_name}이(가) 주된 {sentiment_ko} 상태"
    
    # 2. 후보 루틴 정보를 JSON 형태로 정리
    candidates_data = []
    for cand in candidates[:max_recommend * 2]:  # 최대 추천의 2배만큼 후보 제공
        candidates_data.append({
            "id": cand.id,
            "title": cand.title,
            "description": cand.description,
            "group": cand.group,
            "sub_group": cand.sub_group,
            "tags": cand.tags,
            "score": round(cand.score, 3)
        })
    
    # 3. 프롬프트 구성
    system_prompt = """너는 "마음봄" 서비스의 정신건강 및 생활 루틴 코치입니다.
갱년기 여성을 대상으로 하는 서비스이므로, 따뜻하고 존중하는 말투를 사용해야 합니다.
너무 어려운 말은 피하고, 친근하고 이해하기 쉬운 표현을 사용하세요.
사용자의 감정 상태에 맞는 루틴을 추천하고, 각 루틴이 왜 도움이 되는지 명확하게 설명해야 합니다."""

    user_prompt = f"""사용자의 감정 상태:
{emotion_summary}

추천 태그: {', '.join(emotion.recommended_routine_tags[:5])}

후보 루틴 목록:
{json.dumps(candidates_data, ensure_ascii=False, indent=2)}

위 후보 루틴 중에서 사용자의 감정 상태에 가장 적합한 {max_recommend}개의 루틴을 선택해주세요.
각 루틴에 대해 다음 정보를 제공해주세요:

1. 이 루틴이 왜 이 감정 상태에 도움이 되는지 (reason)
2. "봄이"가 사용자에게 전달할 따뜻하고 친근한 메시지 (ui_message)

응답은 반드시 다음 JSON 형식이어야 합니다:
{{
  "recommendations": [
    {{
      "routine_id": "루틴 ID",
      "title": "루틴 제목",
      "category": "카테고리 (예: EMOTION_POSITIVE)",
      "sub_type": "하위 타입 (선택사항)",
      "duration_min": 10,
      "intensity_level": "low/medium/high",
      "reason": "이 루틴이 왜 도움이 되는지 설명 (1-2문장)",
      "ui_message": "사용자에게 전달할 따뜻한 메시지 (존댓말, 친근하게)",
      "priority": 1,
      "suggested_time_window": "morning/day/evening/any",
      "followup_type": "none/check_completion"
    }}
  ]
}}

중요:
- reason과 ui_message는 반드시 한국어로 작성
- ui_message는 "~해보시는 건 어떨까요?", "~하시면 좋을 것 같아요" 같은 따뜻한 톤
- priority는 1부터 시작 (1이 가장 높은 우선순위)
- duration_min은 5~30분 사이의 현실적인 값
- intensity_level은 루틴의 강도를 나타냄 (대부분 "low" 또는 "medium")
"""

    # 4. LLM 호출
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.7,
            response_format={"type": "json_object"}
        )
        
        content = response.choices[0].message.content
        result = json.loads(content)
        
    except Exception as e:
        print(f"LLM 호출 실패: {e}. Fallback 모드로 진행합니다.")
        return _fallback_recommendations(candidates, max_recommend)
    
    # 5. 응답 파싱 및 검증
    recommendations = []
    recommendations_data = result.get("recommendations", [])
    
    for i, rec_data in enumerate(recommendations_data[:max_recommend]):
        # 원본 후보에서 정보 가져오기
        candidate = next(
            (c for c in candidates if c.id == rec_data.get("routine_id")),
            candidates[i] if i < len(candidates) else None
        )
        
        if not candidate:
            continue
        
        # RoutineRecommendationItem 생성
        recommendation = RoutineRecommendationItem(
            routine_id=rec_data.get("routine_id", candidate.id),
            title=rec_data.get("title", candidate.title),
            category=rec_data.get("category", candidate.group),
            sub_type=rec_data.get("sub_type"),
            duration_min=rec_data.get("duration_min", 10),
            intensity_level=rec_data.get("intensity_level", "low"),
            reason=rec_data.get("reason", f"{candidate.title}이(가) 현재 감정 상태에 도움이 될 것 같습니다."),
            ui_message=rec_data.get("ui_message", f"{candidate.title}을(를) 해보시는 건 어떨까요?"),
            priority=rec_data.get("priority", i + 1),
            suggested_time_window=rec_data.get("suggested_time_window", "any"),
            followup_type=rec_data.get("followup_type", "check_completion")
        )
        recommendations.append(recommendation)
    
    return recommendations


def _fallback_recommendations(
    candidates: List[RoutineCandidate],
    max_recommend: int
) -> List[RoutineRecommendationItem]:
    """LLM 호출 실패 시 기본 추천 생성"""
    recommendations = []
    
    for i, candidate in enumerate(candidates[:max_recommend]):
        recommendation = RoutineRecommendationItem(
            routine_id=candidate.id,
            title=candidate.title,
            category=candidate.group,
            sub_type=candidate.sub_group,
            duration_min=10,
            intensity_level="low",
            reason=f"{candidate.title}이(가) 현재 감정 상태에 도움이 될 것 같습니다.",
            ui_message=f"{candidate.title}을(를) 해보시는 건 어떨까요?",
            priority=i + 1,
            suggested_time_window="any",
            followup_type="check_completion"
        )
        recommendations.append(recommendation)
    
    return recommendations

