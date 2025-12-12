"""Repository layer for menopause survey questions."""

from typing import Iterable, List, Optional

from sqlalchemy.orm import Session

from app.db.models import MenopauseSurveyQuestion


def list_questions(
    db: Session, gender: Optional[str] = None, is_active: Optional[bool] = True
) -> List[MenopauseSurveyQuestion]:
    query = db.query(MenopauseSurveyQuestion).filter(
        MenopauseSurveyQuestion.IS_DELETED == False
    )

    if gender:
        query = query.filter(MenopauseSurveyQuestion.GENDER == gender)
    if is_active is not None:
        query = query.filter(MenopauseSurveyQuestion.IS_ACTIVE == is_active)

    return query.order_by(
        MenopauseSurveyQuestion.GENDER.asc(), MenopauseSurveyQuestion.ORDER_NO.asc()
    ).all()


def get_question(db: Session, question_id: int) -> Optional[MenopauseSurveyQuestion]:
    return (
        db.query(MenopauseSurveyQuestion)
        .filter(
            MenopauseSurveyQuestion.ID == question_id,
            MenopauseSurveyQuestion.IS_DELETED == False,
        )
        .first()
    )


def get_by_code(db: Session, code: str) -> Optional[MenopauseSurveyQuestion]:
    return (
        db.query(MenopauseSurveyQuestion)
        .filter(
            MenopauseSurveyQuestion.CODE == code,
            MenopauseSurveyQuestion.IS_DELETED == False,
        )
        .first()
    )


def create_question(
    db: Session,
    *,
    gender: str,
    code: str,
    order_no: int,
    question_text: str,
    risk_when_yes: bool,
    positive_label: str,
    negative_label: str,
    character_key: Optional[str],
    created_by: Optional[str] = None,
) -> MenopauseSurveyQuestion:
    question = MenopauseSurveyQuestion(
        GENDER=gender,
        CODE=code,
        ORDER_NO=order_no,
        QUESTION_TEXT=question_text,
        RISK_WHEN_YES=risk_when_yes,
        POSITIVE_LABEL=positive_label,
        NEGATIVE_LABEL=negative_label,
        CHARACTER_KEY=character_key,
        CREATED_BY=created_by,
        UPDATED_BY=created_by,
    )
    db.add(question)
    db.commit()
    db.refresh(question)
    return question


def update_question(
    db: Session,
    question: MenopauseSurveyQuestion,
    *,
    gender: Optional[str] = None,
    code: Optional[str] = None,
    order_no: Optional[int] = None,
    question_text: Optional[str] = None,
    risk_when_yes: Optional[bool] = None,
    positive_label: Optional[str] = None,
    negative_label: Optional[str] = None,
    character_key: Optional[str] = None,
    is_active: Optional[bool] = None,
    updated_by: Optional[str] = None,
) -> MenopauseSurveyQuestion:
    if gender is not None:
        question.GENDER = gender
    if code is not None:
        question.CODE = code
    if order_no is not None:
        question.ORDER_NO = order_no
    if question_text is not None:
        question.QUESTION_TEXT = question_text
    if risk_when_yes is not None:
        question.RISK_WHEN_YES = risk_when_yes
    if positive_label is not None:
        question.POSITIVE_LABEL = positive_label
    if negative_label is not None:
        question.NEGATIVE_LABEL = negative_label
    if character_key is not None:
        question.CHARACTER_KEY = character_key
    if is_active is not None:
        question.IS_ACTIVE = is_active
    if updated_by is not None:
        question.UPDATED_BY = updated_by

    db.commit()
    db.refresh(question)
    return question


def soft_delete_question(
    db: Session, question: MenopauseSurveyQuestion, *, updated_by: Optional[str] = None
) -> MenopauseSurveyQuestion:
    question.IS_DELETED = True
    if updated_by is not None:
        question.UPDATED_BY = updated_by
    db.commit()
    db.refresh(question)
    return question


def seed_questions(
    db: Session, defaults: Iterable[dict], created_by: str = "seed-defaults"
) -> tuple[List[MenopauseSurveyQuestion], int]:
    codes = {item["code"] for item in defaults}
    genders = {item["gender"] for item in defaults}
    existing_pairs = {
        (q.CODE, q.GENDER)
        for q in db.query(MenopauseSurveyQuestion)
        .filter(MenopauseSurveyQuestion.CODE.in_(codes))
        .filter(MenopauseSurveyQuestion.GENDER.in_(genders))
        .filter(MenopauseSurveyQuestion.IS_DELETED == False)
        .all()
    }

    created_items: List[MenopauseSurveyQuestion] = []
    skipped_count = 0
    for item in defaults:
        code_gender_pair = (item["code"], item["gender"])
        if code_gender_pair in existing_pairs:
            skipped_count += 1
            continue

        question = MenopauseSurveyQuestion(
            GENDER=item["gender"],
            CODE=item["code"],
            ORDER_NO=item["order_no"],
            QUESTION_TEXT=item["question_text"],
            RISK_WHEN_YES=item.get("risk_when_yes", False),
            POSITIVE_LABEL=item.get("positive_label", "예"),
            NEGATIVE_LABEL=item.get("negative_label", "아니오"),
            CHARACTER_KEY=item.get("character_key"),
            CREATED_BY=created_by,
            UPDATED_BY=created_by,
        )
        db.add(question)
        created_items.append(question)

    if created_items:
        db.commit()
        for question in created_items:
            db.refresh(question)

    return created_items, skipped_count
