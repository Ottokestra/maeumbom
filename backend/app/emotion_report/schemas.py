"""Pydantic schemas for weekly emotion report."""
from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel, Field


class DailyEmotionSticker(BaseModel):
    """Single day emotion sticker information for the report."""

    day_label: str
    date: str
    emotion_code: str
    character_key: str
    label: str


class WeeklyEmotionReport(BaseModel):
    """Weekly emotion report response schema aligned with the frontend."""

    week_start: str
    week_end: str
    summary_title: str
    main_emotion_code: str
    main_character_key: str
    temperature: int
    temperature_label: str
    gauge_color: Optional[str] = None
    daily_stickers: List[DailyEmotionSticker] = Field(default_factory=list)
    badges: List[str] = Field(default_factory=list)
    decorations: List[str] = Field(default_factory=list)

