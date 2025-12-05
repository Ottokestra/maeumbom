"""Service layer for emotion reports."""
from __future__ import annotations

from collections import Counter
from datetime import date, datetime, timedelta
from typing import Iterable

from sqlalchemy.orm import Session

from app.db.models import EmotionAnalysis

from .schemas import DailyEmotionSticker, WeeklyEmotionReport

DAY_LABELS = ["월", "화", "수", "목", "금", "토", "일"]
DEFAULT_EMOTION = "WORRY"

EMOTION_CHARACTER_MAP: dict[str, tuple[str, str]] = {
    "WORRY": ("peach_worry", "걱정 복숭아"),
    "SAD": ("cloud_sad", "우울 구름"),
    "SADNESS": ("cloud_sad", "우울 구름"),
    "ANGER": ("fire_angry", "화난 불꽃"),
    "ANXIETY": ("rain_anxiety", "초조 빗방울"),
    "STRESS": ("storm_stress", "스트레스 번개"),
    "HAPPY": ("sunny_happy", "기쁨 햇살"),
    "JOY": ("sunny_happy", "기쁨 햇살"),
    "RELIEF": ("breeze_relief", "안도 바람"),
    "PROUD": ("star_proud", "뿌듯 별"),
    "LOVE": ("heart_love", "사랑 하트"),
    "NEUTRAL": ("leaf_neutral", "담담 잎새"),
    "CALM": ("leaf_neutral", "담담 잎새"),
    "ENERGETIC": ("spark_energy", "에너지 스파크"),
    "LONELY": ("moon_lonely", "외로운 달"),
    "HOPE": ("seed_hope", "희망 씨앗"),
    "GRATEFUL": ("gift_grateful", "감사 선물"),
}

SAMPLE_WEEKLY_EMOTIONS = [
    "WORRY",
    "SAD",
    "HAPPY",
    "NEUTRAL",
    "HAPPY",
    "STRESS",
    "RELIEF",
]

POSITIVE_CODES = {"HAPPY", "JOY", "RELIEF", "PROUD", "LOVE", "HOPE", "GRATEFUL", "ENERGETIC"}
NEGATIVE_CODES = {"WORRY", "SAD", "SADNESS", "ANGER", "ANXIETY", "STRESS", "LONELY"}


def map_emotion_to_character(emotion_code: str | None) -> tuple[str, str]:
    key = (emotion_code or DEFAULT_EMOTION).upper()
    return EMOTION_CHARACTER_MAP.get(key, EMOTION_CHARACTER_MAP[DEFAULT_EMOTION])


def _calculate_week_range(base_date: date | None) -> tuple[date, date]:
    target = base_date or date.today()
    week_start = target - timedelta(days=target.weekday())
    week_end = week_start + timedelta(days=6)
    return week_start, week_end


def _extract_emotion_code(record: EmotionAnalysis) -> str:
    if record.PRIMARY_EMOTION and isinstance(record.PRIMARY_EMOTION, dict):
        for key in ("emotion_code", "code", "primary_emotion"):
            candidate = record.PRIMARY_EMOTION.get(key)
            if candidate:
                return str(candidate).upper()
        label = record.PRIMARY_EMOTION.get("label")
        if label:
            return str(label).upper()

    sentiment = (record.SENTIMENT_OVERALL or "").lower()
    if sentiment:
        if sentiment == "positive":
            return "HAPPY"
        if sentiment == "negative":
            return "SAD"
    return DEFAULT_EMOTION


def _select_daily_emotion(records: Iterable[EmotionAnalysis], day: date) -> str:
    for record in sorted(records, key=lambda r: r.CREATED_AT, reverse=True):
        if record.CREATED_AT.date() == day:
            return _extract_emotion_code(record)
    return DEFAULT_EMOTION


def _build_temperature(emotion_codes: list[str]) -> tuple[int, str, str | None]:
    if not emotion_codes:
        return 50, "온도: 50°", "#f7a9a8"

    positive = sum(1 for code in emotion_codes if code in POSITIVE_CODES)
    negative = sum(1 for code in emotion_codes if code in NEGATIVE_CODES)
    total = len(emotion_codes)

    balance = positive - negative
    normalized = 50 + int((balance / max(total, 1)) * 50)
    temperature = max(0, min(100, normalized))

    if temperature >= 70:
        gauge_color = "#ffb347"
    elif temperature >= 40:
        gauge_color = "#f7a9a8"
    else:
        gauge_color = "#8fb3ff"

    return temperature, f"온도: {temperature}°", gauge_color


def build_weekly_emotion_report(
    db: Session,
    user_id: int,
    base_date: date | None = None,
) -> WeeklyEmotionReport:
    week_start, week_end = _calculate_week_range(base_date)

    start_dt = datetime.combine(week_start, datetime.min.time())
    end_dt = datetime.combine(week_end + timedelta(days=1), datetime.min.time())

    records = (
        db.query(EmotionAnalysis)
        .filter(EmotionAnalysis.USER_ID == user_id)
        .filter(EmotionAnalysis.CREATED_AT >= start_dt)
        .filter(EmotionAnalysis.CREATED_AT < end_dt)
        .order_by(EmotionAnalysis.CREATED_AT.desc())
        .all()
    )

    daily_codes: list[str] = []
    stickers: list[DailyEmotionSticker] = []

    for idx, offset in enumerate(range(0, 7)):
        current_date = week_start + timedelta(days=offset)
        if records:
            emotion_code = _select_daily_emotion(records, current_date)
        else:
            emotion_code = SAMPLE_WEEKLY_EMOTIONS[idx % len(SAMPLE_WEEKLY_EMOTIONS)]
        character_key, label = map_emotion_to_character(emotion_code)
        stickers.append(
            DailyEmotionSticker(
                day_label=DAY_LABELS[idx],
                date=current_date,
                emotion_code=emotion_code,
                character_key=character_key,
                label=label,
            )
        )
        daily_codes.append(emotion_code)

    counter = Counter(daily_codes)
    main_emotion = counter.most_common(1)[0][0] if counter else DEFAULT_EMOTION
    main_character_key, main_label = map_emotion_to_character(main_emotion)

    temperature, temperature_label, gauge_color = _build_temperature(daily_codes)
    summary_title = f"금주의 너는 '{main_label}'"

    return WeeklyEmotionReport(
        week_start=week_start,
        week_end=week_end,
        summary_title=summary_title,
        main_emotion_code=main_emotion,
        main_character_key=main_character_key,
        temperature=temperature,
        temperature_label=temperature_label,
        gauge_color=gauge_color,
        daily_stickers=stickers,
    )

