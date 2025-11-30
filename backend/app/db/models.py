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
        CHECK_ROOT: Source of emotion analysis ("conversation" or "daily_mood_check")
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
    CHECK_ROOT = Column(String(20), nullable=False, index=True)
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
        Index('idx_user_created', 'USER_ID', 'CREATED_AT'),
        Index('idx_check_root', 'CHECK_ROOT'),
    )
    
    # Relationship to User
    user = relationship("User", backref="emotion_analyses")
    
    def __repr__(self):
        return f"<EmotionAnalysis(ID={self.ID}, CHECK_ROOT={self.CHECK_ROOT}, SENTIMENT_OVERALL={self.SENTIMENT_OVERALL})>"


# ============================================================================
# 대화 및 메모리 저장 모델 (Agent 기능)
# ============================================================================

class Conversation(Base):
    """
    Conversation history model
    Stores all conversation messages with user data isolation
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to TB_USERS (data isolation)
        SESSION_ID: Session identifier (UUID)
        SPEAKER_TYPE: Speaker identifier (user-A, user-B, assistant)
        CONTENT: Message content
        IS_DELETED: Soft delete flag ('Y'/'N')
        CREATED_AT: Creation timestamp
        CREATED_BY: User who created this record
        UPDATED_AT: Last update timestamp
        UPDATED_BY: User who last updated this record
    """
    __tablename__ = "TB_CONVERSATIONS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    SESSION_ID = Column(String(255), nullable=False, index=True)
    SPEAKER_TYPE = Column(String(50), nullable=False)  # user-A, user-B, assistant
    CONTENT = Column(Text, nullable=False)
    IS_DELETED = Column(String(1), nullable=False, default='N', server_default='N')
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False)
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True)
    
    # Composite indexes for performance
    __table_args__ = (
        Index('idx_user_session_conv', 'USER_ID', 'SESSION_ID'),
        Index('idx_session_created', 'SESSION_ID', 'CREATED_AT'),
        Index('idx_user_deleted_conv', 'USER_ID', 'IS_DELETED'),
    )
    
    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="conversations")
    creator = relationship("User", foreign_keys=[CREATED_BY])
    updater = relationship("User", foreign_keys=[UPDATED_BY])
    
    def __repr__(self):
        return f"<Conversation(ID={self.ID}, USER_ID={self.USER_ID}, SESSION_ID={self.SESSION_ID}, SPEAKER={self.SPEAKER_TYPE})>"


class SessionMemory(Base):
    """
    Session-specific short-term memory model
    Stores temporary memory data per session
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to TB_USERS (data isolation)
        SESSION_ID: Session identifier
        MEMORY_TYPE: Memory type (summary, context, emotion_flow, etc.)
        KEY_CONTENT: Memory content (text)
        VALUE_DATA: Structured data (JSON, optional)
        IS_DELETED: Soft delete flag ('Y'/'N')
        EXPIRES_AT: Expiration timestamp (optional)
        CREATED_AT: Creation timestamp
        CREATED_BY: User who created this record
        UPDATED_AT: Last update timestamp
        UPDATED_BY: User who last updated this record
    """
    __tablename__ = "TB_SESSION_MEMORIES"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    SESSION_ID = Column(String(255), nullable=False, index=True)
    MEMORY_TYPE = Column(String(50), nullable=False)
    KEY_CONTENT = Column(Text, nullable=False)
    VALUE_DATA = Column(JSON, nullable=True)
    IS_DELETED = Column(String(1), nullable=False, default='N', server_default='N')
    EXPIRES_AT = Column(DateTime(timezone=True), nullable=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False)
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True)
    
    # Composite indexes
    __table_args__ = (
        Index('idx_user_session_mem', 'USER_ID', 'SESSION_ID'),
        Index('idx_user_deleted_smem', 'USER_ID', 'IS_DELETED'),
        Index('idx_user_type', 'USER_ID', 'MEMORY_TYPE'),
    )
    
    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="session_memories")
    creator = relationship("User", foreign_keys=[CREATED_BY])
    updater = relationship("User", foreign_keys=[UPDATED_BY])
    
    def __repr__(self):
        return f"<SessionMemory(ID={self.ID}, USER_ID={self.USER_ID}, SESSION_ID={self.SESSION_ID}, TYPE={self.MEMORY_TYPE})>"


class GlobalMemory(Base):
    """
    Global long-term memory model
    Stores persistent user facts and patterns across sessions
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to TB_USERS (data isolation)
        CATEGORY: Memory category (health, preference, family, etc.)
        MEMORY_TEXT: Memory content (factual information)
        IMPORTANCE: Importance level (1-5, for RAG weighting)
        SOURCE_SESSION_ID: Origin session ID (for tracking)
        IS_DELETED: Soft delete flag ('Y'/'N')
        LAST_ACCESSED_AT: Last access timestamp (for forgetting mechanism)
        CREATED_AT: Creation timestamp
        CREATED_BY: User who created this record
        UPDATED_AT: Last update timestamp
        UPDATED_BY: User who last updated this record
    """
    __tablename__ = "TB_GLOBAL_MEMORIES"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    CATEGORY = Column(String(50), nullable=False)
    MEMORY_TEXT = Column(Text, nullable=False)
    IMPORTANCE = Column(Integer, default=1)
    SOURCE_SESSION_ID = Column(String(255), nullable=True)
    IS_DELETED = Column(String(1), nullable=False, default='N', server_default='N')
    LAST_ACCESSED_AT = Column(DateTime(timezone=True), server_default=func.now())
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False)
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True)
    
    # Composite indexes
    __table_args__ = (
        Index('idx_user_category', 'USER_ID', 'CATEGORY'),
        Index('idx_user_deleted_gmem', 'USER_ID', 'IS_DELETED'),
        Index('idx_user_importance', 'USER_ID', 'IMPORTANCE'),
    )
    
    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="global_memories")
    creator = relationship("User", foreign_keys=[CREATED_BY])
    updater = relationship("User", foreign_keys=[UPDATED_BY])
    
    def __repr__(self):
        return f"<GlobalMemory(ID={self.ID}, USER_ID={self.USER_ID}, CATEGORY={self.CATEGORY}, IMPORTANCE={self.IMPORTANCE})>"

