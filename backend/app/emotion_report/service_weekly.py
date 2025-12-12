"""
Service layer for Weekly Emotion Report
Handles business logic for creating, retrieving, and listing weekly emotion reports
"""

from sqlalchemy.orm import Session
from datetime import date, timedelta
from typing import Optional, List
import json

from .models_weekly import WeeklyEmotionReport
from .schemas_weekly import WeeklyEmotionReportBase


def upsert_weekly_report(
    db: Session,
    user_id: int,
    week_start: date,
    week_end: date,
    payload: WeeklyEmotionReportBase,
) -> WeeklyEmotionReport:
    """
    Create or update a weekly emotion report

    Args:
        db: Database session
        user_id: User ID
        week_start: Start date of the week
        week_end: End date of the week
        payload: Report data

    Returns:
        WeeklyEmotionReport: Created or updated report
    """
    # Check if report already exists
    existing = (
        db.query(WeeklyEmotionReport)
        .filter(
            WeeklyEmotionReport.USER_ID == user_id,
            WeeklyEmotionReport.WEEK_START == week_start,
            WeeklyEmotionReport.WEEK_END == week_end,
        )
        .first()
    )

    # Convert badges list to JSON string
    badges_json = json.dumps(payload.badges) if payload.badges else None

    if existing:
        # Update existing report
        existing.EMOTION_TEMPERATURE = payload.emotion_temperature
        existing.POSITIVE_SCORE = payload.positive_score
        existing.NEGATIVE_SCORE = payload.negative_score
        existing.NEUTRAL_SCORE = payload.neutral_score
        existing.MAIN_EMOTION = payload.main_emotion
        existing.MAIN_EMOTION_CONFIDENCE = payload.main_emotion_confidence
        existing.MAIN_EMOTION_CHARACTER_CODE = payload.main_emotion_character_code
        existing.BADGES = badges_json
        existing.SUMMARY_TEXT = payload.summary_text

        db.commit()
        db.refresh(existing)
        return existing
    else:
        # Create new report
        new_report = WeeklyEmotionReport(
            USER_ID=user_id,
            WEEK_START=week_start,
            WEEK_END=week_end,
            EMOTION_TEMPERATURE=payload.emotion_temperature,
            POSITIVE_SCORE=payload.positive_score,
            NEGATIVE_SCORE=payload.negative_score,
            NEUTRAL_SCORE=payload.neutral_score,
            MAIN_EMOTION=payload.main_emotion,
            MAIN_EMOTION_CONFIDENCE=payload.main_emotion_confidence,
            MAIN_EMOTION_CHARACTER_CODE=payload.main_emotion_character_code,
            BADGES=badges_json,
            SUMMARY_TEXT=payload.summary_text,
        )

        db.add(new_report)
        db.commit()
        db.refresh(new_report)
        return new_report


def get_weekly_report_by_id(
    db: Session, user_id: int, report_id: int
) -> Optional[WeeklyEmotionReport]:
    """
    Get a weekly report by ID (with user_id check for security)

    Args:
        db: Database session
        user_id: User ID (for authorization)
        report_id: Report ID

    Returns:
        WeeklyEmotionReport or None
    """
    return (
        db.query(WeeklyEmotionReport)
        .filter(
            WeeklyEmotionReport.ID == report_id, WeeklyEmotionReport.USER_ID == user_id
        )
        .first()
    )


def get_weekly_report_by_week(
    db: Session, user_id: int, week_start: date, week_end: Optional[date] = None
) -> Optional[WeeklyEmotionReport]:
    """
    Get a weekly report by week range

    Args:
        db: Database session
        user_id: User ID
        week_start: Start date of the week
        week_end: End date of the week (optional, defaults to week_start + 6 days)

    Returns:
        WeeklyEmotionReport or None
    """
    if week_end is None:
        week_end = week_start + timedelta(days=6)

    return (
        db.query(WeeklyEmotionReport)
        .filter(
            WeeklyEmotionReport.USER_ID == user_id,
            WeeklyEmotionReport.WEEK_START == week_start,
            WeeklyEmotionReport.WEEK_END == week_end,
        )
        .first()
    )


def list_weekly_reports(
    db: Session, user_id: int, limit: int = 8
) -> List[WeeklyEmotionReport]:
    """
    List recent weekly reports for a user

    Args:
        db: Database session
        user_id: User ID
        limit: Maximum number of reports to return

    Returns:
        List of WeeklyEmotionReport
    """
    return (
        db.query(WeeklyEmotionReport)
        .filter(WeeklyEmotionReport.USER_ID == user_id)
        .order_by(WeeklyEmotionReport.WEEK_START.desc())
        .limit(limit)
        .all()
    )


def convert_badges_to_list(report: WeeklyEmotionReport) -> List[str]:
    """
    Convert badges JSON string to list

    Args:
        report: WeeklyEmotionReport instance

    Returns:
        List of badge strings
    """
    if report.BADGES:
        try:
            return json.loads(report.BADGES)
        except (json.JSONDecodeError, TypeError):
            return []
    return []
