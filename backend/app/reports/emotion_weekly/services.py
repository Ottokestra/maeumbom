"""주간 감정 리포트 비즈니스 로직."""
from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Dict, Iterable, List, Tuple

from fastapi import HTTPException

from .repository import EmotionRecord, EmotionWeeklyRepository
from .schemas import (
    EmotionBadge,
    EmotionTemperature,
    MainEmotion,
    SummaryBubble,
    WeeklyEmotionReportResponse,
)

EMOTION_POLARITY: Dict[str, str] = {
    "기쁨": "positive",
    "희망": "positive",
    "설렘": "positive",
    "행복": "positive",
    "감사": "positive",
    "사랑": "positive",
    "평온": "neutral",
    "보통": "neutral",
    "중립": "neutral",
    "슬픔": "negative",
    "우울": "negative",
    "불안": "negative",
    "걱정": "negative",
    "두려움": "negative",
    "분노": "negative",
    "짜증": "negative",
    "화": "negative",
}

CHARACTER_CODE_MAP: Dict[str, str] = {
    "기쁨": "HAPPY_BIRD",
    "희망": "BRIGHT_DEER",
    "설렘": "SPARK_RABBIT",
    "행복": "HAPPY_BIRD",
    "감사": "GRATEFUL_DOG",
    "슬픔": "BLUE_WHALE",
    "우울": "BLUE_WHALE",
    "불안": "ANXIOUS_CAT",
    "걱정": "ANXIOUS_CAT",
    "두려움": "ANXIOUS_CAT",
    "분노": "ANGRY_BEAR",
    "짜증": "ANGRY_BEAR",
    "화": "ANGRY_BEAR",
}

BADGE_DEFINITIONS: Dict[str, Tuple[str, str]] = {
    "SAD_WEEK": ("우울 한 주", "슬픔·우울 계열 감정이 우세했던 주간"),
    "WORRIED_WEEK": ("걱정 많은 한 주", "불안·걱정 계열 감정이 우세했던 주간"),
    "HAPPY_WEEK": ("반짝이는 한 주", "기쁨·설렘 감정이 두드러진 주간"),
    "BALANCED_WEEK": ("균형 잡힌 한 주", "긍·부정 감정이 균형을 이룬 주간"),
}

SAD_EMOTIONS = {"슬픔", "우울"}
WORRIED_EMOTIONS = {"불안", "걱정", "두려움"}
HAPPY_EMOTIONS = {"기쁨", "설렘", "행복", "희망"}


def _resolve_week_range(week_start: date | None) -> tuple[date, date]:
    start = week_start or date.today() - timedelta(days=6)
    end = start + timedelta(days=6)
    if end < start:
        raise HTTPException(status_code=400, detail="week_start가 유효하지 않습니다.")
    return start, end


def _calculate_temperature(records: Iterable[EmotionRecord]) -> EmotionTemperature:
    positive_sum = 0.0
    negative_sum = 0.0
    for record in records:
        polarity = EMOTION_POLARITY.get(record.label)
        if polarity == "positive":
            positive_sum += record.score
        elif polarity == "negative":
            negative_sum += record.score

    total = positive_sum + negative_sum
    numerator = positive_sum - negative_sum
    raw_score = 50 + 50 * (numerator / max(total, 1.0))
    score = max(0, min(100, int(round(raw_score))))

    if score <= 39:
        level = "cold"
    elif score <= 59:
        level = "neutral"
    elif score <= 79:
        level = "warm"
    else:
        level = "hot"

    positive_ratio = positive_sum / total if total else 0.0
    negative_ratio = negative_sum / total if total else 0.0

    return EmotionTemperature(
        score=score,
        level=level,
        positive_ratio=round(positive_ratio, 2),
        negative_ratio=round(negative_ratio, 2),
    )


def _select_main_emotion(records: Iterable[EmotionRecord]) -> MainEmotion:
    score_by_label: Dict[str, float] = {}
    total = 0.0
    for record in records:
        score_by_label[record.label] = score_by_label.get(record.label, 0.0) + record.score
        total += record.score

    if not score_by_label:
        return MainEmotion(label="알수없음", confidence=0.0, character_code="BALANCED_FRIEND")

    main_label = max(score_by_label, key=score_by_label.get)
    confidence = score_by_label[main_label] / total if total else 0.0
    character_code = CHARACTER_CODE_MAP.get(main_label, "BALANCED_FRIEND")

    return MainEmotion(
        label=main_label,
        confidence=round(confidence, 2),
        character_code=character_code,
    )


def _determine_badge(records: Iterable[EmotionRecord]) -> EmotionBadge:
    total_score = sum(record.score for record in records)
    if total_score == 0:
        code = "BALANCED_WEEK"
    else:
        sadness_ratio = _sum_by_labels(records, SAD_EMOTIONS) / total_score
        worried_ratio = _sum_by_labels(records, WORRIED_EMOTIONS) / total_score
        happy_ratio = _sum_by_labels(records, HAPPY_EMOTIONS) / total_score

        if sadness_ratio >= 0.5:
            code = "SAD_WEEK"
        elif worried_ratio >= 0.5:
            code = "WORRIED_WEEK"
        elif happy_ratio >= 0.6:
            code = "HAPPY_WEEK"
        else:
            code = "BALANCED_WEEK"

    label, description = BADGE_DEFINITIONS[code]
    return EmotionBadge(code=code, label=label, description=description)


def _sum_by_labels(records: Iterable[EmotionRecord], labels: set[str]) -> float:
    return sum(record.score for record in records if record.label in labels)


def _build_summary_bubbles(
    conversations: List,
    main_emotion_label: str,
    max_pairs: int = 5,
) -> List[SummaryBubble]:
    """대화 로그를 기반으로 요약 말풍선을 구성한다."""

    bubbles: List[SummaryBubble] = []
    if not conversations:
        return bubbles

    ordered = list(reversed(conversations))
    pair_count = 0
    i = 0
    while i < len(ordered) and pair_count < max_pairs:
        message = ordered[i]
        if message.SPEAKER_TYPE.startswith("user"):
            user_text = _truncate_text(message.CONTENT)
            assistant_text = ""
            if i + 1 < len(ordered):
                next_message = ordered[i + 1]
                if next_message.SPEAKER_TYPE == "assistant":
                    assistant_text = _truncate_text(next_message.CONTENT)
                    i += 1
            bubbles.append(
                SummaryBubble(
                    role="user",
                    text=user_text,
                    emotion_label=main_emotion_label or "기타",
                )
            )
            if assistant_text:
                bubbles.append(
                    SummaryBubble(
                        role="assistant",
                        text=assistant_text,
                        emotion_label="기타",
                    )
                )
            pair_count += 1
        i += 1

    return bubbles


def _truncate_text(text: str, max_length: int = 120) -> str:
    compact = " ".join(text.split())
    if len(compact) <= max_length:
        return compact
    return compact[: max_length - 3] + "..."


def build_weekly_emotion_report(
    user_id: int, week_start: date | None, repository: EmotionWeeklyRepository
) -> WeeklyEmotionReportResponse:
    start_date, end_date = _resolve_week_range(week_start)
    start_dt = datetime.combine(start_date, datetime.min.time())
    end_dt = datetime.combine(end_date, datetime.max.time())

    records = repository.fetch_emotion_records(user_id=user_id, start=start_dt, end=end_dt)
    conversations = repository.fetch_conversations(user_id=user_id, start=start_dt, end=end_dt)

    temperature = _calculate_temperature(records)
    main_emotion = _select_main_emotion(records)
    badge = _determine_badge(records)
    summary_bubbles = _build_summary_bubbles(conversations, main_emotion.label)

    return WeeklyEmotionReportResponse(
        user_id=user_id,
        week_start=start_date,
        week_end=end_date,
        temperature=temperature,
        main_emotion=main_emotion,
        badge=badge,
        summary_bubbles=summary_bubbles,
    )
