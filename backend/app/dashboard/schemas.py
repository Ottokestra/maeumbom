from datetime import date
from typing import List, Optional

from pydantic import BaseModel


class WeeklyEmotionRanking(BaseModel):
    rank: int
    code: str
    label: str
    percent: float
    count: int
    character_code: str


class DailyMoodSticker(BaseModel):
    date: date
    weekday: str
    emotion_code: Optional[str] = None
    emotion_label: Optional[str] = None
    character_code: Optional[str] = None
    has_record: bool


class WeeklyMoodReportResponse(BaseModel):
    week_label: str
    week_start: date
    week_end: date
    overall_score_percent: int
    dominant_emotion: WeeklyEmotionRanking
    daily_characters: List[DailyMoodSticker]
    emotion_rankings: List[WeeklyEmotionRanking]
    analysis_text: str
