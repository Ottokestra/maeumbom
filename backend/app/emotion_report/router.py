"""Emotion report API router."""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.auth.dependencies import get_optional_user
from app.auth.models import User
from app.db.database import get_db

from .schemas import WeeklyEmotionReport
from app.services.emotion_report_service import build_weekly_emotion_report

router = APIRouter(prefix="/api/reports/emotion", tags=["emotion_report"])


@router.get(
    "/weekly",
    response_model=WeeklyEmotionReport,
    summary="주간 감정 리포트 조회",
    description="최근 일주일 간의 감정 로그를 기반으로 요약된 감정 리포트를 반환합니다.",
)
def get_weekly_emotion_report(
    user_id: int = Query(1, description="사용자 ID (임시: 로그인 연동 전까지 기본값 1)", ge=1),
    base_date: Optional[str] = Query(
        None, description="리포트 기준 날짜 (YYYY-MM-DD). 미지정 시 오늘 기준"
    ),
    current_user: User | None = Depends(get_optional_user),
    db: Session = Depends(get_db),
):
    """현재 로그인한 사용자의 최근 감정 리포트를 반환한다."""

    resolved_user_id = current_user.ID if current_user else user_id

    parsed_base_date = None
    if base_date:
        try:
            parsed_base_date = datetime.strptime(base_date, "%Y-%m-%d").date()
        except ValueError as exc:  # pragma: no cover - simple validation guard
            raise HTTPException(status_code=400, detail="base_date 형식이 올바르지 않습니다.") from exc

    try:
        report = build_weekly_emotion_report(
            db=db, user_id=resolved_user_id, base_date=parsed_base_date
        )
    except HTTPException:
        raise
    except Exception as exc:  # pragma: no cover - defensive
        raise HTTPException(status_code=500, detail="주간 리포트 생성 중 오류가 발생했습니다.") from exc

    return report

