from fastapi import APIRouter

from .schemas import WeeklyEmotionReport
from .service import get_weekly_emotion_report

router = APIRouter(prefix="/api/reports/emotion", tags=["emotion-reports"])


@router.get("/weekly", response_model=WeeklyEmotionReport)
def read_weekly_emotion_report(user_id: int = 1):
    """
    주간 감정 리포트 목 API.
    - 현재는 user_id=1 고정 / 쿼리 파라미터로 받아서 사용
    - 나중에 인증 붙이면 토큰에서 user_id를 읽도록 수정 예정
    """
    return get_weekly_emotion_report(user_id=user_id)
