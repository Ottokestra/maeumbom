from datetime import datetime, timedelta
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.db.database import get_db
from app.db.models import EmotionAnalysis, User

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
