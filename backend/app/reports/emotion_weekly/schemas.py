"""주간 감정 리포트 응답 스키마."""
from __future__ import annotations

from datetime import date
from typing import List
from typing_extensions import Literal
from pydantic import BaseModel


class EmotionTemperature(BaseModel):
    score: int
    level: Literal["cold", "neutral", "warm", "hot"]
    positive_ratio: float
    negative_ratio: float


class MainEmotion(BaseModel):
    label: str
    confidence: float
    character_code: str


class EmotionBadge(BaseModel):
    code: str
    label: str
    description: str


class SummaryBubble(BaseModel):
    role: Literal["user", "assistant"]
    text: str
    emotion_label: str


class WeeklyEmotionReportResponse(BaseModel):
    user_id: int
    week_start: date
    week_end: date
    temperature: EmotionTemperature
    main_emotion: MainEmotion
    badge: EmotionBadge
    summary_bubbles: List[SummaryBubble]
