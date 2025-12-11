"""API routes for the mental routine survey domain."""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.db.models import User
from app.db.database import get_db

from .schemas import (
    SurveyQuestionSchema,
    SurveyResultSummary,
    SurveySubmitRequest,
)
from .service import (
    DEFAULT_SURVEY_NAME,
    get_active_questions,
    get_my_latest_result,
    submit_answers,
)

# ⚠️ 여기 prefix 에는 "/api" 붙이지 않는다.
# main.py 에서 app.include_router(..., prefix="/api") 로 한 번 더 붙임.
router = APIRouter(
    prefix="/routine-survey",
    tags=["routine-survey"],
)


@router.get("/questions", response_model=List[SurveyQuestionSchema])
async def list_questions(
    survey_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """
    활성화된 설문의 문항 리스트 조회.

    최종 URL (main.py prefix 포함):
        GET /api/routine-survey/questions
    """
    questions = get_active_questions(
        db=db,
        survey_id=survey_id,
        survey_name=DEFAULT_SURVEY_NAME,
    )

    if not questions:
        # 라우트는 존재하지만, 활성 설문이 없을 때 404
        raise HTTPException(status_code=404, detail="활성화된 설문이 없습니다.")

    return questions


@router.post("/submit", response_model=SurveyResultSummary)
async def submit_survey(
    request: SurveySubmitRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    현재 로그인한 사용자의 설문 응답 저장.

    최종 URL:
        POST /api/routine-survey/submit
    """
    return submit_answers(
        db=db,
        user_id=current_user.ID,
        survey_id=request.survey_id,
        answers=request.answers,
    )


@router.get("/results/me", response_model=SurveyResultSummary)
async def get_my_result(
    survey_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    현재 로그인한 사용자의 최신 설문 결과 조회.

    최종 URL:
        GET /api/routine-survey/results/me
    """
    summary = get_my_latest_result(
        db=db,
        user_id=current_user.ID,
        survey_id=survey_id,
    )
    if not summary:
        raise HTTPException(status_code=404, detail="설문 결과가 없습니다.")
    return summary
