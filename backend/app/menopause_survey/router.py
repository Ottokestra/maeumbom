<<<<<<< HEAD
# app/menopause_survey/router.py 파일 상단

from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional

# =======================================================
# 1. DB 의존성 주입 함수 임포트 
# =======================================================
from app.dependencies import get_db

from .schemas import (
    MenopauseQuestionCreate,
    MenopauseQuestionUpdate,
    MenopauseQuestionOut,
=======
from typing import List, Optional

from fastapi import APIRouter, Depends, Query, Body
from sqlalchemy.orm import Session

from app.db.database import get_db

from .schemas import (
    MenopauseQuestionCreate,
    MenopauseQuestionOut,
    MenopauseQuestionUpdate,
>>>>>>> 10eca562ebbed6cd5936665476546b0e09b9c1ee
    MenopauseSurveySubmitRequest,
    MenopauseSurveyResultResponse,
)
from .service import (
    list_question_items,
    retrieve_question,
    create_question_item,
    update_question_item,
<<<<<<< HEAD
    delete_question_item,
    seed_default_questions,
    submit_menopause_survey_service,
)

# =======================================================
# 2. APIRouter 인스턴스 정의: prefix 중복을 해결하기 위해 접두사 제거 (수정됨)
# =======================================================
router = APIRouter(
    prefix="/api/menopause-survey", 
    tags=["Menopause Survey"],
)


# =======================================================
# 3. 라우터 엔드포인트 정의 (변경 없음)
# =======================================================

# 📌 설문 문항 목록 조회
# 최종 경로는 main.py에서 설정한 접두사 + "/questions"가 됩니다.
@router.get(
    "/questions", 
    response_model=List[MenopauseQuestionOut], 
    status_code=status.HTTP_200_OK
)
def get_menopause_questions(
    db: Session = Depends(get_db), 
    gender: Optional[str] = Query(None, description="성별 필터 (FEMALE/MALE)"),
    is_active: Optional[bool] = Query(True, description="활성화 여부 필터")
):
    """
    갱년기 설문 문항 목록을 조회합니다.
    """
    return list_question_items(db, gender=gender, is_active=is_active)


# 📌 설문조사 결과 제출
@router.post(
    "/submit",
    response_model=MenopauseSurveyResultResponse,
    status_code=status.HTTP_201_CREATED,
)
async def submit_menopause_survey(
    payload: MenopauseSurveySubmitRequest,
    # TODO: 실제 사용자 인증을 통해 current_user_id를 받아와야 합니다. (임시로 1 가정)
    # current_user_id: int = Depends(get_current_active_user_id),
    db: Session = Depends(get_db),
):
    """
    사용자의 갱년기 설문조사 응답을 제출하고 분석 결과를 반환합니다.
    """
    current_user_id = 1 # 임시 사용자 ID
    return await submit_menopause_survey_service(
        db,
        request_data=payload,
        current_user_id=current_user_id,
    )
=======
    submit_menopause_survey,
)

router = APIRouter(prefix="/api", tags=["menopause-survey"])


@router.get("/menopause/questions", response_model=List[MenopauseQuestionOut])
def list_questions(
    gender: Optional[str] = Query(None, description="FEMALE 또는 MALE"),
    is_active: Optional[bool] = Query(None, description="활성화 여부 필터"),
    db: Session = Depends(get_db),
):
    """설문 문항 목록 조회."""
    return list_question_items(db, gender=gender, is_active=is_active)


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


@router.post(
    "/menopause/questions/seed-defaults", response_model=List[MenopauseQuestionOut]
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
>>>>>>> 10eca562ebbed6cd5936665476546b0e09b9c1ee
