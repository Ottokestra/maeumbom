"""Pydantic schemas for menopause survey questions."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class MenopauseQuestionCreate(BaseModel):
    gender: str = Field(..., description="성별 (FEMALE / MALE)")
    code: str = Field(..., description="문항 코드 (F1~F10, M1~M10)")
    order_no: int = Field(..., description="성별 내 문항 표시 순서")
    question_text: str = Field(..., description="문항 텍스트")
    risk_when_yes: bool = Field(..., description="예 응답 시 위험 여부")
    positive_label: str = Field("예", description="긍정 선택지 라벨")
    negative_label: str = Field("아니오", description="부정 선택지 라벨")
    character_key: Optional[str] = Field(
        None, description="감정 캐릭터 매핑 키 (예: PEACH_WORRY)"
    )


class MenopauseQuestionUpdate(BaseModel):
    gender: Optional[str] = Field(None, description="성별 (FEMALE / MALE)")
    code: Optional[str] = Field(None, description="문항 코드 (F1~F10, M1~M10)")
    order_no: Optional[int] = Field(None, description="성별 내 문항 표시 순서")
    question_text: Optional[str] = Field(None, description="문항 텍스트")
    risk_when_yes: Optional[bool] = Field(None, description="예 응답 시 위험 여부")
    positive_label: Optional[str] = Field(None, description="긍정 선택지 라벨")
    negative_label: Optional[str] = Field(None, description="부정 선택지 라벨")
    character_key: Optional[str] = Field(
        None, description="감정 캐릭터 매핑 키 (예: PEACH_WORRY)"
    )
    is_active: Optional[bool] = Field(None, description="활성화 여부")


class MenopauseQuestionOut(BaseModel):
    id: int = Field(..., alias="ID")
    gender: str = Field(..., alias="GENDER")
    code: str = Field(..., alias="CODE")
    order_no: int = Field(..., alias="ORDER_NO")
    question_text: str = Field(..., alias="QUESTION_TEXT")
    risk_when_yes: bool = Field(..., alias="RISK_WHEN_YES")
    positive_label: str = Field(..., alias="POSITIVE_LABEL")
    negative_label: str = Field(..., alias="NEGATIVE_LABEL")
    character_key: Optional[str] = Field(None, alias="CHARACTER_KEY")
    is_active: bool = Field(..., alias="IS_ACTIVE")
    is_deleted: bool = Field(..., alias="IS_DELETED")
    created_at: Optional[datetime] = Field(None, alias="CREATED_AT")
    updated_at: Optional[datetime] = Field(None, alias="UPDATED_AT")
    created_by: Optional[str] = Field(None, alias="CREATED_BY")
    updated_by: Optional[str] = Field(None, alias="UPDATED_BY")

    class Config:
        from_attributes = True  # orm_mode is deprecated in v2
        populate_by_name = True  # allow_population_by_field_name is deprecated in v2


class MenopauseAnswerItem(BaseModel):
    question_id: int
    answer_value: int  # 0 or 3


class MenopauseSurveySubmitRequest(BaseModel):
    gender: str  # FEMALE / MALE (설문 대상 성별)
    answers: list[MenopauseAnswerItem]


class MenopauseSurveyResultResponse(BaseModel):
    id: int
    total_score: int
    risk_level: str  # LOW, MID, HIGH
    comment: str
    created_at: datetime

    class Config:
        from_attributes = True
