"""서비스 레이어: 사용자 감정 리포트 생성"""
from __future__ import annotations

from collections import Counter
from datetime import datetime, timedelta
from typing import List
from typing_extensions import Literal
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.db.models import UserEmotionLog
from .schemas import EmotionMetric, TopEmotionItem, UserReportResponse


_PERIOD_DAYS = {
    "daily": 1,
    "weekly": 7,
    "monthly": 30,
}


def _get_period_range(period_type: Literal["daily", "weekly", "monthly"], now: datetime) -> tuple[datetime, datetime]:
    """주어진 기간 타입에 따른 시작/종료 시각을 반환한다."""

    if period_type == "daily":
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    else:
        days = _PERIOD_DAYS[period_type]
        start = (now - timedelta(days=days - 1)).replace(hour=0, minute=0, second=0, microsecond=0)
    end = now.replace(hour=23, minute=59, second=59, microsecond=999999)
    return start, end


def _build_top_emotions(
    db: Session, user_id: int, start: datetime, end: datetime, total_messages: int
) -> List[TopEmotionItem]:
    counts = (
        db.query(UserEmotionLog.emotion_label, func.count(UserEmotionLog.id).label("cnt"))
        .filter(UserEmotionLog.user_id == user_id)
        .filter(UserEmotionLog.created_at >= start)
        .filter(UserEmotionLog.created_at <= end)
        .group_by(UserEmotionLog.emotion_label)
        .order_by(func.count(UserEmotionLog.id).desc())
        .limit(3)
        .all()
    )

    top_items: List[TopEmotionItem] = []
    for label, cnt in counts:
        ratio = float(cnt) / total_messages if total_messages else 0.0
        top_items.append(TopEmotionItem(label=label, count=cnt, ratio=ratio))
    return top_items


def _build_highlights(
    db: Session, user_id: int, period_type: Literal["daily", "weekly", "monthly"], start: datetime, end: datetime
) -> List[str]:
    entries = (
        db.query(UserEmotionLog)
        .filter(UserEmotionLog.user_id == user_id)
        .filter(UserEmotionLog.created_at >= start)
        .filter(UserEmotionLog.created_at <= end)
        .order_by(UserEmotionLog.created_at.desc())
        .limit(20)
        .all()
    )

    if not entries:
        return []

    label_counts = Counter(entry.emotion_label for entry in entries)
    period_label = {"daily": "오늘", "weekly": "최근 7일", "monthly": "최근 30일"}[period_type]
    highlights: List[str] = []
    for label, count in label_counts.most_common(3):
        highlights.append(f"- {period_label} 동안 {label} 태그가 {count}회 기록되었습니다.")
    return highlights


def _build_recommendation(avg_sentiment: float, dominant_emotion: str | None) -> str:
    if avg_sentiment < -0.3:
        return "최근 정서가 많이 가라앉아 있습니다. 하루 10분 산책 또는 짧은 호흡 기도 시간을 가져보세요."
    if avg_sentiment > 0.3:
        return "긍정적인 정서가 우세합니다. 이 시기에 새로운 도전을 작게 하나 시도해 보세요."

    if dominant_emotion:
        return f"정서는 안정적입니다. '{dominant_emotion}' 감정을 살피며 감사 일기를 가볍게 써보면 어떨까요?"
    return "정서가 큰 기복 없이 유지되고 있습니다. 현재의 루틴을 가볍게 유지하면서, 감사 일기를 시도해보면 좋겠습니다."


def get_user_report(
    db: Session, user_id: int, period_type: Literal["daily", "weekly", "monthly"], now: datetime | None = None
) -> UserReportResponse:
    """사용자 감정 리포트를 생성한다."""

    now = now or datetime.utcnow()
    start, end = _get_period_range(period_type, now)

    total_messages = (
        db.query(func.count(UserEmotionLog.id))
        .filter(UserEmotionLog.user_id == user_id)
        .filter(UserEmotionLog.created_at >= start)
        .filter(UserEmotionLog.created_at <= end)
        .scalar()
        or 0
    )

    total_sessions = (
        db.query(func.count(func.distinct(UserEmotionLog.session_id)))
        .filter(UserEmotionLog.user_id == user_id)
        .filter(UserEmotionLog.created_at >= start)
        .filter(UserEmotionLog.created_at <= end)
        .scalar()
        or 0
    )

    avg_sentiment = (
        db.query(func.avg(UserEmotionLog.sentiment_score))
        .filter(UserEmotionLog.user_id == user_id)
        .filter(UserEmotionLog.created_at >= start)
        .filter(UserEmotionLog.created_at <= end)
        .scalar()
    )
    avg_sentiment = float(avg_sentiment) if avg_sentiment is not None else 0.0

    top_emotions = _build_top_emotions(db, user_id, start, end, total_messages)
    highlights = _build_highlights(db, user_id, period_type, start, end)
    dominant_emotion = top_emotions[0].label if top_emotions else None
    recommendation = _build_recommendation(avg_sentiment, dominant_emotion)

    metrics = EmotionMetric(
        period_start=start,
        period_end=end,
        total_sessions=total_sessions,
        total_messages=total_messages,
        avg_sentiment=avg_sentiment,
        top_emotions=top_emotions,
    )

    return UserReportResponse(
        period_type=period_type,
        period_start=start,
        period_end=end,
        metrics=metrics,
        recent_highlights=highlights,
        recommendation=recommendation,
    )
