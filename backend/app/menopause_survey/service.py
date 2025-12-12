"""Service layer for menopause survey question management."""

from typing import List, Optional
import logging

from fastapi import HTTPException
from sqlalchemy.orm import Session

from .repository import (
    create_question,
    get_by_code,
    get_question,
    list_questions,
    seed_questions,
    soft_delete_question,
    update_question,
)
from .schemas import MenopauseQuestionCreate, MenopauseQuestionUpdate

logger = logging.getLogger(__name__)

DEFAULT_SEED_CREATED_BY = "seed-defaults"

# TODO: 캐릭터 매핑 테이블 연동 예정 - 현재는 임시 키를 사용
FEMALE_CHARACTER_KEYS = [
    "PEACH_WORRY",
    "PEACH_CALM",
    "PEACH_TIRED",
    "PEACH_HEAT",
    "PEACH_ANXIOUS",
    "PEACH_PAIN",
    "PEACH_SHY",
    "PEACH_BALANCE",
    "PEACH_BLUE",
    "PEACH_EXHAUSTED",
]

MALE_CHARACTER_KEYS = [
    "FIRE_FOCUS",
    "FIRE_ENERGY",
    "FIRE_DRIVE",
    "FIRE_ANGRY",
    "FIRE_EMPTY",
    "FIRE_FORGET",
    "FIRE_SLEEP",
    "FIRE_STRESS",
    "FIRE_WEIGHT",
    "FIRE_CONFIDENCE",
]


FEMALE_DEFAULT_QUESTIONS = [
    {
        "gender": "FEMALE",
        "code": f"F{idx}",
        "order_no": idx,
        "question_text": text,
        "risk_when_yes": True,
        "positive_label": "예",
        "negative_label": "아니오",
        "character_key": FEMALE_CHARACTER_KEYS[idx - 1],
    }
    for idx, text in enumerate(
        [
            "일의 집중력이나 기억력이 예전 같지 않다고 느낀다.",
            "아무 이유 없이 짜증이 늘고 감정 기복이 심해졌다.",
            "잠을 잘 이루지 못하거나 수면에 문제가 있다.",
            "얼굴이 달아오르거나 갑작스러운 열감(홍조)을 자주 느낀다.",
            "가슴 두근거림, 식은땀, 이유 없는 불안감을 느끼는 편이다.",
            "관절통, 근육통 등 몸 여기저기가 자주 쑤시거나 아프다.",
            "성욕이 감소했거나 성관계가 예전보다 불편하게 느껴진다.",
            "체중 증가나 체형 변화(뱃살 증가 등)가 눈에 띈다.",
            "예전보다 우울하고 의욕이 떨어진 느낌이 자주 든다.",
            "일상생활이 버겁게 느껴지고 작은 일에도 쉽게 지친다.",
        ],
        start=1,
    )
]

MALE_DEFAULT_QUESTIONS = [
    {
        "gender": "MALE",
        "code": f"M{idx}",
        "order_no": idx,
        "question_text": text,
        "risk_when_yes": True,
        "positive_label": "예",
        "negative_label": "아니오",
        "character_key": MALE_CHARACTER_KEYS[idx - 1],
    }
    for idx, text in enumerate(
        [
            "예전보다 쉽게 피로해지고 회복이 더딘 편이다.",
            "근력이나 체력이 눈에 띄게 떨어졌다고 느낀다.",
            "성욕이나 성 기능이 예전보다 감소했다.",
            "짜증이나 분노가 늘고 사소한 일에도 예민해진다.",
            "웬일인지 의욕이 없고 무기력한 기분이 자주 든다.",
            "집중력 저하나 건망증이 심해진 것 같다.",
            "밤에 자주 깨거나 깊은 잠을 자기 어렵다.",
            "심장 두근거림, 식은땀, 발열 같은 증상을 경험한다.",
            "복부 비만, 체중 증가 등 체형 변화가 눈에 띄게 느껴진다.",
            "삶에 대한 자신감이나 의욕이 예전보다 줄었다.",
        ],
        start=1,
    )
]


DEFAULT_SEED_DATA = FEMALE_DEFAULT_QUESTIONS + MALE_DEFAULT_QUESTIONS


def _normalize_gender(gender: Optional[str]) -> Optional[str]:
    return gender.upper() if gender else None


def list_question_items(
    db: Session, *, gender: Optional[str] = None, is_active: Optional[bool] = True
):
    normalized_gender = _normalize_gender(gender)
    questions = list_questions(db, gender=normalized_gender, is_active=is_active)

    if not questions:
        logger.warning(
            "[MenopauseSurvey] No questions found for gender=%s",
            normalized_gender or "ALL",
        )

    return questions


def retrieve_question(db: Session, question_id: int):
    question = get_question(db, question_id)
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")
    return question


def create_question_item(db: Session, payload: MenopauseQuestionCreate):
    gender = payload.gender.value
    code = payload.code.upper()

    if get_by_code(db, code):
        raise HTTPException(status_code=400, detail="이미 존재하는 문항 코드입니다.")

    return create_question(
        db,
        gender=gender,
        code=code,
        order_no=payload.order_no,
        question_text=payload.question_text,
        risk_when_yes=payload.risk_when_yes,
        positive_label=payload.positive_label,
        negative_label=payload.negative_label,
        character_key=payload.character_key,
        created_by="api",
    )


def update_question_item(
    db: Session, question_id: int, payload: MenopauseQuestionUpdate
):
    question = retrieve_question(db, question_id)

    new_code = payload.code.upper() if payload.code else None
    if new_code and new_code != question.CODE and get_by_code(db, new_code):
        raise HTTPException(status_code=400, detail="이미 존재하는 문항 코드입니다.")

    return update_question(
        db,
        question,
        gender=_normalize_gender(payload.gender.value if payload.gender else None),
        code=new_code,
        order_no=payload.order_no,
        question_text=payload.question_text,
        risk_when_yes=payload.risk_when_yes,
        positive_label=payload.positive_label,
        negative_label=payload.negative_label,
        character_key=payload.character_key,
        is_active=payload.is_active,
        updated_by="api",
    )


def delete_question_item(db: Session, question_id: int):
    question = retrieve_question(db, question_id)
    return soft_delete_question(db, question, updated_by="api")


def seed_default_questions(db: Session) -> dict:
    created, skipped_count = seed_questions(
        db, DEFAULT_SEED_DATA, created_by=DEFAULT_SEED_CREATED_BY
    )
    return {
        "created_count": len(created),
        "skipped_count": skipped_count,
    }


from datetime import datetime

from app.db.models import MenopauseSurveyResult, MenopauseSurveyAnswer
from .schemas import MenopauseSurveySubmitRequest, MenopauseSurveyResultResponse


def submit_menopause_survey(
    db: Session, payload: MenopauseSurveySubmitRequest
) -> MenopauseSurveyResultResponse:
    # 1. Calculate Score
    total_score = 0
    for ans in payload.answers:
        total_score += ans.answer_value

    # 2. Risk Level (Simple logic: <10 LOW, 10-20 MID, >20 HIGH)
    if total_score < 10:
        risk_level = "LOW"
        comment = "증상이 경미합니다. 규칙적인 생활을 유지하세요."
    elif total_score <= 20:
        risk_level = "MID"
        comment = "증상이 느껴집니다. 생활 습관 개선과 상담이 도움이 될 수 있습니다."
    else:
        risk_level = "HIGH"
        comment = "증상이 심합니다. 전문의와의 상담을 적극 권장합니다."

    # 3. Save
    result = MenopauseSurveyResult(
        GENDER=payload.gender.value,
        TOTAL_SCORE=total_score,
        RISK_LEVEL=risk_level,
        COMMENT=comment,
        CREATED_AT=datetime.utcnow(),
        UPDATED_AT=datetime.utcnow(),
    )
    db.add(result)
    db.flush()

    for ans in payload.answers:
        db.add(
            MenopauseSurveyAnswer(
                RESULT_ID=result.ID,
                QUESTION_ID=ans.question_id,
                ANSWER_VALUE=ans.answer_value,
            )
        )

    db.commit()
    db.refresh(result)

    # Return schema compatible dict/object
    return MenopauseSurveyResultResponse(
        id=result.ID,
        total_score=result.TOTAL_SCORE,
        risk_level=result.RISK_LEVEL,
        comment=result.COMMENT,
        created_at=result.CREATED_AT,
    )
