from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional

from app.db.database import get_db
from .schemas_weekly import (
    WeeklyReportGenerateRequest,
    WeeklyEmotionReport,
    WeeklyReportListResponse,
    WeeklyEmotionReportDetail,
)
from .service_weekly import (
    generate_weekly_report,
    get_weekly_report_by_id,
    get_weekly_report_by_user_and_week,
    list_weekly_reports,
)

router = APIRouter(prefix="/api/v1/reports/emotion/weekly", tags=["emotion-weekly"])


@router.post("/generate", response_model=WeeklyEmotionReport)
def generate_report(
    payload: WeeklyReportGenerateRequest, db: Session = Depends(get_db)
):
    return generate_weekly_report(db, payload)


@router.get("/list", response_model=WeeklyReportListResponse)
def list_reports(
    userId: int = Query(...), limit: int = 8, db: Session = Depends(get_db)
):
    reports = list_weekly_reports(db, userId, limit)
    return WeeklyReportListResponse(items=reports)


@router.get("/{reportId}", response_model=WeeklyEmotionReportDetail)
def get_report(reportId: int, db: Session = Depends(get_db)):
    report = get_weekly_report_by_id(db, reportId)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return report


@router.get("", response_model=WeeklyEmotionReport)
def get_report_by_params(
    userId: int = Query(...),
    weekStart: str = Query(..., description="YYYY-MM-DD"),
    weekEnd: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    try:
        # Pydantic schemas expect datetime, but URL param is str.
        # However, we pass datetime object to service.
        # But for request parsing, FastAPI handles conversion?
        # weekStart is defined as str in this function signature.
        dt = datetime.strptime(weekStart, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(
            status_code=400, detail="Invalid date format. Use YYYY-MM-DD"
        )

    report = get_weekly_report_by_user_and_week(db, userId, dt)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return report
