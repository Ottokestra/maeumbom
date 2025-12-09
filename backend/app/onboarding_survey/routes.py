"""
API endpoints for onboarding survey
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.auth.dependencies import get_current_user
from app.auth.models import User

from .models import (
    OnboardingSurveySubmitRequest,
    OnboardingSurveyResponse,
    OnboardingSurveyStatusResponse
)
from .service import (
    get_user_profile,
    create_or_update_profile,
    convert_profile_to_response,
)


router = APIRouter()


@router.post("/submit", response_model=OnboardingSurveyResponse)
async def submit_onboarding_survey(
    request: OnboardingSurveySubmitRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={"detail": f"온보딩 설문 저장에 실패했습니다: {str(e)}", "code": "ONBOARDING_SAVE_FAILED"},
        )


@router.get("/me", response_model=OnboardingSurveyResponse)
async def get_my_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
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
            detail={"detail": "온보딩 설문이 없습니다. 먼저 제출해주세요.", "code": "PROFILE_NOT_FOUND"},
        )

    return convert_profile_to_response(profile)


@router.get("/status", response_model=OnboardingSurveyStatusResponse)
async def get_profile_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
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
            completed=True,
            profile=convert_profile_to_response(profile),
            missing_fields=[],
        )

    required_fields = [
        "nickname",
        "age_group",
        "gender",
        "marital_status",
        "children_yn",
        "living_with",
        "personality_type",
        "activity_style",
        "stress_relief",
        "hobbies",
    ]

    return OnboardingSurveyStatusResponse(
        completed=False,
        profile=None,
        missing_fields=required_fields,
    )

