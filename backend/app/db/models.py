"""
SQLAlchemy models for all database tables
Centralized model management
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, Date, Index, ForeignKey, JSON, Float, Boolean, Time
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
        DISPLAYED_IMAGES: The 3 images shown during selection (JSON)
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
    DISPLAYED_IMAGES = Column(JSON, nullable=True)  # Store the 3 images shown during selection
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


# ============================================================================
# 신규 모델 (사용자 Phase 및 건강 데이터) - User Phase Service
# ============================================================================

class HealthLog(Base):
    """
    Health data log model
    Stores daily health data from Apple HealthKit and Android Health Connect
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table
        LOG_DATE: Date of the health data (YYYY-MM-DD)
        SLEEP_START_TIME: Sleep start time (bedtime)
        SLEEP_END_TIME: Sleep end time (wake time) - used for Phase calculation
        STEP_COUNT: Daily step count
        SLEEP_DURATION_HOURS: Total sleep duration in hours
        HEART_RATE_AVG: Average heart rate
        HEART_RATE_RESTING: Resting heart rate
        HEART_RATE_VARIABILITY: Heart rate variability (HRV)
        ACTIVE_MINUTES: Active minutes
        EXERCISE_MINUTES: Exercise minutes
        CALORIES_BURNED: Calories burned
        DISTANCE_KM: Distance traveled in kilometers
        SOURCE_TYPE: Data source ("manual", "apple_health", "google_fit")
        RAW_DATA: Original health data in JSON format
        CREATED_AT: Creation timestamp
    """
    __tablename__ = "TB_HEALTH_LOGS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    LOG_DATE = Column(Date, nullable=False, index=True)
    
    # Phase calculation (core data)
    SLEEP_START_TIME = Column(DateTime(timezone=True), nullable=True)
    SLEEP_END_TIME = Column(DateTime(timezone=True), nullable=True)
    STEP_COUNT = Column(Integer, nullable=True)
    
    # Menopause health monitoring (common data for iOS & Android)
    SLEEP_DURATION_HOURS = Column(Float, nullable=True)
    HEART_RATE_AVG = Column(Integer, nullable=True)
    HEART_RATE_RESTING = Column(Integer, nullable=True)
    HEART_RATE_VARIABILITY = Column(Float, nullable=True)
    ACTIVE_MINUTES = Column(Integer, nullable=True)
    EXERCISE_MINUTES = Column(Integer, nullable=True)
    CALORIES_BURNED = Column(Integer, nullable=True)
    DISTANCE_KM = Column(Float, nullable=True)
    
    # Metadata
    SOURCE_TYPE = Column(String(50), nullable=False)  # "manual", "apple_health", "google_fit"
    RAW_DATA = Column(JSON, nullable=True)  # Original data for extensibility
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    
    # Create composite index for faster lookups
    __table_args__ = (
        Index('idx_user_date', 'USER_ID', 'LOG_DATE'),
    )
    
    # Relationship to User
    user = relationship("User", backref="health_logs")
    
    def __repr__(self):
        return f"<HealthLog(ID={self.ID}, USER_ID={self.USER_ID}, LOG_DATE={self.LOG_DATE}, SOURCE_TYPE={self.SOURCE_TYPE})>"


class UserPatternSetting(Base):
    """
    User pattern setting model
    Stores weekly pattern analysis results (weekday/weekend patterns)
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table (unique)
        WEEKDAY_WAKE_TIME: Average wake time for weekdays (Mon-Fri)
        WEEKDAY_SLEEP_TIME: Average sleep time for weekdays (Mon-Fri)
        WEEKEND_WAKE_TIME: Average wake time for weekends (Sat-Sun)
        WEEKEND_SLEEP_TIME: Average sleep time for weekends (Sat-Sun)
        LAST_ANALYSIS_DATE: Last pattern analysis date
        DATA_COMPLETENESS: Data completeness score (0.0-1.0)
        IS_NIGHT_WORKER: Night worker flag
        CREATED_AT: Creation timestamp
        UPDATED_AT: Last update timestamp
    """
    __tablename__ = "TB_USER_PATTERN_SETTINGS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, unique=True, index=True)
    
    # Weekday pattern (Mon-Fri average)
    WEEKDAY_WAKE_TIME = Column(Time, nullable=False)
    WEEKDAY_SLEEP_TIME = Column(Time, nullable=False)
    
    # Weekend pattern (Sat-Sun average)
    WEEKEND_WAKE_TIME = Column(Time, nullable=False)
    WEEKEND_SLEEP_TIME = Column(Time, nullable=False)
    
    # Analysis metadata
    LAST_ANALYSIS_DATE = Column(Date, nullable=True)
    DATA_COMPLETENESS = Column(Float, nullable=True)  # 0.0-1.0
    
    # Other settings
    IS_NIGHT_WORKER = Column(Boolean, default=False)
    
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationship to User
    user = relationship("User", backref="pattern_setting", uselist=False)
    
    def __repr__(self):
        return f"<UserPatternSetting(ID={self.ID}, USER_ID={self.USER_ID}, WEEKDAY_WAKE={self.WEEKDAY_WAKE_TIME})>"


# ============================================================================
# 신규 모델 (인터랙티브 시나리오 서비스) - Relation Training & Drama
# ============================================================================

class Scenario(Base):
    """
    Scenario model for interactive training and drama
    
    Attributes:
        ID: Primary key
        TITLE: Scenario title
        TARGET_TYPE: Target relationship type (e.g., 'parent', 'friend', 'partner')
        CATEGORY: Scenario category ('TRAINING' or 'DRAMA')
        START_IMAGE_URL: Optional start image URL for the scenario
        CREATED_AT: Creation timestamp
        UPDATED_AT: Last update timestamp
    """
    __tablename__ = "TB_SCENARIOS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    TITLE = Column(String(255), nullable=False)
    TARGET_TYPE = Column(String(50), nullable=False)
    CATEGORY = Column(String(20), nullable=False)  # 'TRAINING' or 'DRAMA'
    START_IMAGE_URL = Column(String(500), nullable=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    nodes = relationship("ScenarioNode", back_populates="scenario", cascade="all, delete-orphan")
    results = relationship("ScenarioResult", back_populates="scenario", cascade="all, delete-orphan")
    play_logs = relationship("PlayLog", back_populates="scenario")
    
    def __repr__(self):
        return f"<Scenario(ID={self.ID}, TITLE={self.TITLE}, CATEGORY={self.CATEGORY})>"


class ScenarioNode(Base):
    """
    Scenario node model - represents each step in the scenario
    
    Attributes:
        ID: Primary key
        SCENARIO_ID: Foreign key to scenarios table
        STEP_LEVEL: Step level in the scenario (1, 2, 3, ...)
        SITUATION_TEXT: Situation description text
        IMAGE_URL: Optional image URL for the situation
        CREATED_AT: Creation timestamp
    """
    __tablename__ = "TB_SCENARIO_NODES"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    SCENARIO_ID = Column(Integer, ForeignKey("TB_SCENARIOS.ID"), nullable=False, index=True)
    STEP_LEVEL = Column(Integer, nullable=False)
    SITUATION_TEXT = Column(Text, nullable=False)
    IMAGE_URL = Column(String(500), nullable=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    
    # Create composite index for faster lookups
    __table_args__ = (
        Index('idx_scenario_step', 'SCENARIO_ID', 'STEP_LEVEL'),
    )
    
    # Relationships
    scenario = relationship("Scenario", back_populates="nodes")
    options = relationship("ScenarioOption", back_populates="node", foreign_keys="ScenarioOption.NODE_ID", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<ScenarioNode(ID={self.ID}, SCENARIO_ID={self.SCENARIO_ID}, STEP_LEVEL={self.STEP_LEVEL})>"


class ScenarioOption(Base):
    """
    Scenario option model - represents choices at each node
    
    Attributes:
        ID: Primary key
        NODE_ID: Foreign key to scenario nodes table
        OPTION_TEXT: Option text displayed to user
        OPTION_CODE: Option code for tracking (e.g., 'A', 'B', 'C')
        NEXT_NODE_ID: Foreign key to next node (NULL if this is an ending option)
        RESULT_ID: Foreign key to result (used when NEXT_NODE_ID is NULL)
        CREATED_AT: Creation timestamp
    """
    __tablename__ = "TB_SCENARIO_OPTIONS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    NODE_ID = Column(Integer, ForeignKey("TB_SCENARIO_NODES.ID"), nullable=False, index=True)
    OPTION_TEXT = Column(Text, nullable=False)
    OPTION_CODE = Column(String(10), nullable=False)
    NEXT_NODE_ID = Column(Integer, ForeignKey("TB_SCENARIO_NODES.ID"), nullable=True, index=True)
    RESULT_ID = Column(Integer, ForeignKey("TB_SCENARIO_RESULTS.ID"), nullable=True, index=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    node = relationship("ScenarioNode", back_populates="options", foreign_keys=[NODE_ID])
    next_node = relationship("ScenarioNode", foreign_keys=[NEXT_NODE_ID])
    result = relationship("ScenarioResult", back_populates="options")
    
    def __repr__(self):
        return f"<ScenarioOption(ID={self.ID}, NODE_ID={self.NODE_ID}, OPTION_CODE={self.OPTION_CODE})>"


class ScenarioResult(Base):
    """
    Scenario result model - represents possible endings
    
    Attributes:
        ID: Primary key
        SCENARIO_ID: Foreign key to scenarios table
        RESULT_CODE: Result code for tracking (e.g., 'SUCCESS', 'FAIL', 'NEUTRAL')
        DISPLAY_TITLE: Result title displayed to user
        ANALYSIS_TEXT: Detailed analysis text
        ATMOSPHERE_IMAGE_TYPE: Image type for atmosphere (e.g., 'positive', 'negative', 'neutral')
        SCORE: Score for this result (0-100)
        IMAGE_URL: Optional image URL for result (4컷만화 이미지)
        CREATED_AT: Creation timestamp
    """
    __tablename__ = "TB_SCENARIO_RESULTS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    SCENARIO_ID = Column(Integer, ForeignKey("TB_SCENARIOS.ID"), nullable=False, index=True)
    RESULT_CODE = Column(String(50), nullable=False)
    DISPLAY_TITLE = Column(String(255), nullable=False)
    ANALYSIS_TEXT = Column(Text, nullable=False)
    ATMOSPHERE_IMAGE_TYPE = Column(String(50), nullable=True)
    SCORE = Column(Integer, nullable=True)
    IMAGE_URL = Column(String(500), nullable=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    
    # Create composite index for faster lookups
    __table_args__ = (
        Index('idx_scenario_result', 'SCENARIO_ID', 'RESULT_CODE'),
    )
    
    # Relationships
    scenario = relationship("Scenario", back_populates="results")
    options = relationship("ScenarioOption", back_populates="result")
    play_logs = relationship("PlayLog", back_populates="result")
    
    def __repr__(self):
        return f"<ScenarioResult(ID={self.ID}, SCENARIO_ID={self.SCENARIO_ID}, RESULT_CODE={self.RESULT_CODE})>"


class PlayLog(Base):
    """
    Play log model - tracks user's scenario plays
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table
        SCENARIO_ID: Foreign key to scenarios table
        RESULT_ID: Foreign key to results table
        PATH_CODE: Path taken through the scenario (e.g., 'A-B-C')
        CREATED_AT: Play timestamp
    """
    __tablename__ = "TB_PLAY_LOGS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    SCENARIO_ID = Column(Integer, ForeignKey("TB_SCENARIOS.ID"), nullable=False, index=True)
    RESULT_ID = Column(Integer, ForeignKey("TB_SCENARIO_RESULTS.ID"), nullable=False, index=True)
    PATH_CODE = Column(String(255), nullable=False)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    
    # Create composite index for faster lookups
    __table_args__ = (
        Index('idx_user_scenario', 'USER_ID', 'SCENARIO_ID', 'CREATED_AT'),
        Index('idx_scenario_result', 'SCENARIO_ID', 'RESULT_ID'),
    )
    
    # Relationships
    user = relationship("User", backref="play_logs")
    scenario = relationship("Scenario", back_populates="play_logs")
    result = relationship("ScenarioResult", back_populates="play_logs")
    
    def __repr__(self):
        return f"<PlayLog(ID={self.ID}, USER_ID={self.USER_ID}, SCENARIO_ID={self.SCENARIO_ID}, RESULT_ID={self.RESULT_ID})>"
