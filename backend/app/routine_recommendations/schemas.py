"""
Pydantic schemas for routine recommendations API
"""

from datetime import date
from typing import Optional, List, Any
from pydantic import BaseModel, Field


class RoutineRecommendationResponse(BaseModel):
    """루틴 추천 응답"""
    id: int = Field(..., alias="ID")
    user_id: int = Field(..., alias="USER_ID")
    recommendation_date: date = Field(..., alias="RECOMMENDATION_DATE")
    emotion_summary: Optional[Any] = Field(None, alias="EMOTION_SUMMARY")
    routines: Optional[Any] = Field(None, alias="ROUTINES")
    total_emotions: int = Field(..., alias="TOTAL_EMOTIONS")
    primary_emotion: Optional[str] = Field(None, alias="PRIMARY_EMOTION")
    sentiment_overall: Optional[str] = Field(None, alias="SENTIMENT_OVERALL")
    
    class Config:
        from_attributes = True
        populate_by_name = True


class RoutineRecommendationsListResponse(BaseModel):
    """루틴 추천 목록 응답"""
    recommendations: List[RoutineRecommendationResponse]
    total_count: int

