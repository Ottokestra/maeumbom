"""
API endpoints for onboarding survey
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.auth.dependencies import get_current_user
from app.auth.models import User

from .schemas import (
    OnboardingSurveySubmitRequest,
    OnboardingSurveyResponse,
    OnboardingSurveyStatusResponse,
)
from .service import (
    get_user_profile,
    create_or_update_profile,
    check_profile_exists,
    convert_profile_to_response,
)


router = APIRouter()


@router.post("/submit", response_model=OnboardingSurveyResponse)
async def submit_onboarding_survey(
    request: OnboardingSurveySubmitRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Submit or update onboarding survey

    - **Upsert**: Creates new profile if not exists, updates if exists
    - **Authentication**: Required

    Args:
        request: Survey submission data
        db: Database session
        current_user: Current authenticated user

    Returns:
        Created or updated user profile
    """
    try:
        profile = create_or_update_profile(db, current_user.ID, request)
        return convert_profile_to_response(profile)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save profile: {str(e)}")


@router.get("/me", response_model=OnboardingSurveyResponse)
async def get_my_profile(
    db: Session = Depends(get_db), current_user: User = Depends(get_current_user)
):
    """
    Get my onboarding survey profile

    - **Authentication**: Required

    Args:
        db: Database session
        current_user: Current authenticated user

    Returns:
        User profile data

    Raises:
        404: Profile not found
    """
    profile = get_user_profile(db, current_user.ID)

    if not profile:
        raise HTTPException(
            status_code=404,
            detail="Profile not found. Please complete the onboarding survey.",
        )

    return convert_profile_to_response(profile)


@router.get("/status", response_model=OnboardingSurveyStatusResponse)
async def get_profile_status(
    db: Session = Depends(get_db), current_user: User = Depends(get_current_user)
):
    """
    Check if user has completed onboarding survey

    - **Authentication**: Required

    Args:
        db: Database session
        current_user: Current authenticated user

    Returns:
        Profile completion status
    """
    profile = get_user_profile(db, current_user.ID)

    if profile:
        return OnboardingSurveyStatusResponse(
            has_profile=True, profile=convert_profile_to_response(profile)
        )
    else:
        return OnboardingSurveyStatusResponse(has_profile=False, profile=None)
