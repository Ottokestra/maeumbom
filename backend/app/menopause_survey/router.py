from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.database import get_db

from .schemas import (
    Gender,
    MenopauseQuestionCreate,
    MenopauseQuestionOut,
    MenopauseQuestionUpdate,
    MenopauseSeedResponse,
    MenopauseSurveySubmitRequest,
    MenopauseSurveyResultResponse,
)
from .service import (
    create_question_item,
    delete_question_item,
    list_question_items,
    retrieve_question,
    seed_default_questions,
    update_question_item,
    submit_menopause_survey,
)

router = APIRouter(prefix="/api", tags=["menopause-survey"])


@router.get("/menopause/questions", response_model=List[MenopauseQuestionOut])
def list_questions(
    gender: Gender = Query(
        ...,
        description="FEMALE 또는 MALE (필수)",
    ),
    is_active: bool = Query(True, description="활성화된 문항만 조회"),
    db: Session = Depends(get_db),
):
    """설문 문항 목록 조회."""
    return list_question_items(db, gender=gender.value, is_active=is_active)


@router.get("/menopause/questions/{question_id}", response_model=MenopauseQuestionOut)
def get_question(question_id: int, db: Session = Depends(get_db)):
    """설문 문항 단건 조회."""
    return retrieve_question(db, question_id)


@router.post("/menopause/questions", response_model=MenopauseQuestionOut)
def create_question(payload: MenopauseQuestionCreate, db: Session = Depends(get_db)):
    """설문 문항 생성."""
    return create_question_item(db, payload)


@router.patch("/menopause/questions/{question_id}", response_model=MenopauseQuestionOut)
def update_question(
    question_id: int, payload: MenopauseQuestionUpdate, db: Session = Depends(get_db)
):
    """설문 문항 수정."""
    return update_question_item(db, question_id, payload)


@router.delete(
    "/menopause/questions/{question_id}", response_model=MenopauseQuestionOut
)
def delete_question(question_id: int, db: Session = Depends(get_db)):
    """설문 문항 소프트 삭제."""
    return delete_question_item(db, question_id)


@router.post("/menopause/questions/seed-defaults", response_model=MenopauseSeedResponse)
def seed_default(db: Session = Depends(get_db)):
    """기본 남/녀 설문 문항 10개씩을 한번에 생성한다 (존재하지 않는 코드만 추가)."""
    return seed_default_questions(db)


@router.post("/menopause-survey/submit", response_model=MenopauseSurveyResultResponse)
def submit_menopause(
    payload: MenopauseSurveySubmitRequest, db: Session = Depends(get_db)
):
    """갱년기 설문 답변 제출 및 결과 계산 (MVP: 인증 불필요)"""
    return submit_menopause_survey(db, payload)
