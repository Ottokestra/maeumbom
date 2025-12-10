from datetime import date, datetime
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


class WeeklySentimentPoint(BaseModel):
    timestamp: datetime
    sentiment_score: float
    sentiment_overall: str
    primary_emotion_code: str
    primary_emotion_label: str
    character_code: str


class HighlightConversation(BaseModel):
    id: int
    text: str
    created_at: datetime
    sentiment_overall: str
    primary_emotion_code: str
    primary_emotion_label: str
    risk_level: Optional[str] = None
    report_tags: List[str] = []


class WeeklyMoodReportResponse(BaseModel):
    week_label: str
    week_start: date
    week_end: date
    overall_score_percent: int
    dominant_emotion: WeeklyEmotionRanking
    daily_characters: List[DailyMoodSticker]
    emotion_rankings: List[WeeklyEmotionRanking]
    analysis_text: str
    sentiment_timeline: List[WeeklySentimentPoint]
    highlight_conversations: List[HighlightConversation]
