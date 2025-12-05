"""Pydantic schemas for weekly emotion report."""
from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel, Field


class WeeklyEmotionItem(BaseModel):
    """Single day emotion summary for the weekly report."""

    day: str  # 요일 라벨 ("월", "화" ...)
    emoji: str  # 캐릭터 이모지
    emotion_code: str  # 내부 감정 코드 (예: "worry")


class WeeklyEmotionReport(BaseModel):
    """Weekly emotion report response schema."""

    hasData: bool
    summaryTitle: Optional[str] = None
    mainCharacterEmoji: Optional[str] = None
    temperature: Optional[int] = None
    weeklyEmotions: List[WeeklyEmotionItem] = Field(default_factory=list)

