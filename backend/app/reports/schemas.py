"""보고서 응답 스키마 정의."""
from __future__ import annotations

from datetime import datetime
from typing import List
from typing_extensions import Literal
from pydantic import BaseModel


class TopEmotionItem(BaseModel):
    label: str
    count: int
    ratio: float


class EmotionMetric(BaseModel):
    period_start: datetime
    period_end: datetime
    total_sessions: int
    total_messages: int
    avg_sentiment: float
    top_emotions: List[TopEmotionItem]


class UserReportResponse(BaseModel):
    period_type: Literal["daily", "weekly", "monthly"]
    period_start: datetime
    period_end: datetime
    metrics: EmotionMetric
    recent_highlights: List[str]
    recommendation: str
