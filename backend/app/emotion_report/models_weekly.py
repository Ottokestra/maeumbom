"""
SQLAlchemy models for Weekly Emotion Report.
"""

from sqlalchemy import Column, Integer, String, DateTime, Date, Text, ForeignKey, Float
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.database import Base


class WeeklyEmotionReport(Base):
    """
    Weekly Emotion Report model
    Stores aggregated weekly emotion analysis results for user's "My Page"

    Attributes:
        ID: Primary key
        USER_ID: Foreign key to TB_USERS
        WEEK_START: Start date of the week (Monday, Date type)
        WEEK_END: End date of the week (Sunday, Date type)
        EMOTION_TEMPERATURE: Emotion temperature score (0-100)
        POSITIVE_SCORE: Positive emotion score (0-100)
        NEGATIVE_SCORE: Negative emotion score (0-100)
        NEUTRAL_SCORE: Neutral emotion score (0-100)
        MAIN_EMOTION: Main emotion of the week
        MAIN_EMOTION_CONFIDENCE: Confidence score for main emotion (0.0-1.0)
        MAIN_EMOTION_CHARACTER_CODE: Character code for main emotion
        BADGES: JSON array of badge strings
        SUMMARY_TEXT: Summary text for the week
        CREATED_AT: Creation timestamp
        UPDATED_AT: Last update timestamp
    """

    __tablename__ = "TB_WEEKLY_EMOTION_REPORTS"

    ID = Column(Integer, primary_key=True, autoincrement=True, index=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)

    # Week range (Date type, not DateTime)
    WEEK_START = Column(Date, nullable=False, index=True)
    WEEK_END = Column(Date, nullable=False)

    # Scores (Integer type, 0-100 range)
    EMOTION_TEMPERATURE = Column(Integer, nullable=False, default=0)
    POSITIVE_SCORE = Column(Integer, nullable=False, default=0)
    NEGATIVE_SCORE = Column(Integer, nullable=False, default=0)
    NEUTRAL_SCORE = Column(Integer, nullable=False, default=0)

    # Main emotion
    MAIN_EMOTION = Column(String(50), nullable=True)
    MAIN_EMOTION_CONFIDENCE = Column(Float, nullable=True)
    MAIN_EMOTION_CHARACTER_CODE = Column(String(100), nullable=True)

    # Badges and summary
    BADGES = Column(Text, nullable=True)  # JSON string stored as Text
    SUMMARY_TEXT = Column(Text, nullable=True)

    # Timestamps
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    UPDATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    user = relationship("User", backref="weekly_emotion_reports")
