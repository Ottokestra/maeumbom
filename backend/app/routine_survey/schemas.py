"""Pydantic schemas for the mental routine survey domain."""
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class SurveyQuestionSchema(BaseModel):
    question_id: int = Field(..., description="설문 문항 ID")
    survey_id: int = Field(..., description="설문 ID")
    question_no: int = Field(..., description="문항 번호")
    title: str = Field(..., description="문항 제목")
    description: Optional[str] = Field(None, description="문항 설명")
    score: int = Field(..., description="문항 점수")

    class Config:
        orm_mode = True


class SurveySubmitItem(BaseModel):
    question_id: int
    answer_value: str = Field(..., description="'Y' 또는 'N'")


class SurveySubmitRequest(BaseModel):
    survey_id: int
    answers: List[SurveySubmitItem]


class SurveyResultSummary(BaseModel):
    survey_id: int
    result_id: int
    total_score: int
    risk_level: str
    comment: Optional[str]
    taken_at: datetime

    class Config:
        orm_mode = True
