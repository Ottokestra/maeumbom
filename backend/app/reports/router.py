"""Reports API router."""
from __future__ import annotations

from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.models import User
from app.db.database import get_db

from .services import build_weekly_report
from .schemas import WeeklyEmotionReportResponse

router = APIRouter(prefix="/api/reports", tags=["reports"])


@router.get("/emotion/weekly", response_model=WeeklyEmotionReportResponse)
def get_weekly_emotion_report(
    mock: bool = Query(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    로그인한 사용자의 이번 주 감정 리포트.
    mock=true 이면 DB 대신 샘플 데이터를 내려준다.
    """
    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)

    return build_weekly_report(
        db=db,
        user_id=current_user.ID,
        week_start=week_start,
        week_end=week_end,
        mock=mock,
    )
