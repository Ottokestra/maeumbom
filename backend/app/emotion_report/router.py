"""Emotion report API router."""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_optional_user
from app.auth.models import User
from app.db.database import get_db

from .schemas import WeeklyEmotionReport
from app.services.emotion_report_service import build_weekly_emotion_report

router = APIRouter(prefix="/api/reports/emotion", tags=["emotion_report"])


@router.get("/weekly", response_model=WeeklyEmotionReport)
def get_weekly_emotion_report(
    current_user: User | None = Depends(get_optional_user),
    db: Session = Depends(get_db),
):
    """현재 로그인한 사용자의 최근 감정 리포트를 반환한다."""

    user_id = current_user.ID if current_user else 1  # TODO: 실제 인증 적용 시 기본값 제거
    report = build_weekly_emotion_report(db=db, user_id=user_id)
    return report

