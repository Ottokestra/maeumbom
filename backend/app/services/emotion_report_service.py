"""Service layer for building weekly emotion reports."""
from __future__ import annotations

from collections import Counter, defaultdict
from datetime import date, datetime, timedelta
from typing import Dict, Iterable, Optional, Tuple

from sqlalchemy.orm import Session

from app.db.models import DailyMoodSelection, EmotionAnalysis
from app.schemas.emotion_report import EmotionDaySummary, WeeklyEmotionReport

WEEKDAY_LABELS = ["월", "화", "수", "목", "금", "토", "일"]

# 감정 키를 캐릭터 코드/라벨로 매핑
EMOTION_CHARACTER_MAP: Dict[str, Tuple[str, str]] = {
    "worry": ("PEACH_WORRY", "걱정이 복숭아"),
    "anxiety": ("PEACH_WORRY", "걱정이 복숭아"),
    "sad": ("CLOUD_SAD", "슬픈 구름"),
    "sadness": ("CLOUD_SAD", "슬픈 구름"),
    "joy": ("SUN_JOY", "반짝이는 햇살"),
    "happy": ("SUN_JOY", "반짝이는 햇살"),
    "anger": ("VOLCANO_ANGER", "화산 같은 분노"),
    "fear": ("NIGHT_FEAR", "두려움의 밤"),
}

DEFAULT_CHARACTER_CODE = "PEACH_WORRY"
DEFAULT_CHARACTER_LABEL = "걱정이 복숭아"


def get_week_range(today: date) -> tuple[date, date]:
    """Return (start, end) for the last 7 days including today."""

    start = today - timedelta(days=6)
    return start, today


def _clamp_temperature(value: float) -> int:
    return max(0, min(100, int(round(value))))


def _normalize_emotion_key(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    normalized = str(value).strip().lower()
    return normalized or None


def resolve_character_code(emotion_key: Optional[str]) -> Tuple[str, str]:
    """Resolve emotion key to (character_code, label)."""

    if emotion_key:
        mapped = EMOTION_CHARACTER_MAP.get(emotion_key)
        if mapped:
            return mapped
    return DEFAULT_CHARACTER_CODE, DEFAULT_CHARACTER_LABEL


def _extract_emotion_from_analysis(analysis: EmotionAnalysis) -> tuple[Optional[str], Optional[float]]:
    primary = analysis.PRIMARY_EMOTION or {}
    emotion_key = None
    score: Optional[float] = None

    if isinstance(primary, dict):
        emotion_key = (
            primary.get("key")
            or primary.get("emotion")
            or primary.get("code")
            or primary.get("label")
        )
        for candidate in ("score", "probability", "value"):
            if primary.get(candidate) is not None:
                try:
                    score = float(primary.get(candidate))
                except (TypeError, ValueError):
                    score = None
                break
    elif primary:
        emotion_key = str(primary)

    return _normalize_emotion_key(emotion_key), score


def _extract_emotion_from_selection(selection: DailyMoodSelection) -> tuple[Optional[str], Optional[float]]:
    result = selection.EMOTION_RESULT or {}
    emotion_key = None
    score: Optional[float] = None

    if isinstance(result, dict):
        primary = result.get("primary_emotion") or result
        if isinstance(primary, dict):
            emotion_key = (
                primary.get("key")
                or primary.get("emotion")
                or primary.get("code")
                or primary.get("label")
            )
            if primary.get("score") is not None:
                try:
                    score = float(primary.get("score"))
                except (TypeError, ValueError):
                    score = None
        else:
            emotion_key = primary
    elif result:
        emotion_key = result

    return _normalize_emotion_key(emotion_key), score


def load_weekly_emotion_data(
    db: Session, user_id: int, start_date: date, end_date: date
) -> Dict[date, Dict[str, Optional[float]]]:
    """Load emotion data from EmotionAnalysis and DailyMoodSelection within the range."""

    data: Dict[date, Dict[str, Optional[float]]] = {}

    start_dt = datetime.combine(start_date, datetime.min.time())
    end_dt = datetime.combine(end_date, datetime.max.time())

    analyses: Iterable[EmotionAnalysis] = (
        db.query(EmotionAnalysis)
        .filter(EmotionAnalysis.USER_ID == user_id)
        .filter(EmotionAnalysis.CREATED_AT >= start_dt)
        .filter(EmotionAnalysis.CREATED_AT <= end_dt)
        .all()
    )

    for analysis in analyses:
        emotion_key, score = _extract_emotion_from_analysis(analysis)
        if not emotion_key:
            continue
        day = analysis.CREATED_AT.date()
        if day not in data or data[day].get("score") is None:
            data[day] = {"emotion_key": emotion_key, "score": score}

    selections: Iterable[DailyMoodSelection] = (
        db.query(DailyMoodSelection)
        .filter(DailyMoodSelection.USER_ID == user_id)
        .filter(DailyMoodSelection.SELECTED_DATE >= start_date)
        .filter(DailyMoodSelection.SELECTED_DATE <= end_date)
        .all()
    )

    for selection in selections:
        if selection.SELECTED_DATE in data:
            continue
        emotion_key, score = _extract_emotion_from_selection(selection)
        if emotion_key:
            data[selection.SELECTED_DATE] = {"emotion_key": emotion_key, "score": score}

    return data


def generate_coach_message(main_emotion_key: Optional[str]) -> str:
    """Generate a simple rule-based coach message.

    TODO: 향후 딥에이전트 LLM 연동 지점
    """

    if not main_emotion_key:
        return "이번 주 감정 데이터를 더 모아볼까요? 나중에 함께 돌아볼게요."

    if main_emotion_key in {"worry", "anxiety"}:
        return (
            "이번 주에는 걱정과 불안이 조금 느껴졌어요. 어떤 일이 있었는지 천천히 나랑 "
            "이야기해볼래요?"
        )
    if main_emotion_key in {"sad", "sadness"}:
        return (
            "조금 무겁고 우울한 마음이 느껴져요. 혼자 끌어안지 말고, 나와 같이 "
            "나눠볼까요?"
        )
    if main_emotion_key in {"joy", "happy"}:
        return (
            "기분 좋은 순간들이 많았네요! 그 행복을 어떻게 더 이어갈 수 있을지 같이 이야기해봐요."
        )
    return "이번 주의 마음을 잘 들여다봤어요. 다음 주에는 어떤 기분을 만나게 될까요?"


def build_weekly_report(
    db: Session, user_id: int, today: Optional[date] = None
) -> Optional[WeeklyEmotionReport]:
    """Build a WeeklyEmotionReport from available data."""

    base_date = today or date.today()
    start_date, end_date = get_week_range(base_date)

    weekly_data = load_weekly_emotion_data(db, user_id, start_date, end_date)
    if not weekly_data:
        return None

    emotion_counts: Counter[str] = Counter()
    scores_by_emotion: Dict[str, list[float]] = defaultdict(list)

    for payload in weekly_data.values():
        emotion_key = payload.get("emotion_key")
        if not emotion_key:
            continue
        emotion_counts[emotion_key] += 1
        if payload.get("score") is not None:
            scores_by_emotion[emotion_key].append(float(payload["score"]))

    main_emotion_key = None
    if scores_by_emotion:
        avg_scores = {k: sum(v) / len(v) for k, v in scores_by_emotion.items()}
        main_emotion_key = max(avg_scores, key=lambda k: (avg_scores[k], emotion_counts[k]))
    elif emotion_counts:
        main_emotion_key = emotion_counts.most_common(1)[0][0]

    character_code, character_label = resolve_character_code(main_emotion_key)

    flat_scores = [score for payload in weekly_data.values() for score in [payload.get("score")] if score is not None]
    if flat_scores:
        avg_score = sum(flat_scores) / len(flat_scores)
        temperature = _clamp_temperature(avg_score * 100 if avg_score <= 1 else avg_score)
    else:
        temperature = 72

    days: list[EmotionDaySummary] = []
    day_count = (end_date - start_date).days + 1
    for offset in range(day_count):
        day = start_date + timedelta(days=offset)
        payload = weekly_data.get(day)
        emotion_key = payload.get("emotion_key") if payload else None
        resolved_code, _ = resolve_character_code(emotion_key) if emotion_key else (character_code, character_label)
        days.append(
            EmotionDaySummary(
                date=day,
                weekday_label=WEEKDAY_LABELS[day.weekday()],
                character_code=resolved_code,
                main_emotion=emotion_key,
            )
        )

    return WeeklyEmotionReport(
        has_data=True,
        start_date=start_date,
        end_date=end_date,
        title=f"금주의 너는 '{character_label}'",
        temperature=temperature,
        main_character_code=character_code,
        main_emotion=main_emotion_key,
        coach_message=generate_coach_message(main_emotion_key),
        days=days,
    )


def get_weekly_emotion_report(db: Session, user_id: int) -> Optional[WeeklyEmotionReport]:
    """High-level API to fetch the weekly emotion report for a user."""

    return build_weekly_report(db=db, user_id=user_id)
