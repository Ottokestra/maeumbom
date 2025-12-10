"""보고서 API 라우터."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.db.database import get_db
from app.db.models import User
from .schemas import UserReportResponse
from .services import get_user_report

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/me/daily", response_model=UserReportResponse)
def get_daily_report(
    db: Session = Depends(get_db), current_user: User = Depends(get_current_user)
):
    """일간 감정 리포트를 반환한다."""

    return get_user_report(db=db, user_id=current_user.ID, period_type="daily")


@router.get("/me/weekly", response_model=UserReportResponse)
def get_weekly_report(
    db: Session = Depends(get_db), current_user: User = Depends(get_current_user)
):
    """주간 감정 리포트를 반환한다."""

    return get_user_report(db=db, user_id=current_user.ID, period_type="weekly")


@router.get("/me/monthly", response_model=UserReportResponse)
def get_monthly_report(
    db: Session = Depends(get_db), current_user: User = Depends(get_current_user)
):
    """월간 감정 리포트를 반환한다."""

    return get_user_report(db=db, user_id=current_user.ID, period_type="monthly")
