"""
SQLAlchemy models for Weekly Emotion Report.
"""

from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Float, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.database import Base


class WeeklyEmotionReport(Base):
    __tablename__ = "TB_EMOTION_WEEKLY_REPORT"

    reportId = Column(
        "ID", Integer, primary_key=True, autoincrement=True
    )  # Mapped to reportId in schema if needed, but DB convention usually ID
    # User requested 'reportId' field in model description, but DB_GUIDE says PK is ID.
    # Pydantic schema will map ID -> reportId.

    userId = Column(
        "USER_ID", Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True
    )
    weekStart = Column("WEEK_START", DateTime(timezone=True), nullable=False)
    weekEnd = Column("WEEK_END", DateTime(timezone=True), nullable=False)

    emotionTemperature = Column("EMOTION_TEMPERATURE", Float, default=36.5)
    positiveScore = Column("POSITIVE_SCORE", Float, default=0.0)
    negativeScore = Column("NEGATIVE_SCORE", Float, default=0.0)
    neutralScore = Column("NEUTRAL_SCORE", Float, default=0.0)

    mainEmotion = Column("MAIN_EMOTION", String(50), nullable=True)
    mainEmotionConfidence = Column("MAIN_EMOTION_CONFIDENCE", Float, default=0.0)
    mainEmotionCharacterCode = Column(
        "MAIN_EMOTION_CHARACTER_CODE", String(50), nullable=True
    )

    badges = Column("BADGES", JSON, nullable=True)  # JSON Array of strings
    summaryText = Column("SUMMARY_TEXT", Text, nullable=True)

    createdAt = Column("CREATED_AT", DateTime(timezone=True), server_default=func.now())

    # Relationships
    snippets = relationship(
        "WeeklyEmotionDialogSnippet",
        back_populates="report",
        cascade="all, delete-orphan",
    )


class WeeklyEmotionDialogSnippet(Base):
    __tablename__ = "TB_EMOTION_WEEKLY_DIALOG_SNIPPET"

    id = Column("ID", Integer, primary_key=True, autoincrement=True)
    reportId = Column(
        "REPORT_ID",
        Integer,
        ForeignKey("TB_EMOTION_WEEKLY_REPORT.ID"),
        nullable=False,
        index=True,
    )

    role = Column("ROLE", String(20), nullable=False)  # USER / ASSISTANT
    content = Column("CONTENT", Text, nullable=False)
    emotion = Column("EMOTION", String(50), nullable=True)

    createdAt = Column("CREATED_AT", DateTime(timezone=True), server_default=func.now())

    report = relationship("WeeklyEmotionReport", back_populates="snippets")
