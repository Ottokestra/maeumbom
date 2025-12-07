"""Schemas for weekly emotion reports."""
from __future__ import annotations

from datetime import date
from typing import List, Optional
from typing_extensions import Literal
from pydantic import BaseModel


class DateRange(BaseModel):
    start: date
    end: date


class ReportCharacter(BaseModel):
    id: str
    name: str
    avatar_url: Optional[str] = None
    color: Optional[str] = None
    role: Optional[str] = None


class EmotionMetrics(BaseModel):
    mood_score: int
    stress_score: int
    stability_score: int
    talk_count: int
    positive_ratio: float
    negative_ratio: float
    neutral_ratio: float
    main_emotion: str
    secondary_emotion: Optional[str] = None


class DialogLine(BaseModel):
    speaker_id: str
    type: Literal["opening", "analysis", "warning", "tip", "closing"]
    emotion: str
    text: str


class WeeklyEmotionReportResponse(BaseModel):
    has_data: bool
    period: Literal["WEEKLY"]
    date_range: DateRange
    title: Optional[str] = None
    summary: Optional[str] = None
    characters: List[ReportCharacter]
    metrics: Optional[EmotionMetrics] = None
    dialog: List[DialogLine]
