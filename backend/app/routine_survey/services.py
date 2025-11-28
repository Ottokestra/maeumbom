"""Service layer for the mental routine survey domain."""
from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from .models import (
    MentalRoutineSurvey,
    MentalRoutineSurveyAnswer,
    MentalRoutineSurveyQuestion,
    MentalRoutineSurveyResult,
)
from .schemas import SurveyResultSummary, SurveySubmitItem

DEFAULT_SURVEY_NAME = "심리상태·루틴 체크 설문"


RISK_COMMENTS = {
    "LOW": "현재 상태는 안정적입니다. 가벼운 루틴을 유지해보세요.",
    "MID": "일부 항목에서 주의가 필요합니다. 휴식과 상담을 고려해보세요.",
    "HIGH": "다수 항목에서 위험 신호가 감지되었습니다. 전문가 상담을 권장합니다.",
}


def get_active_questions(
    db: Session, survey_name: Optional[str] = None, survey_id: Optional[int] = None
) -> List[MentalRoutineSurveyQuestion]:
    """Return active questions for the given survey."""
    survey_query = db.query(MentalRoutineSurvey).filter(MentalRoutineSurvey.active_yn == "Y")

    if survey_id:
        survey_query = survey_query.filter(MentalRoutineSurvey.survey_id == survey_id)
    elif survey_name:
        survey_query = survey_query.filter(MentalRoutineSurvey.name == survey_name)

    survey = survey_query.first()
    if not survey:
        return []

    return (
        db.query(MentalRoutineSurveyQuestion)
        .filter(
            MentalRoutineSurveyQuestion.survey_id == survey.survey_id,
            MentalRoutineSurveyQuestion.active_yn == "Y",
        )
        .order_by(MentalRoutineSurveyQuestion.question_no.asc())
        .all()
    )


def _calculate_risk(total_score: int) -> str:
    if total_score < 3:
        return "LOW"
    if 3 <= total_score < 6:
        return "MID"
    return "HIGH"


def submit_answers(
    db: Session,
    user_id: int,
    survey_id: int,
    answers: List[SurveySubmitItem],
) -> SurveyResultSummary:
    """Persist survey answers and return the result summary."""
    survey = (
        db.query(MentalRoutineSurvey)
        .filter(
            MentalRoutineSurvey.survey_id == survey_id,
            MentalRoutineSurvey.active_yn == "Y",
        )
        .first()
    )
    if not survey:
        raise HTTPException(status_code=404, detail="해당 설문을 찾을 수 없습니다.")

    questions = get_active_questions(db, survey_id=survey_id)
    question_map = {q.question_id: q for q in questions}

    if not question_map:
        raise HTTPException(status_code=400, detail="활성화된 설문 문항이 없습니다.")

    result = MentalRoutineSurveyResult(
        survey_id=survey_id,
        user_id=user_id,
        taken_at=datetime.utcnow(),
        total_score=0,
        risk_level="LOW",
    )
    db.add(result)
    db.flush()

    total_score = 0
    for answer in answers:
        question = question_map.get(answer.question_id)
        if not question:
            raise HTTPException(status_code=400, detail=f"유효하지 않은 문항 ID: {answer.question_id}")

        answer_value = (answer.answer_value or "N").upper()
        score = question.score if answer_value == "Y" else 0
        total_score += score

        db.add(
            MentalRoutineSurveyAnswer(
                result_id=result.result_id,
                question_id=question.question_id,
                answer_value=answer_value,
                score=score,
            )
        )

    risk_level = _calculate_risk(total_score)
    comment = RISK_COMMENTS.get(risk_level, "")

    result.total_score = total_score
    result.risk_level = risk_level
    result.comment = comment
    result.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(result)

    return SurveyResultSummary(
        survey_id=result.survey_id,
        result_id=result.result_id,
        total_score=result.total_score,
        risk_level=result.risk_level,
        comment=result.comment,
        taken_at=result.taken_at,
    )


def get_my_latest_result(
    db: Session, user_id: int, survey_id: Optional[int] = None
) -> Optional[SurveyResultSummary]:
    query = db.query(MentalRoutineSurveyResult).filter(
        MentalRoutineSurveyResult.user_id == user_id
    )

    if survey_id:
        query = query.filter(MentalRoutineSurveyResult.survey_id == survey_id)

    result = query.order_by(MentalRoutineSurveyResult.taken_at.desc()).first()
    if not result:
        return None

    return SurveyResultSummary.from_orm(result)
