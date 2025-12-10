"""주간 감정 리포트 API 라우터."""
from __future__ import annotations

from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.database import get_db
from .repository import EmotionWeeklyRepository
from .schemas import WeeklyEmotionReportResponse
from .services import build_weekly_emotion_report

router = APIRouter(prefix="/api/v1/reports/emotion", tags=["emotion-weekly-report"])


@router.get("/weekly", response_model=WeeklyEmotionReportResponse)
def get_weekly_emotion_report(
    user_id: int = Query(..., description="사용자 ID", ge=1),
    week_start: date | None = Query(None, description="주간 시작일 (YYYY-MM-DD)"),
    db: Session = Depends(get_db),
):
    """주간 감정 리포트를 조회한다."""

    try:
        repository = EmotionWeeklyRepository(db)
        return build_weekly_emotion_report(
            user_id=user_id, week_start=week_start, repository=repository
        )
    except HTTPException:
        raise
    except Exception as exc:  # pragma: no cover - 방어 로직
        raise HTTPException(status_code=500, detail="주간 리포트 생성에 실패했습니다.") from exc
