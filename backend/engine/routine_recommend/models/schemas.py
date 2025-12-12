"""
Pydantic schemas for Routine Recommendation
감정 분석 결과를 기반으로 루틴을 추천하는 API의 스키마 정의
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum


# ============================================================================
# 감정 분석 결과 관련 모델
# ============================================================================

class EmotionScore(BaseModel):
    """감정 점수 모델 (raw_distribution 항목)"""
    code: str = Field(..., description="감정 코드 (예: 'joy', 'sadness')")
    name_ko: str = Field(..., description="한국어 감정 이름")
    group: str = Field(..., description="감정 그룹: 'positive' or 'negative'")
    score: float = Field(..., description="감정 점수 (0~1)", ge=0.0, le=1.0)


class PrimaryEmotion(BaseModel):
    """주요 감정 모델"""
    code: str = Field(..., description="감정 코드")
    name_ko: str = Field(..., description="한국어 감정 이름")
    group: str = Field(..., description="감정 그룹: 'positive' or 'negative'")
    intensity: int = Field(..., description="감정 강도 (1~5)", ge=1, le=5)
    confidence: float = Field(..., description="신뢰도 (0~1)", ge=0.0, le=1.0)


class SecondaryEmotion(BaseModel):
    """보조 감정 모델"""
    code: str = Field(..., description="감정 코드")
    name_ko: str = Field(..., description="한국어 감정 이름")
    intensity: int = Field(..., description="감정 강도 (1~5)", ge=1, le=5)


class ServiceSignals(BaseModel):
    """서비스 신호 모델"""
    need_empathy: bool = Field(..., description="공감이 필요한지 여부")
    need_routine_recommend: bool = Field(..., description="루틴 추천이 필요한지 여부")
    need_health_check: bool = Field(..., description="건강 체크가 필요한지 여부")
    need_voice_analysis: bool = Field(..., description="음성 분석이 필요한지 여부")
    risk_level: str = Field(..., description="위험 수준: 'normal', 'watch', 'alert', 'critical'")


# 하위 호환성을 위한 별칭
EmotionDistribution = EmotionScore
EmotionPrimary = PrimaryEmotion
EmotionSecondary = SecondaryEmotion
EmotionServiceSignals = ServiceSignals


class EmotionAnalysisResult(BaseModel):
    """감정 분석 결과 모델 (AnalyzeResponse17 구조를 그대로 표현)"""
    text: str = Field(..., description="원본 입력 텍스트")
    language: str = Field(default="ko", description="언어 코드")
    
    raw_distribution: List[EmotionScore] = Field(..., description="17개 감정 분포 점수")
    primary_emotion: PrimaryEmotion = Field(..., description="주요 감정")
    secondary_emotions: List[SecondaryEmotion] = Field(default_factory=list, description="보조 감정들 (1~3개)")
    sentiment_overall: str = Field(..., description="전체 감정 극성: 'positive', 'neutral', 'negative'")
    
    service_signals: ServiceSignals = Field(..., description="서비스 신호")
    recommended_response_style: List[str] = Field(default_factory=list, description="추천 응답 스타일")
    recommended_routine_tags: List[str] = Field(default_factory=list, description="추천 루틴 태그")
    report_tags: List[str] = Field(default_factory=list, description="리포트 태그")


# ============================================================================
# 루틴 추천 입력 모델
# ============================================================================

class TimeOfDay(str, Enum):
    """하루 중 시간대"""
    MORNING = "morning"
    DAY = "day"
    EVENING = "evening"
    PRE_SLEEP = "pre_sleep"


class RoutineRecommendFromEmotionInput(BaseModel):
    """감정 분석 결과를 기반으로 한 루틴 추천 요청 모델"""
    user_id: int = Field(..., description="사용자 ID", gt=0)
    emotion_result: EmotionAnalysisResult = Field(..., description="감정 분석 결과")
    time_of_day: Optional[str] = Field(
        default=None, 
        description="하루 중 시간대: 'morning', 'day', 'evening', 'pre_sleep'"
    )


# ============================================================================
# 루틴 추천 출력 모델
# ============================================================================

class RoutineCandidate(BaseModel):
    """RAG 검색 결과 후보 루틴"""
    id: str = Field(..., description="루틴 고유 ID")
    title: str = Field(..., description="루틴 제목")
    description: str = Field(..., description="루틴 설명")
    group: str = Field(..., description="루틴 그룹 (예: 'EMOTION_POSITIVE', 'TIME_MORNING')")
    sub_group: str = Field(..., description="루틴 하위 그룹")
    tags: List[str] = Field(default_factory=list, description="루틴 태그 리스트")
    score: float = Field(..., description="검색 유사도 점수 (높을수록 유사)", ge=0.0)


class RoutineRecommendationItem(BaseModel):
    """개별 루틴 추천 항목 (최종 추천 결과)"""
    routine_id: str = Field(..., description="루틴 고유 ID")
    title: str = Field(..., description="루틴 제목")
    category: str = Field(..., description="루틴 카테고리")
    sub_type: Optional[str] = Field(default=None, description="루틴 하위 타입")
    duration_min: Optional[int] = Field(default=None, description="소요 시간 (분)", gt=0)
    intensity_level: Optional[str] = Field(default=None, description="강도 수준 (low/medium/high)")
    reason: str = Field(..., description="추천 이유 (LLM 생성)")
    ui_message: str = Field(..., description="UI 메시지 (LLM 생성, 사용자에게 전달할 따뜻한 말)")
    priority: int = Field(..., description="우선순위 (1~5, 높을수록 우선)", ge=1, le=5)
    suggested_time_window: Optional[str] = Field(default=None, description="추천 시간대 (morning/day/evening/pre_sleep)")
    followup_type: Optional[str] = Field(default=None, description="후속 조치 타입 (none/check_completion)")


class RoutineRecommendOutput(BaseModel):
    """루틴 추천 결과 출력 모델"""
    user_id: int = Field(..., description="사용자 ID", gt=0)
    recommendations: List[RoutineRecommendationItem] = Field(..., description="추천된 루틴 목록")

