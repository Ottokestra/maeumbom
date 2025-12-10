from __future__ import annotations

from collections import Counter, defaultdict
from datetime import date, datetime, time, timedelta
from typing import Dict, Iterable, List, Tuple

from sqlalchemy.orm import Session

from app.db.models import UserEmotionLog
from .schemas import DailyMoodSticker, WeeklyEmotionRanking, WeeklyMoodReportResponse


# 기본 캐릭터 매핑 (UI에서 사용하는 키)
EMOTION_INFO_MAP: Dict[str, Dict[str, str]] = {
    "joy": {"code": "JOY", "label": "기쁨", "character": "SUNFLOWER"},
    "happy": {"code": "JOY", "label": "기쁨", "character": "SUNFLOWER"},
    "happiness": {"code": "JOY", "label": "기쁨", "character": "SUNFLOWER"},
    "love": {"code": "LOVE", "label": "사랑", "character": "PENGUIN_HEART"},
    "affection": {"code": "LOVE", "label": "사랑", "character": "PENGUIN_HEART"},
    "sad": {"code": "SADNESS", "label": "슬픔", "character": "RAINDROP"},
    "sadness": {"code": "SADNESS", "label": "슬픔", "character": "RAINDROP"},
    "anger": {"code": "ANGER", "label": "분노", "character": "VOLCANO"},
    "angry": {"code": "ANGER", "label": "분노", "character": "VOLCANO"},
    "fear": {"code": "FEAR", "label": "두려움", "character": "OWL_FEAR"},
    "anxiety": {"code": "FEAR", "label": "불안", "character": "OWL_FEAR"},
    "surprise": {"code": "SURPRISE", "label": "놀람", "character": "CAT_SURPRISE"},
    "disgust": {"code": "DISGUST", "label": "혐오", "character": "CACTUS"},
    "neutral": {"code": "NEUTRAL", "label": "중립", "character": "BALANCE_ROCK"},
}

# 감정에 따른 기본 점수 (감정 스코어가 없을 때 사용)
EMOTION_SENTIMENT_WEIGHT: Dict[str, float] = {
    "joy": 1.0,
    "happy": 1.0,
    "happiness": 1.0,
    "love": 0.9,
    "affection": 0.9,
    "surprise": 0.2,
    "neutral": 0.0,
    "sad": -0.7,
    "sadness": -0.7,
    "anger": -0.8,
    "angry": -0.8,
    "fear": -0.6,
    "anxiety": -0.6,
    "disgust": -0.8,
}

WEEKDAYS = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]


def _normalize_label(label: str) -> str:
    return label.strip().lower()


def _get_emotion_info(label: str) -> Tuple[str, str, str]:
    key = _normalize_label(label)
    info = EMOTION_INFO_MAP.get(key)
    if info:
        return info["code"], info["label"], info["character"]
    return label.upper(), label, "DEFAULT"


def _calculate_overall_score(entries: Iterable[UserEmotionLog]) -> int:
    scores: List[float] = [
        entry.sentiment_score for entry in entries if entry.sentiment_score is not None
    ]
    if scores:
        avg_score = sum(scores) / len(scores)
    else:
        weights = [
            EMOTION_SENTIMENT_WEIGHT.get(_normalize_label(entry.emotion_label), 0.0)
            for entry in entries
        ]
        avg_score = sum(weights) / len(weights) if weights else 0.0

    scaled = int(round((avg_score + 1) / 2 * 100))
    return max(0, min(100, scaled))


def _build_week_label(week_start: date) -> str:
    week_number = ((week_start.day - 1) // 7) + 1
    return f"{week_start.year}년 {week_start.month}월 {week_number}주차"


def _build_daily_stickers(entries: List[UserEmotionLog], week_start: date) -> List[DailyMoodSticker]:
    stickers: List[DailyMoodSticker] = []
    entries_by_date: Dict[date, List[UserEmotionLog]] = defaultdict(list)
    for entry in entries:
        entries_by_date[entry.created_at.date()].append(entry)

    for idx in range(7):
        current_date = week_start + timedelta(days=idx)
        day_entries = entries_by_date.get(current_date, [])
        if not day_entries:
            stickers.append(
                DailyMoodSticker(
                    date=current_date,
                    weekday=WEEKDAYS[idx],
                    emotion_code=None,
                    emotion_label=None,
                    character_code=None,
                    has_record=False,
                )
            )
            continue

        counter = Counter(_normalize_label(entry.emotion_label) for entry in day_entries)
        top_label = counter.most_common(1)[0][0]
        code, label, character = _get_emotion_info(top_label)

        stickers.append(
            DailyMoodSticker(
                date=current_date,
                weekday=WEEKDAYS[idx],
                emotion_code=code,
                emotion_label=label,
                character_code=character,
                has_record=True,
            )
        )
    return stickers


def _build_rankings(counts: Counter, total: int) -> List[WeeklyEmotionRanking]:
    rankings: List[WeeklyEmotionRanking] = []
    for idx, (label_key, count) in enumerate(counts.most_common(5), start=1):
        code, label, character = _get_emotion_info(label_key)
        percent = (count / total * 100) if total else 0.0
        rankings.append(
            WeeklyEmotionRanking(
                rank=idx,
                code=code,
                label=label,
                percent=round(percent, 2),
                count=count,
                character_code=character,
            )
        )
    if not rankings:
        rankings.append(
            WeeklyEmotionRanking(
                rank=1,
                code="N/A",
                label="데이터 없음",
                percent=0.0,
                count=0,
                character_code="DEFAULT",
            )
        )
    return rankings


def _build_analysis_text(
    week_label: str, overall_score: int, rankings: List[WeeklyEmotionRanking]
) -> str:
    if rankings and rankings[0].count == 0:
        return f"{week_label}에는 아직 감정 기록이 없어요. 일기를 남기면 더 나은 리포트를 만들어드릴게요."

    top = rankings[0]
    secondary = rankings[1:3]
    secondary_text = ", ".join([f"{item.label} {item.percent:.0f}%" for item in secondary])
    base = f"{week_label} 동안 {top.label} 감정을 가장 많이 느끼셨어요 ({top.percent:.0f}%)."
    if secondary_text:
        base += f" 다음으로는 {secondary_text} 순으로 나타났어요."
    score_comment = "전체 정서가 안정적이에요." if overall_score >= 60 else "조금 더 마음을 돌봐주세요."
    return f"{base} 주간 감정 점수는 {overall_score}%입니다. {score_comment}"


def get_weekly_mood_report(
    db: Session, user_id: int, week_start: date, week_end: date
) -> WeeklyMoodReportResponse:
    start_dt = datetime.combine(week_start, time.min)
    end_dt = datetime.combine(week_end, time.max)

    entries: List[UserEmotionLog] = (
        db.query(UserEmotionLog)
        .filter(UserEmotionLog.user_id == user_id)
        .filter(UserEmotionLog.created_at >= start_dt)
        .filter(UserEmotionLog.created_at <= end_dt)
        .all()
    )

    normalized_labels = [_normalize_label(entry.emotion_label) for entry in entries]
    counts = Counter(normalized_labels)
    total = sum(counts.values())
    rankings = _build_rankings(counts, total)
    dominant_emotion = rankings[0]

    overall_score = _calculate_overall_score(entries)
    daily_stickers = _build_daily_stickers(entries, week_start)
    week_label = _build_week_label(week_start)
    analysis_text = _build_analysis_text(week_label, overall_score, rankings)

    return WeeklyMoodReportResponse(
        week_label=week_label,
        week_start=week_start,
        week_end=week_end,
        overall_score_percent=overall_score,
        dominant_emotion=dominant_emotion,
        daily_characters=daily_stickers,
        emotion_rankings=rankings,
        analysis_text=analysis_text,
    )
