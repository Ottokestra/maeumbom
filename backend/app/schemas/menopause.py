"""Pydantic schemas for menopause self-test survey."""
from __future__ import annotations

from typing import List, Literal, Optional

from pydantic import BaseModel


class MenopauseQuestionBase(BaseModel):
    orderNo: int
    category: Optional[str] = None
    questionText: str
    positiveLabel: Optional[str] = "예"
    negativeLabel: Optional[str] = "아니오"
    characterKey: Optional[str] = None


class MenopauseQuestionCreate(MenopauseQuestionBase):
    pass


class MenopauseQuestionUpdate(BaseModel):
    orderNo: Optional[int] = None
    category: Optional[str] = None
    questionText: Optional[str] = None
    positiveLabel: Optional[str] = None
    negativeLabel: Optional[str] = None
    characterKey: Optional[str] = None
    isActive: Optional[bool] = None


class MenopauseQuestionOut(MenopauseQuestionBase):
    id: int
    isActive: bool

    class Config:
        orm_mode = True


class MenopauseAnswerItem(BaseModel):
    questionId: int
    answer: Literal["YES", "NO"]


class MenopauseAnswerRequest(BaseModel):
    answers: List[MenopauseAnswerItem]
