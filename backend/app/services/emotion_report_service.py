"""Service for building weekly emotion reports."""
from __future__ import annotations

import logging
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta
from typing import Dict, Tuple

from sqlalchemy.orm import Session

from app.db.models import EmotionLog
from app.emotion_report.schemas import DailyEmotionSticker, WeeklyEmotionReport

logger = logging.getLogger(__name__)

DAY_LABELS = ["월", "화", "수", "목", "금", "토", "일"]
DEFAULT_EMOTION_CODE = "worry"
DEFAULT_CHARACTER_KEY = "peach_worry"
DEFAULT_LABEL = "걱정이 복숭아"
DEFAULT_GAUGE_COLOR = "#f9c6d6"


# 감정 코드 → 캐릭터 키/라벨/게이지 컬러 매핑
EMOTION_CHARACTER_MAP: Dict[str, Tuple[str, str, str]] = {
    "worry": ("peach_worry", "걱정이 복숭아", "#f9c6d6"),
    "sad": ("cloud_sad", "슬픈 구름", "#b3c7e6"),
    "focus": ("book_focus", "집중하는 책", "#c2e0ff"),
    "sleepy": ("nap_sleepy", "졸린 낮잠", "#e0d1ff"),
    "brave": ("lion_brave", "용감한 사자", "#ffd580"),
    "proud": ("star_proud", "뿌듯한 별", "#ffd480"),
    "happy": ("sun_happy", "기쁜 해", "#ffe89e"),
}


def _normalize_emotion_code(emotion_code: str | None) -> str:
    if not emotion_code:
        return DEFAULT_EMOTION_CODE
    return str(emotion_code).strip().lower() or DEFAULT_EMOTION_CODE


def _pick_character_info(emotion_code: str) -> tuple[str, str, str]:
    return EMOTION_CHARACTER_MAP.get(
        emotion_code,
        (DEFAULT_CHARACTER_KEY, DEFAULT_LABEL, DEFAULT_GAUGE_COLOR),
    )


def _format_date(value: date) -> str:
    return value.strftime("%Y-%m-%d")


def _build_sample_report(base_date: date) -> WeeklyEmotionReport:
    """Return a sample report so the UI is not broken when data is missing."""

    logger.info("TODO: 실제 데이터 연동 필요 - returning sample weekly emotion report")

    stickers: list[DailyEmotionSticker] = []
    for i in range(7):
        day_date = base_date - timedelta(days=6 - i)
        character_key, label, _ = _pick_character_info(DEFAULT_EMOTION_CODE)
        stickers.append(
            DailyEmotionSticker(
                day_label=DAY_LABELS[day_date.weekday()],
                date=_format_date(day_date),
                emotion_code=DEFAULT_EMOTION_CODE,
                character_key=character_key,
                label=label,
            )
        )

    _, label, gauge_color = _pick_character_info(DEFAULT_EMOTION_CODE)

    return WeeklyEmotionReport(
        week_start=_format_date(base_date - timedelta(days=6)),
        week_end=_format_date(base_date),
        summary_title=f"금주의 너는 {label}",
        main_emotion_code=DEFAULT_EMOTION_CODE,
        main_character_key=DEFAULT_CHARACTER_KEY,
        temperature=72,
        temperature_label="따뜻함 72°",
        gauge_color=gauge_color,
        daily_stickers=stickers,
    )


def build_weekly_emotion_report(
    db: Session, user_id: int, base_date: date | None = None, days: int = 7
) -> WeeklyEmotionReport:
    """최근 N일 간 감정 로그를 기반으로 주간 리포트를 생성한다."""

    base = base_date or date.today()
    end_time = datetime.combine(base, datetime.max.time())
    start_time = end_time - timedelta(days=days - 1)

    logs = (
        db.query(EmotionLog)
        .filter(EmotionLog.IS_DELETED == False)
        .filter(EmotionLog.USER_ID == user_id)
        .filter(EmotionLog.CREATED_AT >= start_time)
        .filter(EmotionLog.CREATED_AT <= end_time)
        .order_by(EmotionLog.CREATED_AT.asc())
        .all()
    )

    if not logs:
        return _build_sample_report(base)

    daily_counters: Dict[date, Counter] = defaultdict(Counter)
    temperature_scores: list[float] = []
    total_counter: Counter = Counter()

    for log in logs:
        normalized_code = _normalize_emotion_code(log.EMOTION_CODE)
        log_date = log.CREATED_AT.date()
        daily_counters[log_date][normalized_code] += 1
        total_counter[normalized_code] += 1
        if log.SCORE is not None:
            temperature_scores.append(float(log.SCORE))

    stickers: list[DailyEmotionSticker] = []
    for offset in range(days):
        day_date = start_time.date() + timedelta(days=offset)
        if day_date not in daily_counters:
            continue
        emotion_code = daily_counters[day_date].most_common(1)[0][0]
        character_key, label, _ = _pick_character_info(emotion_code)
        stickers.append(
            DailyEmotionSticker(
                day_label=DAY_LABELS[day_date.weekday()],
                date=_format_date(day_date),
                emotion_code=emotion_code,
                character_key=character_key,
                label=label,
            )
        )

    main_emotion = total_counter.most_common(1)[0][0]
    main_character_key, main_label, gauge_color = _pick_character_info(main_emotion)

    if temperature_scores:
        avg_temperature = sum(temperature_scores) / len(temperature_scores)
    else:
        avg_temperature = min(100, max(0, total_counter[main_emotion] * 10))

    temperature_label = f"온도 {int(round(avg_temperature))}°"

    return WeeklyEmotionReport(
        week_start=_format_date(start_time.date()),
        week_end=_format_date(end_time.date()),
        summary_title=f"금주의 너는 {main_label}",
        main_emotion_code=main_emotion,
        main_character_key=main_character_key,
        temperature=int(round(avg_temperature)),
        temperature_label=temperature_label,
        gauge_color=gauge_color,
        daily_stickers=stickers,
    )
