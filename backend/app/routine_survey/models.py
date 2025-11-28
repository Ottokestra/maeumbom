"""SQLAlchemy models for the mental routine survey domain."""
from sqlalchemy import Column, BigInteger, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

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
