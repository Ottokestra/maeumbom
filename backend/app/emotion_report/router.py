"""Emotion report API router."""
from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.models import User
from app.db.database import get_db

from .schemas import WeeklyEmotionReport
from .services import build_weekly_emotion_report

router = APIRouter(prefix="/api/reports/emotion", tags=["emotion_report"])


@router.get("/weekly", response_model=WeeklyEmotionReport)
def get_weekly_emotion_report(
    base_date: date | None = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """현재 로그인한 사용자의 최근 1주 감정 리포트 반환."""

    report = build_weekly_emotion_report(db=db, user_id=current_user.id, base_date=base_date)
    return report

