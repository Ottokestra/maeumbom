"""API routes for the mental routine survey domain."""
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.models import User
from app.db.database import get_db

from .schemas import SurveyQuestionSchema, SurveyResultSummary, SurveySubmitRequest
from .services import (
    DEFAULT_SURVEY_NAME,
    get_active_questions,
    get_my_latest_result,
    submit_answers,
)

router = APIRouter(prefix="/routine-survey", tags=["routine-survey"])


@router.get("/questions", response_model=List[SurveyQuestionSchema])
async def list_questions(
    survey_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """Return active questions for the routine survey."""
    questions = get_active_questions(
        db=db,
        survey_id=survey_id,
        survey_name=DEFAULT_SURVEY_NAME,
    )

    if not questions:
        raise HTTPException(status_code=404, detail="활성화된 설문이 없습니다.")

    return questions


@router.post("/submit", response_model=SurveyResultSummary)
async def submit_survey(
    request: SurveySubmitRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Submit survey answers for the current user."""
    return submit_answers(
        db=db,
        user_id=current_user.id,
        survey_id=request.survey_id,
        answers=request.answers,
    )


@router.get("/results/me", response_model=SurveyResultSummary)
async def get_my_result(
    survey_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return the latest survey result of the current user."""
    summary = get_my_latest_result(db=db, user_id=current_user.id, survey_id=survey_id)
    if not summary:
        raise HTTPException(status_code=404, detail="설문 결과가 없습니다.")
    return summary


# Manual test hints (after running the server):
# 1) GET  /api/routine-survey/questions
# 2) POST /api/routine-survey/submit    (body: {"survey_id": 1, "answers": [{"question_id": 1, "answer_value": "Y"}, ...]})
# 3) GET  /api/routine-survey/results/me
