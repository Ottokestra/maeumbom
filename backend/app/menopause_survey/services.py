# backend/app/menopause_survey/services.py
from typing import Tuple

from sqlalchemy.orm import Session

from .models import MenopauseSurvey, MenopauseSurveyAnswer, MenopauseSurveyResult
from .schemas import (
    MenopauseSurveySubmitRequest,
    MenopauseSurveyResultResponse,
)

# 점수에 따른 기본 코멘트
RISK_COMMENTS = {
    "LOW": "현재 상태는 비교적 안정적입니다. 지금의 생활 리듬을 부드럽게 유지해 보세요.",
    "MID": "일부 영역에서 갱년기 관련 신호가 느껴집니다. 생활 습관을 점검하고 필요하면 상담을 고려해 보세요.",
    "HIGH": "여러 영역에서 강한 갱년기 신호가 감지됩니다. 전문 의료진과 상담을 권장드립니다.",
}


def _calculate_score_and_level(payload: MenopauseSurveySubmitRequest) -> Tuple[int, str, str]:
    """
    총점과 위험도 레벨, 기본 코멘트를 계산.
    - 각 문항: 위험 응답 시 3점, 아니면 0점 (총 0~30점)
    """
    total_score = sum(a.answer_value for a in payload.answers)

    if total_score <= 6:
        level = "LOW"
    elif total_score <= 18:
        level = "MID"
    else:
        level = "HIGH"

    comment = RISK_COMMENTS[level]
    return total_score, level, comment


def submit_menopause_survey_service(
    db: Session,
    user_id: int,
    payload: MenopauseSurveySubmitRequest,
) -> MenopauseSurveyResultResponse:
    """설문 저장 + 결과 리턴"""

    total_score, risk_level, comment = _calculate_score_and_level(payload)

    # 1) 설문 메인 레코드
    survey = MenopauseSurvey(
        user_id=user_id,
        gender=payload.gender,
        total_score=total_score,
        risk_level=risk_level,
    )
    db.add(survey)
    db.flush()  # survey.id 확보

    # 2) 문항별 답변
    for ans in payload.answers:
        db_answer = MenopauseSurveyAnswer(
            survey_id=survey.id,
            question_code=ans.question_code,
            question_text=ans.question_text,
            answer_value=ans.answer_value,
            answer_label=ans.answer_label,
        )
        db.add(db_answer)

    # 3) 결과 테이블
    result = MenopauseSurveyResult(
        survey_id=survey.id,
        total_score=total_score,
        risk_level=risk_level,
        comment=comment,
    )
    db.add(result)

    db.commit()
    db.refresh(result)

    return MenopauseSurveyResultResponse(
        total_score=result.total_score,
        risk_level=result.risk_level,  # LOW / MID / HIGH
        comment=result.comment,
    )
