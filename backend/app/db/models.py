"""
SQLAlchemy models for all database tables
Centralized model management
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, Date, Index, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .database import Base


# ============================================================================
# 기존 모델 (auth 기능) - 새 규칙 적용
# ============================================================================

class User(Base):
    """
    User model for authentication
    
    Attributes:
        ID: Primary key
        SOCIAL_ID: Unique identifier from OAuth provider (e.g., Google sub)
        PROVIDER: OAuth provider name (default: 'google')
        EMAIL: User email
        NICKNAME: User display name
        REFRESH_TOKEN: Current valid refresh token (Whitelist strategy)
        CREATED_AT: Account creation timestamp
        UPDATED_AT: Last update timestamp
    """
    __tablename__ = "TB_USERS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    SOCIAL_ID = Column(String(255), unique=True, nullable=False, index=True)
    PROVIDER = Column(String(50), nullable=False, default="google")
    EMAIL = Column(String(255), nullable=False)
    NICKNAME = Column(String(255), nullable=False)
    REFRESH_TOKEN = Column(Text, nullable=True)  # Whitelist: store valid refresh token
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Create composite index for faster lookups
    __table_args__ = (
        Index('idx_provider_social_id', 'PROVIDER', 'SOCIAL_ID'),
    )
    
    def __repr__(self):
        return f"<User(ID={self.ID}, EMAIL={self.EMAIL}, PROVIDER={self.PROVIDER})>"


class DailyMoodSelection(Base):
    """
    Daily mood check image selection model
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to TB_USERS table
        SELECTED_DATE: Date when image was selected (YYYY-MM-DD)
        IMAGE_ID: Selected image ID
        SENTIMENT: Sentiment classification (negative/neutral/positive)
        FILENAME: Image filename
        DESCRIPTION: Image description text
        EMOTION_RESULT: Emotion analysis result (JSON)
        CREATED_AT: Selection timestamp
    """
    __tablename__ = "TB_DAILY_MOOD_SELECTIONS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    SELECTED_DATE = Column(Date, nullable=False, index=True)
    IMAGE_ID = Column(Integer, nullable=False)
    SENTIMENT = Column(String(20), nullable=False)  # negative, neutral, positive
    FILENAME = Column(String(255), nullable=False)
    DESCRIPTION = Column(Text, nullable=True)
    EMOTION_RESULT = Column(JSON, nullable=True)  # Store emotion analysis result as JSON
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    
    # Create composite index for faster lookups (USER_ID + SELECTED_DATE)
    __table_args__ = (
        Index('idx_user_date', 'USER_ID', 'SELECTED_DATE'),
    )
    
    # Relationship to User
    user = relationship("User", backref="daily_mood_selections")
    
    def __repr__(self):
        return f"<DailyMoodSelection(ID={self.ID}, USER_ID={self.USER_ID}, SELECTED_DATE={self.SELECTED_DATE}, SENTIMENT={self.SENTIMENT})>"


# ============================================================================
# 신규 모델 (감정분석 기능) - 새 규칙 적용
# ============================================================================

class EmotionAnalysis(Base):
    """
    Emotion analysis result model
    Stores emotion analysis results from the emotion-analysis engine
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table (optional)
        SESSION_ID: Session identifier
        TEXT: Original input text
        LANGUAGE: Language code (default: "ko")
        RAW_DISTRIBUTION: JSON field (17 emotion distribution)
        PRIMARY_EMOTION: JSON field (primary emotion info)
        SECONDARY_EMOTIONS: JSON field (secondary emotions)
        SENTIMENT_OVERALL: Overall sentiment (positive/neutral/negative)
        MIXED_EMOTION: JSON field (mixed emotion info, optional)
        SERVICE_SIGNALS: JSON field (service signals)
        RECOMMENDED_RESPONSE_STYLE: JSON field (recommended response styles)
        RECOMMENDED_ROUTINE_TAGS: JSON field (recommended routine tags)
        REPORT_TAGS: JSON field (report tags)
        CREATED_AT: Creation timestamp
    """
    __tablename__ = "TB_EMOTION_ANALYSIS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    SESSION_ID = Column(String(255), nullable=False, index=True)
    TEXT = Column(Text, nullable=False)
    LANGUAGE = Column(String(10), nullable=False, default="ko")
    RAW_DISTRIBUTION = Column(JSON, nullable=True)
    PRIMARY_EMOTION = Column(JSON, nullable=True)
    SECONDARY_EMOTIONS = Column(JSON, nullable=True)
    SENTIMENT_OVERALL = Column(String(20), nullable=False)
    MIXED_EMOTION = Column(JSON, nullable=True)
    SERVICE_SIGNALS = Column(JSON, nullable=True)
    RECOMMENDED_RESPONSE_STYLE = Column(JSON, nullable=True)
    RECOMMENDED_ROUTINE_TAGS = Column(JSON, nullable=True)
    REPORT_TAGS = Column(JSON, nullable=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    
    # Create composite index for faster lookups
    __table_args__ = (
        Index('idx_session_created', 'SESSION_ID', 'CREATED_AT'),
        Index('idx_user_created', 'USER_ID', 'CREATED_AT'),
    )
    
    # Relationship to User
    user = relationship("User", backref="emotion_analyses")
    
    def __repr__(self):
        return f"<EmotionAnalysis(ID={self.ID}, SESSION_ID={self.SESSION_ID}, SENTIMENT_OVERALL={self.SENTIMENT_OVERALL})>"

