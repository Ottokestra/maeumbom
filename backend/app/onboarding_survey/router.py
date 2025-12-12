from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.auth.dependencies import get_current_user
from app.db.models import User
from .schemas import (
    OnboardingSurveySubmitRequest,
    OnboardingSurveyResponse,
    OnboardingSurveyStatusResponse,
)
from . import service

router = APIRouter(
    prefix="/api/onboarding-survey",
    tags=["onboarding-survey"],
)


@router.post("/submit", response_model=OnboardingSurveyResponse)
def submit_onboarding_survey(
    payload: OnboardingSurveySubmitRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    온보딩 설문 제출 또는 수정 (Upsert)
    """
    profile = service.create_or_update_profile(db, current_user.ID, payload)
    return service.convert_profile_to_response(profile)


@router.get("/me", response_model=OnboardingSurveyResponse)
def get_my_profile(
    current_user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """
    내 온보딩 프로필 조회
    """
    profile = service.get_user_profile(db, current_user.ID)
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found. Please complete the onboarding survey.",
        )
    return service.convert_profile_to_response(profile)


@router.get("/status", response_model=OnboardingSurveyStatusResponse)
def get_onboarding_status(
    current_user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """
    온보딩 설문 완료 여부 확인
    """
    profile = service.get_user_profile(db, current_user.ID)

    if profile:
        return OnboardingSurveyStatusResponse(
            has_profile=True, profile=service.convert_profile_to_response(profile)
        )
    else:
        return OnboardingSurveyStatusResponse(has_profile=False, profile=None)
