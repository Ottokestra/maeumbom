"""FastAPI router for menopause survey questions."""
from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.database import get_db

from .schemas import MenopauseQuestionCreate, MenopauseQuestionOut, MenopauseQuestionUpdate
from .service import (
    create_question_item,
    delete_question_item,
    list_question_items,
    retrieve_question,
    seed_default_questions,
    update_question_item,
)

router = APIRouter(prefix="/menopause/questions", tags=["menopause-survey"])


@router.get("", response_model=List[MenopauseQuestionOut])
def list_questions(
    gender: Optional[str] = Query(None, description="FEMALE 또는 MALE"),
    is_active: Optional[bool] = Query(None, description="활성화 여부 필터"),
    db: Session = Depends(get_db),
):
    """설문 문항 목록 조회."""

    return list_question_items(db, gender=gender, is_active=is_active)


@router.get("/{question_id}", response_model=MenopauseQuestionOut)
def get_question(question_id: int, db: Session = Depends(get_db)):
    """설문 문항 단건 조회."""

    return retrieve_question(db, question_id)


@router.post("", response_model=MenopauseQuestionOut)
def create_question(payload: MenopauseQuestionCreate, db: Session = Depends(get_db)):
    """설문 문항 생성."""

    return create_question_item(db, payload)


@router.patch("/{question_id}", response_model=MenopauseQuestionOut)
def update_question(
    question_id: int, payload: MenopauseQuestionUpdate, db: Session = Depends(get_db)
):
    """설문 문항 수정."""

    return update_question_item(db, question_id, payload)


@router.delete("/{question_id}", response_model=MenopauseQuestionOut)
def delete_question(question_id: int, db: Session = Depends(get_db)):
    """설문 문항 소프트 삭제."""

    return delete_question_item(db, question_id)


@router.post("/seed-defaults", response_model=List[MenopauseQuestionOut])
def seed_default(db: Session = Depends(get_db)):
    """기본 남/녀 설문 문항 10개씩을 한번에 생성한다 (존재하지 않는 코드만 추가)."""

    return seed_default_questions(db)


# 수동 검증 가이드 (Swagger /docs 활용):
# 1) POST /api/menopause/questions/seed-defaults 호출로 기본 20문항 생성
# 2) GET /api/menopause/questions?gender=FEMALE 로 여성 문항 목록 확인
# 3) PATCH /api/menopause/questions/{id} 로 문항 텍스트/순서/캐릭터 변경
# 4) DELETE /api/menopause/questions/{id} 로 소프트 삭제 확인 후, 목록에서 제외됨을 확인