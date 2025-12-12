"""Pydantic schemas for menopause survey questions."""

from datetime import datetime
from typing import Optional, List
from enum import Enum

from pydantic import BaseModel, Field


# ====================================================================
# 설문조사 응답 제출을 위한 스키마
# ====================================================================

class MenopauseSurveyAnswer(BaseModel):
    """개별 질문에 대한 응답 스키마"""
    question_code: str = Field(..., description="응답한 문항 코드 (F1~F10, M1~M10)")
    answer_text: str = Field(..., description="사용자의 응답 (예: '예' 또는 '아니오')")
    is_risk: bool = Field(..., description="이 응답이 위험(이상) 상태를 나타내는지 여부")


class MenopauseSurveySubmitRequest(BaseModel):
    """설문조사 제출 요청 전체 스키마"""
    user_id: int = Field(..., description="설문조사를 제출하는 사용자 ID")
    gender: str = Field(..., description="설문조사가 진행된 성별 (FEMALE / MALE)")
    answers: List[MenopauseSurveyAnswer] = Field(..., description="개별 문항 응답 리스트")


# ====================================================================
# 설문조사 결과 응답 스키마 (새로 추가)
# ====================================================================

class MenopauseSurveyResultResponse(BaseModel):
    """설문조사 결과 반환을 위한 응답 스키마"""
    user_id: int = Field(..., description="결과를 받은 사용자 ID")
    survey_id: int = Field(..., description="제출된 설문조사 레코드 ID")
    gender: str = Field(..., description="설문조사 기준 성별")
    risk_score: int = Field(..., description="총 위험 점수 (예: 위험 응답 개수)")
    result_text: str = Field(..., description="결과에 따른 분석 텍스트")
    risk_level: str = Field(..., description="위험도 레벨 (예: LOW, MEDIUM, HIGH)")
    submitted_at: datetime = Field(..., description="설문조사 제출 시간")
    # 상세 응답 내역이 필요하다면 아래 필드 주석을 해제하세요.
    # answers: List[MenopauseSurveyAnswer] = Field(..., description="제출된 상세 응답 내역")


# ====================================================================
# 기존 질문 관리 스키마 (MenopauseQuestion)
# ====================================================================

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
    id: int = Field(..., validation_alias="ID")
    gender: str = Field(..., validation_alias="GENDER")
    code: str = Field(..., validation_alias="CODE")
    order_no: int = Field(..., validation_alias="ORDER_NO")
    question_text: str = Field(..., validation_alias="QUESTION_TEXT")
    risk_when_yes: bool = Field(..., validation_alias="RISK_WHEN_YES")
    positive_label: str = Field(..., validation_alias="POSITIVE_LABEL")
    negative_label: str = Field(..., validation_alias="NEGATIVE_LABEL")
    character_key: Optional[str] = Field(None, validation_alias="CHARACTER_KEY")
    is_active: Optional[bool] = Field(False, validation_alias="IS_ACTIVE")
    is_deleted: Optional[bool] = Field(False, validation_alias="IS_DELETED")
    created_at: Optional[datetime] = Field(None, validation_alias="CREATED_AT")
    updated_at: Optional[datetime] = Field(None, validation_alias="UPDATED_AT")
    created_by: Optional[str] = Field(None, validation_alias="CREATED_BY")
    updated_by: Optional[str] = Field(None, validation_alias="UPDATED_BY")

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
