from __future__ import annotations

from collections import Counter, defaultdict
from datetime import date, datetime, time, timedelta
from typing import Any, Dict, Iterable, List, Tuple

from sqlalchemy.orm import Session

from app.db.models import EmotionAnalysis
from .schemas import (
    DailyMoodSticker,
    HighlightConversation,
    WeeklyEmotionRanking,
    WeeklyMoodReportResponse,
    WeeklySentimentPoint,
)


# 기본 캐릭터 매핑 (UI에서 사용하는 키)
EMOTION_INFO_MAP: Dict[str, Dict[str, str]] = {
    "joy": {"code": "joy", "label": "기쁨", "character": "PENGUIN_HEART"},
    "happy": {"code": "joy", "label": "기쁨", "character": "PENGUIN_HEART"},
    "happiness": {"code": "joy", "label": "기쁨", "character": "PENGUIN_HEART"},
    "love": {"code": "love", "label": "사랑", "character": "PENGUIN_HEART"},
    "affection": {"code": "love", "label": "사랑", "character": "PENGUIN_HEART"},
    "discontent": {"code": "discontent", "label": "불만", "character": "TIGER"},
    "sad": {"code": "sadness", "label": "슬픔", "character": "RAINDROP"},
    "sadness": {"code": "sadness", "label": "슬픔", "character": "RAINDROP"},
    "anger": {"code": "anger", "label": "분노", "character": "VOLCANO"},
    "angry": {"code": "anger", "label": "분노", "character": "VOLCANO"},
    "fear": {"code": "fear", "label": "두려움", "character": "OWL_FEAR"},
    "anxiety": {"code": "fear", "label": "불안", "character": "OWL_FEAR"},
    "surprise": {"code": "surprise", "label": "놀람", "character": "CAT_SURPRISE"},
    "disgust": {"code": "disgust", "label": "혐오", "character": "CACTUS"},
    "neutral": {"code": "neutral", "label": "중립", "character": "BALANCE_ROCK"},
}

WEEKDAYS = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]


def _normalize_label(label: str) -> str:
    return (label or "").strip().lower()


def _get_character_code(code: str) -> str:
    info = EMOTION_INFO_MAP.get(_normalize_label(code))
    if info:
        return info["character"]
    return "DEFAULT"


def _to_sentiment_score(sentiment_overall: str) -> float:
    if sentiment_overall == "positive":
        return 1.0
    if sentiment_overall == "negative":
        return -1.0
    return 0.0


def _calculate_overall_score(scores: Iterable[float]) -> int:
    score_list = list(scores)
    avg_score = sum(score_list) / len(score_list) if score_list else 0.0
    scaled = int(round((avg_score + 1) / 2 * 100))
    return max(0, min(100, scaled))


def _extract_primary_emotion(primary: Dict[str, Any]) -> Tuple[str, str, str, str, float]:
    code_raw = primary.get("code") or ""
    label = primary.get("name_ko") or primary.get("label") or code_raw or "알수없음"
    normalized = _normalize_label(code_raw or label)
    character = _get_character_code(normalized)
    intensity = primary.get("intensity", 0.0) if isinstance(primary, dict) else 0.0
    return code_raw or normalized.upper(), label, character, normalized, float(intensity)


def _build_week_label(week_start: date) -> str:
    week_number = ((week_start.day - 1) // 7) + 1
    return f"{week_start.year}년 {week_start.month}월 {week_number}주차"


def _build_daily_stickers(
    entries_by_date: Dict[date, List[str]],
    week_start: date,
    label_map: Dict[str, Tuple[str, str, str]],
) -> List[DailyMoodSticker]:
    stickers: List[DailyMoodSticker] = []
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

        counter = Counter(day_entries)
        top_label = counter.most_common(1)[0][0]
        code, label, character = label_map.get(
            top_label, (top_label.upper(), top_label, "DEFAULT")
        )

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


def _build_rankings(
    counts: Counter, label_map: Dict[str, Tuple[str, str, str]]
) -> List[WeeklyEmotionRanking]:
    rankings: List[WeeklyEmotionRanking] = []
    total = sum(counts.values())
    for idx, (label_key, count) in enumerate(counts.most_common(5), start=1):
        code, label, character = label_map.get(
            label_key, (label_key.upper(), label_key, "DEFAULT")
        )
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


def _get_risk_level(item: EmotionAnalysis) -> str:
    signals = item.SERVICE_SIGNALS or {}
    return signals.get("risk_level", "normal")


def _risk_priority(level: str) -> int:
    order = {"risk": 0, "watch": 1, "normal": 2}
    return order.get(level, 3)


def get_weekly_mood_report(
    db: Session, user_id: int, week_start: date, week_end: date
) -> WeeklyMoodReportResponse:
    start_dt = datetime.combine(week_start, time.min)
    end_dt = datetime.combine(week_end + timedelta(days=1), time.min)

    records: List[EmotionAnalysis] = (
        db.query(EmotionAnalysis)
        .filter(
            EmotionAnalysis.USER_ID == user_id,
            EmotionAnalysis.CREATED_AT >= start_dt,
            EmotionAnalysis.CREATED_AT < end_dt,
            EmotionAnalysis.CHECK_ROOT == "conversation",
        )
        .all()
    )

    counts: Counter = Counter()
    label_map: Dict[str, Tuple[str, str, str]] = {}
    entries_by_date: Dict[date, List[str]] = defaultdict(list)
    sentiment_scores: List[float] = []
    sentiment_timeline: List[WeeklySentimentPoint] = []

    for record in sorted(records, key=lambda item: item.CREATED_AT):
        primary_emotion = record.PRIMARY_EMOTION or {}
        code_raw, label, character, normalized, intensity = _extract_primary_emotion(
            primary_emotion
        )
        counts[normalized] += 1
        label_map[normalized] = (code_raw, label, character)
        created_date = record.CREATED_AT.date()
        entries_by_date[created_date].append(normalized)

        score = _to_sentiment_score(record.SENTIMENT_OVERALL)
        sentiment_scores.append(score)
        sentiment_timeline.append(
            WeeklySentimentPoint(
                timestamp=record.CREATED_AT,
                sentiment_score=score,
                sentiment_overall=record.SENTIMENT_OVERALL,
                primary_emotion_code=code_raw,
                primary_emotion_label=label,
                character_code=character,
            )
        )

    rankings = _build_rankings(counts, label_map)
    dominant_emotion = rankings[0]

    overall_score = _calculate_overall_score(sentiment_scores)
    daily_stickers = _build_daily_stickers(entries_by_date, week_start, label_map)
    week_label = _build_week_label(week_start)
    analysis_text = _build_analysis_text(week_label, overall_score, rankings)

    records_sorted = sorted(
        records,
        key=lambda r: (
            _risk_priority(_get_risk_level(r)),
            -float((r.MIXED_EMOTION or {}).get("mixed_ratio", 0.0) or 0.0),
            -float((r.PRIMARY_EMOTION or {}).get("intensity", 0.0) or 0.0),
            r.CREATED_AT,
        ),
    )

    highlight_conversations: List[HighlightConversation] = []
    for r in records_sorted[:5]:
        primary = r.PRIMARY_EMOTION or {}
        code_raw, label, _, _, _ = _extract_primary_emotion(primary)
        signals = r.SERVICE_SIGNALS or {}
        tags = r.REPORT_TAGS or []
        highlight_conversations.append(
            HighlightConversation(
                id=r.ID,
                text=r.TEXT,
                created_at=r.CREATED_AT,
                sentiment_overall=r.SENTIMENT_OVERALL,
                primary_emotion_code=code_raw,
                primary_emotion_label=label,
                risk_level=signals.get("risk_level"),
                report_tags=tags,
            )
        )

    return WeeklyMoodReportResponse(
        week_label=week_label,
        week_start=week_start,
        week_end=week_end,
        overall_score_percent=overall_score,
        dominant_emotion=dominant_emotion,
        daily_characters=daily_stickers,
        emotion_rankings=rankings,
        analysis_text=analysis_text,
        sentiment_timeline=sentiment_timeline,
        highlight_conversations=highlight_conversations,
    )
