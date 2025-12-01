"""SQLAlchemy models for the mental routine survey domain + seed 함수"""

from sqlalchemy import Column, BigInteger, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship, Session

# ✅ 기존 방식 그대로 절대 경로 import
from app.db.database import Base


class MentalRoutineSurvey(Base):
    __tablename__ = "TB_MR_SURVEY"

    survey_id = Column("SURVEY_ID", BigInteger, primary_key=True, autoincrement=True)
    name = Column("NAME", String(100), nullable=False)
    description = Column("DESCRIPTION", String(500), nullable=True)
    active_yn = Column("ACTIVE_YN", String(1), nullable=False, default="Y")
    created_at = Column("CREATED_AT", DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        "UPDATED_AT", DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    questions = relationship(
        "MentalRoutineSurveyQuestion", back_populates="survey", cascade="all, delete-orphan"
    )
    results = relationship(
        "MentalRoutineSurveyResult", back_populates="survey", cascade="all, delete-orphan"
    )


class MentalRoutineSurveyQuestion(Base):
    __tablename__ = "TB_MR_SURVEY_QUESTION"

    question_id = Column("QUESTION_ID", BigInteger, primary_key=True, autoincrement=True)
    survey_id = Column(
        "SURVEY_ID",
        BigInteger,
        ForeignKey("TB_MR_SURVEY.SURVEY_ID"),
        nullable=False,
        index=True,
    )
    question_no = Column("QUESTION_NO", Integer, nullable=False)
    title = Column("TITLE", String(100), nullable=False)
    description = Column("DESCRIPTION", String(500), nullable=True)
    score = Column("SCORE", Integer, nullable=False, default=1)
    active_yn = Column("ACTIVE_YN", String(1), nullable=False, default="Y")
    created_at = Column("CREATED_AT", DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        "UPDATED_AT", DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    survey = relationship("MentalRoutineSurvey", back_populates="questions")
    answers = relationship(
        "MentalRoutineSurveyAnswer", back_populates="question", cascade="all, delete-orphan"
    )


class MentalRoutineSurveyResult(Base):
    __tablename__ = "TB_MR_SURVEY_RESULT"

    result_id = Column("RESULT_ID", BigInteger, primary_key=True, autoincrement=True)
    survey_id = Column(
        "SURVEY_ID",
        BigInteger,
        ForeignKey("TB_MR_SURVEY.SURVEY_ID"),
        nullable=False,
        index=True,
    )
    user_id = Column("USER_ID", BigInteger, nullable=False, index=True)
    taken_at = Column("TAKEN_AT", DateTime(timezone=True), server_default=func.now())
    total_score = Column("TOTAL_SCORE", Integer, nullable=False, default=0)
    risk_level = Column("RISK_LEVEL", String(20), nullable=False)
    comment = Column("COMMENT", String(500), nullable=True)
    created_at = Column("CREATED_AT", DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        "UPDATED_AT", DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    survey = relationship("MentalRoutineSurvey", back_populates="results")
    answers = relationship(
        "MentalRoutineSurveyAnswer", back_populates="result", cascade="all, delete-orphan"
    )


class MentalRoutineSurveyAnswer(Base):
    __tablename__ = "TB_MR_SURVEY_ANSWER"

    answer_id = Column("ANSWER_ID", BigInteger, primary_key=True, autoincrement=True)
    result_id = Column(
        "RESULT_ID",
        BigInteger,
        ForeignKey("TB_MR_SURVEY_RESULT.RESULT_ID"),
        nullable=False,
        index=True,
    )
    question_id = Column(
        "QUESTION_ID",
        BigInteger,
        ForeignKey("TB_MR_SURVEY_QUESTION.QUESTION_ID"),
        nullable=False,
        index=True,
    )
    answer_value = Column("ANSWER_VALUE", String(1), nullable=False)
    score = Column("SCORE", Integer, nullable=False, default=0)
    created_at = Column("CREATED_AT", DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        "UPDATED_AT", DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    result = relationship("MentalRoutineSurveyResult", back_populates="answers")
    question = relationship("MentalRoutineSurveyQuestion", back_populates="answers")


# =====================================================================
# ✅ 기본 온보딩 설문 Seed 함수 (main.py 에서 startup 때 한 번 호출)
# =====================================================================

def seed_default_mr_survey(db: Session) -> MentalRoutineSurvey:
    """
    활성화된 설문이 없으면 기본 온보딩 설문(1-4-1)을 생성한다.
    이미 있으면 그대로 리턴.
    """
    existing = (
        db.query(MentalRoutineSurvey)
        .filter(MentalRoutineSurvey.active_yn == "Y")
        .order_by(MentalRoutineSurvey.survey_id.desc())
        .first()
    )
    if existing:
        return existing

    # 설문 마스터
    survey = MentalRoutineSurvey(
        name="마음봄 온보딩 1-4-1",
        description="요즘 마음과 하루 루틴을 가볍게 살펴보는 3단계 설문이에요.",
        active_yn="Y",
    )
    db.add(survey)
    db.flush()  # survey.survey_id 사용을 위해

    # Q1
    q1 = MentalRoutineSurveyQuestion(
        survey_id=survey.survey_id,
        question_no=1,
        title="오늘 하루, 마음 날씨는 어떤가요?",
        description="가장 가까운 느낌 하나만 골라주세요.",
        score=1,
        active_yn="Y",
    )

    # Q2
    q2 = MentalRoutineSurveyQuestion(
        survey_id=survey.survey_id,
        question_no=2,
        title="요즘 자주 무너지는 하루 루틴은 무엇인가요?",
        description="(예: 수면, 식사, 운동, 일/집안일, 사람관계 등)",
        score=1,
        active_yn="Y",
    )

    # Q3
    q3 = MentalRoutineSurveyQuestion(
        survey_id=survey.survey_id,
        question_no=3,
        title="지금 나에게 가장 필요한 도움은 무엇인가요?",
        description="마음에 와닿는 키워드를 떠올려보세요.",
        score=1,
        active_yn="Y",
    )

    db.add_all([q1, q2, q3])
    db.commit()

    return survey
