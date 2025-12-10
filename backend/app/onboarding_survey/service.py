"""
Business logic for onboarding survey service
"""
from sqlalchemy.orm import Session
from typing import Optional

from fastapi import HTTPException
from sqlalchemy import and_
from sqlalchemy.orm import Session

from app.db.models import UserProfile
from .models import OnboardingSurveySubmitRequest, OnboardingSurveyResponse


def get_user_profile(db: Session, user_id: int) -> Optional[UserProfile]:
    """
    Get user profile by user_id
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        UserProfile object or None
    """
    return db.query(UserProfile).filter(
        and_(
            UserProfile.USER_ID == user_id,
            UserProfile.IS_DELETED == False
        )
    ).first()


def create_or_update_profile(
    db: Session,
    user_id: int,
    request: OnboardingSurveySubmitRequest
) -> UserProfile:
    """
    Create or update user profile (Upsert)
    
    Args:
        db: Database session
        user_id: User ID
        request: Survey submission request
        
    Returns:
        Created or updated UserProfile object
    """
    # Check if profile already exists
    existing_profile = get_user_profile(db, user_id)
    
    if existing_profile:
        # UPDATE existing profile
        existing_profile.NICKNAME = request.nickname
        existing_profile.AGE_GROUP = request.age_group
        existing_profile.GENDER = request.gender
        existing_profile.MARITAL_STATUS = request.marital_status
        existing_profile.CHILDREN_YN = request.children_yn
        existing_profile.LIVING_WITH = request.living_with
        existing_profile.PERSONALITY_TYPE = request.personality_type
        existing_profile.ACTIVITY_STYLE = request.activity_style
        existing_profile.STRESS_RELIEF = request.stress_relief
        existing_profile.HOBBIES = request.hobbies
        existing_profile.ATMOSPHERE = request.atmosphere
        existing_profile.UPDATED_BY = user_id
        
        db.commit()
        db.refresh(existing_profile)
        return existing_profile
    else:
        # INSERT new profile
        new_profile = UserProfile(
            USER_ID=user_id,
            NICKNAME=request.nickname,
            AGE_GROUP=request.age_group,
            GENDER=request.gender,
            MARITAL_STATUS=request.marital_status,
            CHILDREN_YN=request.children_yn,
            LIVING_WITH=request.living_with,
            PERSONALITY_TYPE=request.personality_type,
            ACTIVITY_STYLE=request.activity_style,
            STRESS_RELIEF=request.stress_relief,
            HOBBIES=request.hobbies,
            ATMOSPHERE=request.atmosphere,
            CREATED_BY=user_id
        )
        
        db.add(new_profile)
        db.commit()
        db.refresh(new_profile)
        return new_profile


def check_profile_exists(db: Session, user_id: int) -> bool:
    """
    Check if user has completed onboarding survey
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        True if profile exists, False otherwise
    """
    profile = get_user_profile(db, user_id)
    return profile is not None


def convert_profile_to_response(profile: UserProfile) -> OnboardingSurveyResponse:
    """
    Convert UserProfile SQLAlchemy model to OnboardingSurveyResponse Pydantic model
    
    Args:
        profile: UserProfile SQLAlchemy model
        
    Returns:
        OnboardingSurveyResponse Pydantic model
    """
    return OnboardingSurveyResponse(
        id=profile.ID,
        user_id=profile.USER_ID,
        nickname=profile.NICKNAME,
        age_group=profile.AGE_GROUP,
        gender=profile.GENDER,
        marital_status=profile.MARITAL_STATUS,
        children_yn=profile.CHILDREN_YN,
        living_with=profile.LIVING_WITH if profile.LIVING_WITH else [],
        personality_type=profile.PERSONALITY_TYPE,
        activity_style=profile.ACTIVITY_STYLE,
        stress_relief=profile.STRESS_RELIEF if profile.STRESS_RELIEF else [],
        hobbies=profile.HOBBIES if profile.HOBBIES else [],
        atmosphere=profile.ATMOSPHERE if profile.ATMOSPHERE else [],
        created_at=profile.CREATED_AT,
        updated_at=profile.UPDATED_AT
    )

