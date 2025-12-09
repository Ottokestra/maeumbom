from typing import List, Dict, Optional
from .models.schemas import EmotionAnalysisResult
from .routine_db import ROUTINES

def select_candidate_routines(
    emotion: EmotionAnalysisResult,
    time_of_day: Optional[str] = None,
    limit: int = 10,
) -> List[Dict]:
    """
    감정 분석 결과와 시간대를 기반으로 루틴 후보를 선택합니다.
    
    Args:
        emotion: 감정 분석 결과
        time_of_day: 시간대 (morning, day, evening, pre_sleep)
        limit: 반환할 후보 개수
        
    Returns:
        선택된 루틴 후보 리스트 (점수 내림차순 정렬)
    """
    candidates = []
    
    # 감정 정보 추출
    primary_code = emotion.primary_emotion.code
    primary_group = emotion.primary_emotion.group
    sentiment = emotion.sentiment_overall
    recommended_tags = emotion.recommended_routine_tags
    
    # 각 루틴에 대해 점수 계산
    for routine in ROUTINES:
        score = 0.0
        routine_tags = routine.get("tags", [])
        routine_time_tags = routine.get("time_tags", [])
        routine_category = routine.get("category", "")
        
        # 1. 감정 매칭 점수
        # 긍정적인 감정일 때 -> 긍정 유지 루틴 (EMOTION_POSITIVE)
        if primary_group == "positive" or sentiment == "positive":
            if routine_category == "EMOTION_POSITIVE":
                score += 10.0
            if "maintain_positive" in routine_tags:
                score += 5.0
                
        # 부정적인 감정일 때 -> 해당 감정 완화 루틴
        elif primary_group == "negative":
            # 슬픔/우울/무기력
            if primary_code in ["sadness", "depression", "boredom"]:
                if routine_category == "EMOTION_SADNESS":
                    score += 10.0
                if "sadness" in routine_tags or "low_energy" in routine_tags or "depression" in routine_tags:
                    score += 5.0
            
            # 화/짜증/불만
            elif primary_code in ["anger", "discontent", "contempt"]:
                if routine_category == "EMOTION_ANGER":
                    score += 10.0
                if "anger" in routine_tags or "calm" in routine_tags:
                    score += 5.0
                    
            # 불안/공포/혼란
            elif primary_code in ["fear", "anxiety", "confusion"]:
                if routine_category == "EMOTION_FEAR":
                    score += 10.0
                if "anxiety" in routine_tags or "fear" in routine_tags:
                    score += 5.0
                    
        # 2. 추천 태그 매칭 점수 (EmotionAnalysisResult.recommended_routine_tags)
        for tag in recommended_tags:
            if tag in routine_tags:
                score += 3.0
                
        # 3. 시간대 매칭 점수
        if time_of_day:
            if time_of_day in routine_time_tags:
                score += 5.0
            # 시간대 전용 카테고리인 경우 추가 점수
            time_category_map = {
                "morning": "TIME_MORNING",
                "day": "TIME_DAY",
                "evening": "TIME_EVENING",
                "pre_sleep": "TIME_EVENING"  # pre_sleep은 evening 카테고리 사용
            }
            expected_category = time_category_map.get(time_of_day)
            if expected_category and routine_category == expected_category:
                score += 3.0
                
        # 4. 기타 가산점
        # 감정 강도가 높을 때(4, 5)는 진정/이완 루틴에 가산점
        if emotion.primary_emotion.intensity >= 4:
            if "relaxation" in routine_tags or "calm" in routine_tags or "breathing" in routine_tags:
                score += 2.0
                
        # 점수가 0보다 크면 후보에 추가
        if score > 0:
            # 원본 루틴 dict를 복사해서 score 추가
            candidate = routine.copy()
            candidate["score"] = score
            candidates.append(candidate)
            
    # 점수 내림차순 정렬
    candidates.sort(key=lambda x: x["score"], reverse=True)
    
    # 상위 limit개 반환
    return candidates[:limit]
