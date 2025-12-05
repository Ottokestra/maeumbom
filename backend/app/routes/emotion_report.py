from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_db
from app.schemas.emotion_report import WeeklyEmotionReport
from app.services.emotion_report_service import get_weekly_emotion_report

router = APIRouter(prefix="/reports/emotion", tags=["emotion-report"])


@router.get("/weekly", response_model=WeeklyEmotionReport)
def get_weekly_report(user_id: int = 1, db: Session = Depends(get_db)):
    """
    현재 로그인 유저의 최근 7일 감정 리포트를 반환.
    - 데이터가 없으면 404로 응답하여 프론트에서 '오늘은 아직 데이터가 없어요' 화면을 보여줄 수 있도록 한다.
    """
    # TODO: 인증 연동 시 current_user.id로 교체
    report = get_weekly_emotion_report(db=db, user_id=user_id)
    if report is None or not report.has_data:
        raise HTTPException(status_code=404, detail="No emotion data for this week")
    return report
