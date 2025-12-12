from typing import List, Optional

from fastapi import APIRouter, Depends, Query, Body
from sqlalchemy.orm import Session

from app.db.database import get_db

from .schemas import (
    MenopauseQuestionCreate,
    MenopauseQuestionOut,
    MenopauseQuestionUpdate,
    MenopauseSurveySubmitRequest,
    MenopauseSurveyResultResponse,
)
from .service import (
    list_question_items,
    retrieve_question,
    create_question_item,
    update_question_item,
    submit_menopause_survey,
)

router = APIRouter(prefix="/api", tags=["menopause-survey"])


@router.get("/menopause-survey/questions", response_model=List[MenopauseQuestionOut])
def list_questions(
    gender: Optional[str] = Query(None, description="FEMALE 또는 MALE"),
    is_active: Optional[bool] = Query(None, description="활성화 여부 필터"),
    db: Session = Depends(get_db),
):
    """설문 문항 목록 조회."""
    return list_question_items(db, gender=gender, is_active=is_active)


@router.get("/menopause-survey/questions/{question_id}", response_model=MenopauseQuestionOut)
def get_question(question_id: int, db: Session = Depends(get_db)):
    """설문 문항 단건 조회."""
    return retrieve_question(db, question_id)


@router.post("/menopause-survey/questions", response_model=MenopauseQuestionOut)
def create_question(payload: MenopauseQuestionCreate, db: Session = Depends(get_db)):
    """설문 문항 생성."""
    return create_question_item(db, payload)


@router.patch("/menopause-survey/questions/{question_id}", response_model=MenopauseQuestionOut)
def update_question(
    question_id: int, payload: MenopauseQuestionUpdate, db: Session = Depends(get_db)
):
    """설문 문항 수정."""
    return update_question_item(db, question_id, payload)


@router.delete(
    "/menopause-survey/questions/{question_id}", response_model=MenopauseQuestionOut
)
def delete_question(question_id: int, db: Session = Depends(get_db)):
    """설문 문항 소프트 삭제."""
    return delete_question_item(db, question_id)


@router.post(
    "/menopause-survey/questions/seed-defaults", response_model=List[MenopauseQuestionOut]
)
def seed_default(db: Session = Depends(get_db)):
    """기본 남/녀 설문 문항 10개씩을 한번에 생성한다 (존재하지 않는 코드만 추가)."""
    return seed_default_questions(db)


@router.post("/menopause-survey/submit", response_model=MenopauseSurveyResultResponse)
def submit_menopause(
    payload: MenopauseSurveySubmitRequest, db: Session = Depends(get_db)
):
    """갱년기 설문 답변 제출 및 결과 계산 (MVP: 인증 불필요)"""
    return submit_menopause_survey(db, payload)
