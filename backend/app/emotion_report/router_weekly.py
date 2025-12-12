"""
FastAPI router for Weekly Emotion Report endpoints
All endpoints require authentication and use current_user for data isolation
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional

from app.db.database import get_db
from app.auth.dependencies import get_current_user
from app.db.models import User

from .schemas_weekly import (
    WeeklyEmotionReportBase,
    WeeklyEmotionReportRead,
    WeeklyReportListResponse,
)
from .service_weekly import (
    upsert_weekly_report,
    get_weekly_report_by_id,
    get_weekly_report_by_week,
    list_weekly_reports,
    convert_badges_to_list,
)

router = APIRouter(
    prefix="/api/v1/reports/emotion/weekly", tags=["Weekly Emotion Report"]
)


def _convert_report_to_read(report) -> dict:
    """Convert SQLAlchemy model to response dict with badges as list"""
    return {
        "id": report.ID,
        "user_id": report.USER_ID,
        "week_start": report.WEEK_START,
        "week_end": report.WEEK_END,
        "emotion_temperature": report.EMOTION_TEMPERATURE,
        "positive_score": report.POSITIVE_SCORE,
        "negative_score": report.NEGATIVE_SCORE,
        "neutral_score": report.NEUTRAL_SCORE,
        "main_emotion": report.MAIN_EMOTION,
        "main_emotion_confidence": report.MAIN_EMOTION_CONFIDENCE,
        "main_emotion_character_code": report.MAIN_EMOTION_CHARACTER_CODE,
        "badges": convert_badges_to_list(report),
        "summary_text": report.SUMMARY_TEXT,
        "created_at": report.CREATED_AT,
        "updated_at": report.UPDATED_AT,
    }


def _convert_report_to_list_item(report) -> dict:
    """Convert SQLAlchemy model to list item dict"""
    return {
        "id": report.ID,
        "week_start": report.WEEK_START,
        "week_end": report.WEEK_END,
        "emotion_temperature": report.EMOTION_TEMPERATURE,
        "main_emotion": report.MAIN_EMOTION,
        "badges": convert_badges_to_list(report),
    }


@router.post("/generate", response_model=WeeklyEmotionReportRead)
def generate_weekly_report(
    week_start: str = Query(
        ..., alias="weekStart", description="Week start date (YYYY-MM-DD)"
    ),
    week_end: Optional[str] = Query(
        None,
        alias="weekEnd",
        description="Week end date (YYYY-MM-DD), defaults to week_start + 6 days",
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Generate or regenerate a weekly emotion report

    This endpoint calculates emotion metrics from conversation/emotion data
    and stores the result in the database.

    - **week_start**: Start date of the week (YYYY-MM-DD)
    - **week_end**: End date of the week (optional, defaults to week_start + 6 days)
    """
    # Parse dates
    try:
        week_start_date = datetime.strptime(week_start, "%Y-%m-%d").date()
        if week_end:
            week_end_date = datetime.strptime(week_end, "%Y-%m-%d").date()
        else:
            week_end_date = week_start_date + timedelta(days=6)
    except ValueError:
        raise HTTPException(
            status_code=400, detail="Invalid date format. Use YYYY-MM-DD"
        )

    # TODO: Implement actual emotion report calculation logic
    # For now, using dummy data
    # In production, this should:
    # 1. Query TB_EMOTION_ANALYSIS for the user within the date range
    # 2. Calculate emotion_temperature, scores, main_emotion, badges
    # 3. Generate summary_text

    import random

    emotions = ["happiness", "sadness", "anger", "neutral", "anxiety", "joy", "calm"]
    main_emo = random.choice(emotions)

    payload = WeeklyEmotionReportBase(
        week_start=week_start_date,
        week_end=week_end_date,
        emotion_temperature=random.randint(30, 45),
        positive_score=random.randint(20, 80),
        negative_score=random.randint(10, 60),
        neutral_score=random.randint(10, 50),
        main_emotion=main_emo,
        main_emotion_confidence=round(random.uniform(0.6, 0.95), 2),
        main_emotion_character_code=f"CHAR_{main_emo.upper()}",
        badges=["불안多", "지침", "회복시도"]
        if random.random() > 0.5
        else ["긍정", "활력"],
        summary_text=f"이번 주는 {main_emo} 감정이 주를 이루었습니다. 전반적으로 안정적인 한 주였어요.",
    )

    report = upsert_weekly_report(
        db=db,
        user_id=current_user.ID,
        week_start=week_start_date,
        week_end=week_end_date,
        payload=payload,
    )

    return _convert_report_to_read(report)


@router.get("/{report_id}", response_model=WeeklyEmotionReportRead)
def get_report_by_id(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get a specific weekly emotion report by ID

    Only returns reports belonging to the current user.

    - **report_id**: Report ID
    """
    report = get_weekly_report_by_id(db, current_user.ID, report_id)

    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    return _convert_report_to_read(report)


@router.get("", response_model=WeeklyEmotionReportRead)
def get_report_by_week(
    week_start: str = Query(
        ..., alias="weekStart", description="Week start date (YYYY-MM-DD)"
    ),
    week_end: Optional[str] = Query(
        None, alias="weekEnd", description="Week end date (YYYY-MM-DD)"
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get a weekly emotion report by week range

    - **week_start**: Start date of the week (YYYY-MM-DD)
    - **week_end**: End date of the week (optional, defaults to week_start + 6 days)
    """
    # Parse dates
    try:
        week_start_date = datetime.strptime(week_start, "%Y-%m-%d").date()
        if week_end:
            week_end_date = datetime.strptime(week_end, "%Y-%m-%d").date()
        else:
            week_end_date = week_start_date + timedelta(days=6)
    except ValueError:
        raise HTTPException(
            status_code=400, detail="Invalid date format. Use YYYY-MM-DD"
        )

    report = get_weekly_report_by_week(
        db, current_user.ID, week_start_date, week_end_date
    )

    if not report:
        raise HTTPException(status_code=404, detail="Report not found for this week")

    return _convert_report_to_read(report)


@router.get("/list", response_model=WeeklyReportListResponse)
def get_report_list(
    limit: int = Query(
        8, ge=1, le=100, description="Maximum number of reports to return"
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get a list of recent weekly emotion reports

    Returns the most recent N weekly reports for the current user.

    - **limit**: Maximum number of reports (default: 8, max: 100)
    """
    reports = list_weekly_reports(db, current_user.ID, limit)

    items = [_convert_report_to_list_item(report) for report in reports]

    return {"items": items}
