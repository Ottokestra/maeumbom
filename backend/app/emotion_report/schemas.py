"""Pydantic schemas for weekly emotion report."""
from __future__ import annotations

from datetime import date

from pydantic import BaseModel


class DailyEmotionSticker(BaseModel):
    day_label: str
    date: date
    emotion_code: str
    character_key: str
    label: str


class WeeklyEmotionReport(BaseModel):
    week_start: date
    week_end: date
    summary_title: str
    main_emotion_code: str
    main_character_key: str
    temperature: int
    temperature_label: str
    gauge_color: str | None
    daily_stickers: list[DailyEmotionSticker]

