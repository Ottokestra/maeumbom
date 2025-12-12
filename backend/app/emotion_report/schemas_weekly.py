"""
Pydantic schemas for Weekly Emotion Report API
"""

from datetime import date, datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class WeeklyEmotionReportBase(BaseModel):
    """Base schema for weekly emotion report"""

    week_start: date
    week_end: date
    emotion_temperature: int
    positive_score: int
    negative_score: int
    neutral_score: int
    main_emotion: Optional[str] = None
    main_emotion_confidence: Optional[float] = None
    main_emotion_character_code: Optional[str] = None
    badges: Optional[List[str]] = None
    summary_text: Optional[str] = None


class WeeklyEmotionReportCreate(WeeklyEmotionReportBase):
    """Schema for creating a weekly emotion report"""

    user_id: Optional[int] = None  # Will be set from current_user


class WeeklyEmotionReportRead(WeeklyEmotionReportBase):
    """Schema for reading a weekly emotion report"""

    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class WeeklyEmotionReportListItem(BaseModel):
    """Schema for weekly emotion report list item (simplified)"""

    id: int
    week_start: date
    week_end: date
    emotion_temperature: int
    main_emotion: Optional[str] = None
    badges: Optional[List[str]] = None

    model_config = ConfigDict(from_attributes=True)


class WeeklyReportListResponse(BaseModel):
    """Schema for list response"""

    items: List[WeeklyEmotionReportListItem]
