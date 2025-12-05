"""Service for building weekly emotion reports."""
from __future__ import annotations

from collections import Counter, defaultdict
from datetime import date, datetime, timedelta
from typing import Dict, Tuple

from sqlalchemy.orm import Session

from app.db.models import EmotionLog
from app.emotion_report.schemas import WeeklyEmotionItem, WeeklyEmotionReport

DAY_LABELS = ["월", "화", "수", "목", "금", "토", "일"]
DEFAULT_EMOTION_CODE = "worry"
DEFAULT_EMOJI = "🍑"
DEFAULT_LABEL = "걱정이 복숭아"

# 간단한 감정 코드 → 캐릭터 이모지/라벨 매핑
EMOTION_DISPLAY_MAP: Dict[str, Tuple[str, str]] = {
    "worry": ("🍑", "걱정이 복숭아"),
    "sad": ("🌧️", "우울한 구름"),
    "anger": ("🔥", "화난 불꽃"),
    "anxiety": ("🌧️", "걱정 빗방울"),
    "stress": ("⛈️", "스트레스 번개"),
    "happy": ("☀️", "기쁨 햇살"),
    "joy": ("☀️", "기쁨 햇살"),
    "relief": ("🍃", "안도 바람"),
    "proud": ("⭐", "뿌듯한 별"),
    "love": ("💖", "사랑 하트"),
    "neutral": ("🍀", "담담한 잎새"),
    "calm": ("🍀", "담담한 잎새"),
    "energetic": ("⚡", "에너지 스파크"),
    "lonely": ("🌙", "외로운 달"),
    "hope": ("🌱", "희망 씨앗"),
    "grateful": ("🎁", "감사 선물"),
}


def _normalize_emotion_code(emotion_code: str | None) -> str:
    if not emotion_code:
        return DEFAULT_EMOTION_CODE
    return str(emotion_code).strip().lower() or DEFAULT_EMOTION_CODE


def _pick_display(emotion_code: str) -> tuple[str, str]:
    return EMOTION_DISPLAY_MAP.get(emotion_code, (DEFAULT_EMOJI, DEFAULT_LABEL))


def build_weekly_emotion_report(db: Session, user_id: int, days: int = 7) -> WeeklyEmotionReport:
    """최근 N일 간 감정 로그를 기반으로 주간 리포트를 생성한다."""

    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=days)

    logs = (
        db.query(EmotionLog)
        .filter(EmotionLog.IS_DELETED == False)
        .filter(EmotionLog.USER_ID == user_id)
        .filter(EmotionLog.CREATED_AT >= start_time)
        .order_by(EmotionLog.CREATED_AT.asc())
        .all()
    )

    if not logs:
        return WeeklyEmotionReport(hasData=False, weeklyEmotions=[])

    daily_counters: Dict[date, Counter] = defaultdict(Counter)
    total_counter: Counter = Counter()

    for log in logs:
        normalized_code = _normalize_emotion_code(log.EMOTION_CODE)
        log_date = log.CREATED_AT.date()
        daily_counters[log_date][normalized_code] += 1
        total_counter[normalized_code] += 1

    weekly_items: list[WeeklyEmotionItem] = []
    for log_date in sorted(daily_counters.keys()):
        emotion_code = daily_counters[log_date].most_common(1)[0][0]
        emoji, _ = _pick_display(emotion_code)
        weekly_items.append(
            WeeklyEmotionItem(
                day=DAY_LABELS[log_date.weekday()],
                emoji=emoji,
                emotion_code=emotion_code,
            )
        )

    main_emotion = total_counter.most_common(1)[0][0]
    main_emoji, main_label = _pick_display(main_emotion)
    temperature = max(0, min(100, total_counter[main_emotion] * 10))

    return WeeklyEmotionReport(
        hasData=True,
        summaryTitle=f"금주의 너는 '{main_label}'",
        mainCharacterEmoji=main_emoji,
        temperature=temperature,
        weeklyEmotions=weekly_items,
    )
