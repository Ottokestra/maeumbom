"""
Pydantic models for API request/response validation
"""
from pydantic import BaseModel, Field
from typing import Dict, List, Optional


class AnalyzeRequest(BaseModel):
    """Request model for emotion analysis"""
    text: str = Field(..., description="Text to analyze", min_length=1)


class SessionAnalyzeRequest(BaseModel):
    """Request model for session-based emotion analysis"""
    session_id: str = Field(..., description="Session ID (e.g., user_2_1734170515123)", min_length=1)


class SimilarContext(BaseModel):
    """Model for similar context information"""
    text: str
    emotion: str
    intensity: int
    similarity: float


class RelatedCluster(BaseModel):
    """Model for related emotion cluster"""
    cluster_id: int
    cluster_label: str
    similarity: float = Field(default=0.0, ge=0.0, le=1.0)


class AnalyzeResponse(BaseModel):
    """Response model for emotion analysis (UI-friendly format)"""
    input: str
    
    # VA 값 (숫자)
    valence: float = Field(..., description="Valence value (-1.0 ~ +1.0)", ge=-1.0, le=1.0)
    arousal: float = Field(..., description="Arousal value (-1.0 ~ +1.0)", ge=-1.0, le=1.0)
    
    # UI-friendly 라벨
    mood_direction: str = Field(..., description="Mood direction: 긍정/중립/부정")
    emotion_intensity: str = Field(..., description="Emotion intensity: 높음/보통/낮음")
    
    # 기존 필드 (하위 호환성)
    primary_emotion: str = Field(..., description="Primary detected emotion")
    percentage: int = Field(..., description="Primary emotion percentage")
    top_emotions: Dict[str, int] = Field(..., description="Top 3 emotion percentages (sum=100%)")
    similar_contexts: List[SimilarContext] = Field(default_factory=list)


class HealthResponse(BaseModel):
    """Response model for health check"""
    status: str
    vector_store_count: int
    ready: bool


class InitResponse(BaseModel):
    """Response model for initialization"""
    status: str
    message: str
    document_count: int


class ErrorResponse(BaseModel):
    """Response model for errors"""
    error: str
    detail: Optional[str] = None


# 17개 감정 군집 기반 모델
class EmotionDistribution(BaseModel):
    """Model for emotion distribution item"""
    code: str = Field(..., description="Emotion code (e.g., 'joy', 'sadness')")
    name_ko: str = Field(..., description="Korean emotion name")
    group: str = Field(..., description="Emotion group: 'positive' or 'negative'")
    score: float = Field(..., description="Emotion score (0~1)", ge=0.0, le=1.0)


class PrimaryEmotion(BaseModel):
    """Model for primary emotion"""
    code: str = Field(..., description="Emotion code")
    name_ko: str = Field(..., description="Korean emotion name")
    group: str = Field(..., description="Emotion group: 'positive' or 'negative'")
    intensity: int = Field(..., description="Emotion intensity (1~5)", ge=1, le=5)
    confidence: float = Field(..., description="Confidence (0~1)", ge=0.0, le=1.0)


class SecondaryEmotion(BaseModel):
    """Model for secondary emotion"""
    code: str = Field(..., description="Emotion code")
    name_ko: str = Field(..., description="Korean emotion name")
    group: Optional[str] = Field(default=None, description="Emotion group: 'positive' or 'negative'")
    intensity: int = Field(..., description="Emotion intensity (1~5)", ge=1, le=5)


class MixedEmotion(BaseModel):
    """Model for mixed emotion detection"""
    is_mixed: bool = Field(..., description="Whether mixed emotion is detected")
    dominant_group: str = Field(..., description="Dominant emotion group: 'positive' or 'negative'")
    positive_ratio: float = Field(..., description="Positive emotion ratio (0~1)", ge=0.0, le=1.0)
    negative_ratio: float = Field(..., description="Negative emotion ratio (0~1)", ge=0.0, le=1.0)
    mixed_ratio: float = Field(..., description="Mixed emotion ratio (0~1)", ge=0.0, le=1.0)


class ServiceSignals(BaseModel):
    """Model for service signals"""
    need_empathy: bool = Field(..., description="Whether empathy is needed")
    need_routine_recommend: bool = Field(..., description="Whether routine recommendation is needed")
    need_health_check: bool = Field(..., description="Whether health check is needed")
    need_voice_analysis: bool = Field(..., description="Whether voice analysis is needed")
    risk_level: str = Field(..., description="Risk level: 'normal', 'watch', 'alert', 'critical'")


class AnalyzeResponse17(BaseModel):
    """Response model for 17 emotion clusters analysis"""
    text: str = Field(..., description="Original input text")
    language: str = Field(default="ko", description="Language code")
    
    raw_distribution: List[EmotionDistribution] = Field(..., description="17 emotion distribution scores")
    primary_emotion: PrimaryEmotion = Field(..., description="Primary detected emotion")
    secondary_emotions: List[SecondaryEmotion] = Field(default_factory=list, description="Secondary emotions (1~3)")
    sentiment_overall: str = Field(..., description="Overall sentiment: 'positive', 'neutral', 'negative'")
    mixed_emotion: Optional[MixedEmotion] = Field(default=None, description="Mixed emotion detection result")
    
    service_signals: ServiceSignals = Field(..., description="Service signals for UI")
    recommended_response_style: List[str] = Field(default_factory=list, description="Recommended response styles")
    recommended_routine_tags: List[str] = Field(default_factory=list, description="Recommended routine tags")
    report_tags: List[str] = Field(default_factory=list, description="Report tags")

