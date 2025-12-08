"""
Pydantic models for onboarding survey request/response validation
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


class OnboardingSurveySubmitRequest(BaseModel):
    """
    Onboarding survey submission request
    
    Attributes:
        nickname: User nickname (Q1)
        age_group: Age group (Q2) - '40대', '50대', '60대', '70대 이상'
        gender: Gender (Q3) - '여성', '남성'
        marital_status: Marital status (Q4) - '미혼', '기혼', '이혼/사별', '말하고 싶지 않음'
        children_yn: Children existence (Q5) - '있음', '없음'
        living_with: Living with (Q6, multi-select) - ['혼자', '배우자와', '자녀와', '부모님과', '가족과 함께', '기타']
        personality_type: Personality type (Q7) - '내향적', '외향적', '상황에따라'
        activity_style: Activity style (Q8) - '조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'
        stress_relief: Stress relief methods (Q9, multi-select) - list of Korean text
        hobbies: Hobbies (Q10, multi-select) - list of Korean text
        atmosphere: Preferred atmosphere (Q11, multi-select, optional) - list of Korean text
    """
    nickname: str = Field(..., min_length=1, max_length=100, description="User nickname")
    age_group: str = Field(..., description="Age group (40대, 50대, 60대, 70대 이상)")
    gender: str = Field(..., description="Gender (여성, 남성)")
    marital_status: str = Field(..., description="Marital status")
    children_yn: str = Field(..., description="Children existence (있음, 없음)")
    living_with: List[str] = Field(..., min_items=1, description="Living with (multi-select)")
    personality_type: str = Field(..., description="Personality type")
    activity_style: str = Field(..., description="Activity style")
    stress_relief: List[str] = Field(..., min_items=1, description="Stress relief methods (multi-select)")
    hobbies: List[str] = Field(..., min_items=1, description="Hobbies (multi-select)")
    atmosphere: List[str] = Field(default=[], min_items=0, description="Preferred atmosphere (multi-select, optional)")
    
    class Config:
        json_schema_extra = {
            "example": {
                "nickname": "봄이",
                "age_group": "50대",
                "gender": "여성",
                "marital_status": "기혼",
                "children_yn": "있음",
                "living_with": ["배우자와", "자녀와"],
                "personality_type": "외향적",
                "activity_style": "활동적인게 좋아요",
                "stress_relief": ["산책을 해요", "누군가와 대화를 나눠요", "취미 활동을 해요"],
                "hobbies": ["산책", "음악감상", "독서"],
                "atmosphere": []
            }
        }


class OnboardingSurveyResponse(BaseModel):
    """
    Onboarding survey response
    Returns user profile data
    """
    id: int
    user_id: int
    nickname: str
    age_group: str
    gender: str
    marital_status: str
    children_yn: str
    living_with: List[str]
    personality_type: str
    activity_style: str
    stress_relief: List[str]
    hobbies: List[str]
    atmosphere: List[str]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class OnboardingSurveyStatusResponse(BaseModel):
    """
    Onboarding survey status response
    Indicates whether user has completed the survey
    """
    has_profile: bool
    profile: Optional[OnboardingSurveyResponse] = None

