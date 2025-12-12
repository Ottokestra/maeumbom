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
    # TODO: 설문조사 응답 저장/조회용 repository 함수 추가 필요
)
from .schemas import (
    MenopauseQuestionCreate, 
    MenopauseQuestionUpdate, 
    # 설문조사 제출/결과 스키마 임포트 추가
    MenopauseSurveySubmitRequest, 
    MenopauseSurveyResultResponse
)

logger = logging.getLogger(__name__)

DEFAULT_SEED_CREATED_BY = "seed-defaults"

# ... (FEMALE_CHARACTER_KEYS, MALE_CHARACTER_KEYS, DEFAULT_QUESTIONS 정의는 생략) ...

FEMALE_CHARACTER_KEYS = [
    "PEACH_WORRY", "PEACH_CALM", "PEACH_TIRED", "PEACH_HEAT", "PEACH_ANXIOUS", 
    "PEACH_PAIN", "PEACH_SHY", "PEACH_BALANCE", "PEACH_BLUE", "PEACH_EXHAUSTED",
]

MALE_CHARACTER_KEYS = [
    "FIRE_FOCUS", "FIRE_ENERGY", "FIRE_DRIVE", "FIRE_ANGRY", "FIRE_EMPTY", 
    "FIRE_FORGET", "FIRE_SLEEP", "FIRE_STRESS", "FIRE_WEIGHT", "FIRE_CONFIDENCE",
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
    if not gender:
        return None
    
    g = gender.upper().strip()
    if g in ("M", "MALE"):
        return "M"
    if g in ("F", "FEMALE"):
        return "F"
    return g


# ====================================================================
# 설문조사 제출 핵심 서비스 함수 (ImportError 해결)
# ====================================================================

async def submit_menopause_survey_service(
    db: Session,
    request_data: MenopauseSurveySubmitRequest,
    current_user_id: int,  # 사용자 인증 정보를 통해 현재 사용자 ID를 받는다고 가정
) -> MenopauseSurveyResultResponse:
    """
    설문조사 응답을 받아 DB에 저장하고, 분석을 수행하여 결과를 반환합니다.
    """
    # 1. DB에 설문조사 결과 저장 (repository 함수 필요)
    # submitted_record = save_survey_answers(db, request_data)

    # 2. 위험 점수 계산
    risk_score = sum(1 for answer in request_data.answers if answer.is_risk)
    
    # 3. 위험 레벨 및 텍스트 결정 로직 (간단한 예시)
    if risk_score >= 8:
        risk_level = "HIGH"
        result_text = "위험 점수가 높아 전문가 상담을 권장합니다."
    elif risk_score >= 4:
        risk_level = "MEDIUM"
        result_text = "주의가 필요합니다. 건강 상태를 점검해보세요."
    else:
        risk_level = "LOW"
        result_text = "현재 상태는 양호합니다."

    # 4. 결과 응답 객체 생성 및 반환
    from datetime import datetime
    
    return MenopauseSurveyResultResponse(
        user_id=current_user_id,
        survey_id=1,  # 저장된 레코드 ID로 대체 필요
        gender=request_data.gender,
        risk_score=risk_score,
        result_text=result_text,
        risk_level=risk_level,
        submitted_at=datetime.now()
    )


# ====================================================================
# 기존 질문 관리 서비스 함수들
# ====================================================================

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
    comment = (
        "현재로서는 갱년기와 관련된 변화가 크게 두드러지지 않거나 비교적 가벼운 수준으로 보여요. "
        "생활 리듬을 잘 유지하고, 충분한 휴식과 가벼운 활동으로 컨디션을 살펴보세요."
    )
elif total_score <= 20:
    risk_level = "MID"
    comment = (
        "최근 몸과 마음의 변화를 느끼고 있을 가능성이 있어요. "
        "수면, 식사, 활동 습관을 조금만 조정해도 도움이 될 수 있으며, "
        "증상이 지속되거나 불편하다면 상담을 받아보는 것도 좋은 선택이에요."
    )
else:
    risk_level = "HIGH"
    comment = (
        "현재 증상이 일상생활에 영향을 주고 있을 가능성이 높아요. "
        "혼자 참고 넘기기보다는 전문의와 상담을 통해 원인을 확인하고, "
        "본인에게 맞는 관리나 치료 방법을 찾는 것을 적극 권장드려요."
    )


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
