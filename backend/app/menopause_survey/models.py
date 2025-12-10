# backend/app/menopause_survey/models.py
from sqlalchemy import Column, Integer, String, ForeignKey, Text
from sqlalchemy.orm import relationship

# ✅ 너희 프로젝트에서 공용 Base 를 어디서 가져오는지 확인해서 아래 import 만 맞춰줘.
#   보통은 이런 패턴 중 하나야:
#   - from app.db.base import Base
#   - from app.auth.database import Base
from app.auth.database import Base  # << 필요하면 이 줄만 수정


class MenopauseSurvey(Base):
    __tablename__ = "menopause_surveys"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True, nullable=False)
    gender = Column(String(10), nullable=False)  # FEMALE / MALE
    total_score = Column(Integer, nullable=False)
    risk_level = Column(String(10), nullable=False)  # LOW / MID / HIGH

    answers = relationship(
        "MenopauseSurveyAnswer",
        back_populates="survey",
        cascade="all, delete-orphan",
    )
    result = relationship(
        "MenopauseSurveyResult",
        back_populates="survey",
        uselist=False,
        cascade="all, delete-orphan",
    )


class MenopauseSurveyAnswer(Base):
    __tablename__ = "menopause_survey_answers"

    id = Column(Integer, primary_key=True, index=True)
    survey_id = Column(Integer, ForeignKey("menopause_surveys.id", ondelete="CASCADE"))
    question_code = Column(String(20), nullable=False)
    question_text = Column(Text, nullable=False)
    answer_value = Column(Integer, nullable=False)  # 0 or 3
    answer_label = Column(String(20), nullable=False)  # 맞다 / 아니다

    survey = relationship("MenopauseSurvey", back_populates="answers")


class MenopauseSurveyResult(Base):
    __tablename__ = "menopause_survey_results"

    id = Column(Integer, primary_key=True, index=True)
    survey_id = Column(Integer, ForeignKey("menopause_surveys.id", ondelete="CASCADE"))
    total_score = Column(Integer, nullable=False)
    risk_level = Column(String(10), nullable=False)
    comment = Column(Text, nullable=False)

    survey = relationship("MenopauseSurvey", back_populates="result")