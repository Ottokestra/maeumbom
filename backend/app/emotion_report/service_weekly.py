from sqlalchemy import and_, desc
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import random  # For dummy logic

from .models_weekly import WeeklyEmotionReport, WeeklyEmotionDialogSnippet
from .schemas_weekly import WeeklyReportGenerateRequest


def get_weekly_report_by_id(db: Session, report_id: int):
    return (
        db.query(WeeklyEmotionReport)
        .filter(WeeklyEmotionReport.reportId == report_id)
        .first()
    )


def get_weekly_report_by_user_and_week(db: Session, user_id: int, week_start: datetime):
    return (
        db.query(WeeklyEmotionReport)
        .filter(
            and_(
                WeeklyEmotionReport.userId == user_id,
                WeeklyEmotionReport.weekStart == week_start,
            )
        )
        .first()
    )


def list_weekly_reports(db: Session, user_id: int, limit: int = 8):
    return (
        db.query(WeeklyEmotionReport)
        .filter(WeeklyEmotionReport.userId == user_id)
        .order_by(WeeklyEmotionReport.weekStart.desc())
        .limit(limit)
        .all()
    )


def generate_weekly_report(db: Session, request: WeeklyReportGenerateRequest):
    # Check existence
    existing = get_weekly_report_by_user_and_week(
        db, request.user_id, request.week_start
    )
    if existing and not request.regenerate:
        return existing

    if existing and request.regenerate:
        db.delete(existing)
        db.commit()

    # TODO: Real implementation: Fetch conversations from TB_CONVERSATIONS / TB_EMOTION_ANALYSIS
    # Reusing existing emotion analysis pipelines logic here.

    # Stub logic for now:
    temp = 36.5 + random.uniform(-2, 2)
    emotions = ["happiness", "sadness", "anger", "neutral", "anxiety"]
    main_emo = random.choice(emotions)

    report = WeeklyEmotionReport(
        userId=request.user_id,
        weekStart=request.week_start,
        weekEnd=request.week_end or (request.week_start + timedelta(days=6)),
        emotionTemperature=round(temp, 1),
        mainEmotion=main_emo,
        badges=["weekly_report_first"],
        summaryText=f"지난 주보다 조금 더 {main_emo}한 감정을 많이 느끼셨네요.",
        positiveScore=random.uniform(0, 1),
        negativeScore=random.uniform(0, 1),
        neutralScore=random.uniform(0, 1),
        mainEmotionConfidence=0.85,
        mainEmotionCharacterCode=f"CHAR_{main_emo.upper()}",
    )
    db.add(report)
    db.flush()

    # Add dummy snippets
    snippets_data = [
        ("USER", "이번 주는 정말 힘들었어.", "sadness"),
        ("ASSISTANT", "저런, 무슨 일 있으셨나요?", "neutral"),
        ("USER", "그냥 다 귀찮아.", "annoyance"),
    ]

    for role, content, emo in snippets_data:
        snip = WeeklyEmotionDialogSnippet(
            reportId=report.reportId, role=role, content=content, emotion=emo
        )
        db.add(snip)

    db.commit()
    db.refresh(report)
    return report
