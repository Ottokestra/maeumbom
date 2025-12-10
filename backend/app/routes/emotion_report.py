from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.emotion_report.schemas import WeeklyEmotionReport
from app.services.emotion_report_service import get_weekly_emotion_report

router = APIRouter(prefix="/reports/emotion", tags=["emotion-report"])


@router.get("/weekly", response_model=WeeklyEmotionReport)
def read_weekly_emotion_report(db: Session = Depends(get_db), user_id: int = 1):
    """
    임시로 user_id=1 기준의 주간 감정 리포트 반환.
    나중에 인증 붙이면 JWT에서 user_id 추출하도록 수정.
    """
    return get_weekly_emotion_report(db, user_id=user_id)
