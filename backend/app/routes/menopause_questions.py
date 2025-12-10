"""Menopause self-test question and answer APIs."""
from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth.dependencies import get_optional_user
from app.auth.models import User
from app.db.database import get_db
from app.db.models import MenopauseAnswer, MenopauseQuestion
from app.schemas.menopause import (
    MenopauseAnswerRequest,
    MenopauseQuestionCreate,
    MenopauseQuestionOut,
    MenopauseQuestionUpdate,
)

router = APIRouter(prefix="/api/menopause", tags=["menopause"])


@router.get("/questions", response_model=List[MenopauseQuestionOut])
def list_questions(db: Session = Depends(get_db)):
    """모든 활성 설문 문항 조회."""

    return (
        db.query(MenopauseQuestion)
        .filter(MenopauseQuestion.IS_DELETED == False)
        .order_by(MenopauseQuestion.ORDER_NO.asc())
        .all()
    )


@router.post("/questions", response_model=MenopauseQuestionOut)
def create_question(payload: MenopauseQuestionCreate, db: Session = Depends(get_db)):
    """새 설문 문항 생성."""

    question = MenopauseQuestion(
        ORDER_NO=payload.orderNo,
        CATEGORY=payload.category,
        QUESTION_TEXT=payload.questionText,
        POSITIVE_LABEL=payload.positiveLabel or "예",
        NEGATIVE_LABEL=payload.negativeLabel or "아니오",
        CHARACTER_KEY=payload.characterKey,
    )

    db.add(question)
    db.commit()
    db.refresh(question)
    return question


@router.patch("/questions/{question_id}", response_model=MenopauseQuestionOut)
def update_question(question_id: int, payload: MenopauseQuestionUpdate, db: Session = Depends(get_db)):
    """설문 문항 수정."""

    question = (
        db.query(MenopauseQuestion)
        .filter(MenopauseQuestion.ID == question_id, MenopauseQuestion.IS_DELETED == False)
        .first()
    )

    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    if payload.orderNo is not None:
        question.ORDER_NO = payload.orderNo
    if payload.category is not None:
        question.CATEGORY = payload.category
    if payload.questionText is not None:
        question.QUESTION_TEXT = payload.questionText
    if payload.positiveLabel is not None:
        question.POSITIVE_LABEL = payload.positiveLabel
    if payload.negativeLabel is not None:
        question.NEGATIVE_LABEL = payload.negativeLabel
    if payload.characterKey is not None:
        question.CHARACTER_KEY = payload.characterKey
    if payload.isActive is not None:
        question.IS_ACTIVE = payload.isActive

    db.commit()
    db.refresh(question)
    return question


@router.delete("/questions/{question_id}")
def delete_question(question_id: int, db: Session = Depends(get_db)):
    """설문 문항 소프트 삭제."""

    question = (
        db.query(MenopauseQuestion)
        .filter(MenopauseQuestion.ID == question_id, MenopauseQuestion.IS_DELETED == False)
        .first()
    )

    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    question.IS_DELETED = True
    db.commit()
    return {"ok": True}


@router.post("/answers")
def submit_answers(
    payload: MenopauseAnswerRequest,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_user),
):
    """설문 응답 저장."""

    user_id = current_user.ID if current_user else None
    answer_items = payload.answers or []

    if not answer_items:
        return {"ok": True}

    question_ids = [item.questionId for item in answer_items]
    existing_questions = {
        q.ID
        for q in db.query(MenopauseQuestion)
        .filter(MenopauseQuestion.ID.in_(question_ids))
        .filter(MenopauseQuestion.IS_DELETED == False)
        .all()
    }

    missing_ids = set(question_ids) - existing_questions
    if missing_ids:
        raise HTTPException(status_code=404, detail=f"Questions not found: {sorted(missing_ids)}")

    answers = [
        MenopauseAnswer(
            USER_ID=user_id,
            QUESTION_ID=item.questionId,
            ANSWER_VALUE=item.answer,
        )
        for item in answer_items
    ]

    db.add_all(answers)
    db.commit()

    return {"ok": True}
