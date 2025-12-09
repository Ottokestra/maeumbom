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
