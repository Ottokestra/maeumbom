<<<<<<< HEAD
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
        orm_mode = True
        allow_population_by_field_name = True
=======
from typing import List, Literal
from pydantic import BaseModel, Field


GenderType = Literal["FEMALE", "MALE"]
RiskLevelType = Literal["LOW", "MID", "HIGH"]


class MenopauseSurveyAnswerItem(BaseModel):
    question_code: str = Field(..., description="문항 코드 (예: F1, M3 등)")
    question_text: str = Field(..., description="질문 내용")
    answer_value: int = Field(..., ge=0, le=3, description="점수 (위험 응답 3점, 나머지 0점)")
    answer_label: str = Field(..., description="사용자에게 보여주는 답변 라벨 (맞다 / 아니다)")


class MenopauseSurveySubmitRequest(BaseModel):
    gender: GenderType
    answers: List[MenopauseSurveyAnswerItem]


# 🔥 router.py 에서 사용하는 이름과 맞추기 위한 alias
class MenopauseSurveySubmit(MenopauseSurveySubmitRequest):
  """기존 코드 호환용 alias (라우터에서 이 이름을 사용 중)"""
  pass


class MenopauseSurveyResultResponse(BaseModel):
    total_score: int
    risk_level: RiskLevelType
    comment: str


class MenopauseSurveyResultOut(BaseModel):
    id: int                     # DB에 저장된 설문 결과 PK
    total_score: int            # 총점
    risk_level: Literal["LOW", "MID", "HIGH"]  # 위험도 레벨
    comment: str                # 요약 코멘트

    class Config:
        orm_mode = True         # SQLAlchemy 모델에서 바로 변환 가능하도록
>>>>>>> dev
