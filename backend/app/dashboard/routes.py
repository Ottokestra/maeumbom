from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.db.database import get_db
from app.db.models import EmotionAnalysis, User
from app.dashboard.service import get_weekly_mood_report
from app.dashboard.schemas import WeeklyMoodReportResponse

router = APIRouter()

@router.get("/emotion-history")
async def get_emotion_history(
    days: int = 7,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    대시보드용 감정 분석 히스토리 조회
    """
    try:
        since = datetime.utcnow() - timedelta(days=days)

        emotions = (
            db.query(EmotionAnalysis)
            .filter(
                EmotionAnalysis.USER_ID == current_user.ID,
                EmotionAnalysis.CREATED_AT >= since,
            )
            .order_by(desc(EmotionAnalysis.CREATED_AT))
            .all()
        )

        data = [
            {
                "created_at": record.CREATED_AT,
                "sentiment_overall": record.SENTIMENT_OVERALL,
                "primary_emotion": record.PRIMARY_EMOTION,
                "service_signals": record.SERVICE_SIGNALS,
                "check_root": record.CHECK_ROOT,
            }
            for record in emotions
        ]

        return {"data": data}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={"detail": f"감정 이력 조회 실패: {str(e)}", "code": "DASHBOARD_FETCH_FAILED"},
        )


@router.get("/weekly-mood-report", response_model=WeeklyMoodReportResponse)
async def get_weekly_mood_report_endpoint(
    week_offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    주간 감정 리포트 조회
    """
    try:
        today = datetime.now(ZoneInfo("Asia/Seoul")).date()
        target_date = today + timedelta(weeks=week_offset)
        week_start = target_date - timedelta(days=target_date.weekday())
        week_end = week_start + timedelta(days=6)

        return get_weekly_mood_report(
            db=db, user_id=current_user.ID, week_start=week_start, week_end=week_end
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={"detail": f"주간 감정 리포트 생성 실패: {str(e)}", "code": "WEEKLY_MOOD_REPORT_FAILED"},
        )
