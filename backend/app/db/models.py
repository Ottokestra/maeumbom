"""
SQLAlchemy models for all database tables
Centralized model management
"""

from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    DateTime,
    Date,
    Index,
    ForeignKey,
    JSON,
    Float,
    Boolean,
    Time,
    UniqueConstraint,
)
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
    UPDATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Create composite index for faster lookups
    __table_args__ = (Index("idx_provider_social_id", "PROVIDER", "SOCIAL_ID"),)

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
    EMOTION_RESULT = Column(
        JSON, nullable=True
    )  # Store emotion analysis result as JSON
    DISPLAYED_IMAGES = Column(
        Text, nullable=True
    )  # Store the 3 images shown during selection (JSON string)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())

    # Create composite index for faster lookups (USER_ID + SELECTED_DATE)
    __table_args__ = (Index("idx_user_date", "USER_ID", "SELECTED_DATE"),)

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
        INPUT_TEXT_EMBEDDING: JSON array of embedding vector for similarity search
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
    INPUT_TEXT_EMBEDDING = Column(Text, nullable=True)  # JSON: "[0.123, -0.456, ...]"
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
        Index("idx_user_created", "USER_ID", "CREATED_AT"),
        Index("idx_check_root", "CHECK_ROOT"),
    )

    # Relationship to User
    user = relationship("User", backref="emotion_analyses")

    def __repr__(self):
        return f"<EmotionAnalysis(ID={self.ID}, CHECK_ROOT={self.CHECK_ROOT}, SENTIMENT_OVERALL={self.SENTIMENT_OVERALL})>"


class AnalyzedSession(Base):
    """
    Analyzed session tracking model
    Tracks which sessions have been analyzed to prevent duplicate emotion analysis

    Attributes:
        ID: Primary key
        SESSION_ID: Session identifier (must be unique)
        USER_ID: Foreign key to users table
        ANALYZED_AT: Timestamp when analysis was completed
    """

    __tablename__ = "TB_ANALYZED_SESSIONS"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    SESSION_ID = Column(String(255), unique=True, nullable=False, index=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    ANALYZED_AT = Column(DateTime(timezone=True), server_default=func.now())

    # Create composite index for faster lookups
    __table_args__ = (
        Index("idx_session_user", "SESSION_ID", "USER_ID"),
    )

    # Relationship to User
    user = relationship("User", backref="analyzed_sessions")

    def __repr__(self):
        return f"<AnalyzedSession(ID={self.ID}, SESSION_ID={self.SESSION_ID}, USER_ID={self.USER_ID})>"


class EmotionLog(Base):
    """
    감정 분석 결과 로그

    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table
        EMOTION_CODE: 분석 결과 감정 코드
        SCORE: 감정 점수 (선택 값)
        CREATED_AT: 로그 생성 시각
        IS_DELETED: 소프트 삭제 여부
    """

    __tablename__ = "TB_EMOTION_LOG"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    EMOTION_CODE = Column(String(50), nullable=False)
    SCORE = Column(Float, nullable=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    IS_DELETED = Column(Boolean, default=False, nullable=True)

    # Relationship to User
    user = relationship("User", backref="emotion_logs")

    def __repr__(self):
        return f"<EmotionLog(ID={self.ID}, USER_ID={self.USER_ID}, EMOTION_CODE={self.EMOTION_CODE})>"


# ============================================================================
# 갱년기 설문 모델 (Menopause Survey)
# ============================================================================


class MenopauseSurveyQuestion(Base):
    """
    갱년기 자가테스트 설문 문항 (성별/코드 기반)

    Attributes:
        ID: Primary key
        GENDER: 성별 구분 (FEMALE / MALE)
        CODE: 문항 코드 (예: F1~F10, M1~M10)
        ORDER_NO: 성별 내 표시 순서
        QUESTION_TEXT: 질문 텍스트
        RISK_WHEN_YES: "예" 응답 시 위험 여부
        POSITIVE_LABEL: 긍정 선택지 라벨 (기본값 "예")
        NEGATIVE_LABEL: 부정 선택지 라벨 (기본값 "아니오")
        CHARACTER_KEY: 프론트 캐릭터 매핑 키
        IS_ACTIVE: 활성화 여부
        IS_DELETED: 소프트 삭제 여부
        CREATED_AT/UPDATED_AT: 생성/수정 시각
        CREATED_BY/UPDATED_BY: 생성/수정자 정보
    """

    __tablename__ = "TB_MENOPAUSE_SURVEY_QUESTIONS"

    # NOTE: 기존 오타 테이블에서 데이터 이전 시 참고용 SQL (직접 실행 필요)
    # -- 개발 DB에서 한 번만 실행
    # -- INSERT INTO TB_MENOPAUSE_SURVEY_QUESTIONS (
    # --   GENDER, CODE, ORDER_NO, QUESTION_TEXT, RISK_WHEN_YES,
    # --   POSITIVE_LABEL, NEGATIVE_LABEL, CHARACTER_KEY,
    # --   IS_ACTIVE, IS_DELETED, CREATED_AT, UPDATED_AT, CREATED_BY, UPDATED_BY
    # -- )
    # -- SELECT
    # --   GENDER, CODE, ORDER_NO, QUESTION_TEXT, RISK_WHEN_YES,
    # --   POSITIVE_LABEL, NEGATIVE_LABEL, CHARACTER_KEY,
    # --   IS_ACTIVE, IS_DELETED, CREATED_AT, UPDATED_AT, CREATED_BY, UPDATED_BY
    # -- FROM TB_MENOPAUSE_SURVEY_QEUSTION;

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    GENDER = Column(String(10), nullable=False, index=True)
    CODE = Column(String(10), nullable=False, index=True)
    ORDER_NO = Column(Integer, nullable=False, index=True)
    QUESTION_TEXT = Column(Text, nullable=False)
    RISK_WHEN_YES = Column(Boolean, nullable=False, default=False)
    POSITIVE_LABEL = Column(String(20), nullable=False, default="예")
    NEGATIVE_LABEL = Column(String(20), nullable=False, default="아니오")
    CHARACTER_KEY = Column(String(50), nullable=True)
    IS_ACTIVE = Column(Boolean, default=True, nullable=True)
    IS_DELETED = Column(Boolean, default=False, nullable=True)
    CREATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=True
    )
    UPDATED_AT = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=True,
    )
    CREATED_BY = Column(String(50), nullable=True)
    UPDATED_BY = Column(String(50), nullable=True)

    __table_args__ = (
        UniqueConstraint("CODE", name="uq_menopause_survey_question_code"),
        Index("idx_menopause_gender_order", "GENDER", "ORDER_NO"),
    )

    def __repr__(self):
        return f"<MenopauseSurveyQuestion(ID={self.ID}, GENDER={self.GENDER}, CODE={self.CODE})>"


class MenopauseQuestion(Base):
    """
    갱년기 자가테스트 설문 문항

    Attributes:
        ID: Primary key
        ORDER_NO: 표시 순서
        CATEGORY: 카테고리
        QUESTION_TEXT: 질문 텍스트
        POSITIVE_LABEL: 긍정 선택지 라벨
        NEGATIVE_LABEL: 부정 선택지 라벨
        CHARACTER_KEY: 프론트 캐릭터 매핑 키
        IS_ACTIVE: 활성화 여부
        IS_DELETED: 소프트 삭제 여부
        CREATED_AT/UPDATED_AT: 생성/수정 시각
    """

    __tablename__ = "TB_MENOPAUSE_QUESTION"

    ID = Column(Integer, primary_key=True, autoincrement=True, index=True)
    ORDER_NO = Column(Integer, nullable=False, index=True)
    CATEGORY = Column(String(50), nullable=True)
    QUESTION_TEXT = Column(String(500), nullable=False)
    POSITIVE_LABEL = Column(String(50), nullable=False, default="예")
    NEGATIVE_LABEL = Column(String(50), nullable=False, default="아니오")
    CHARACTER_KEY = Column(String(50), nullable=True)
    IS_ACTIVE = Column(Boolean, default=True, nullable=True)
    IS_DELETED = Column(Boolean, default=False, nullable=True)
    CREATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=True
    )
    UPDATED_AT = Column(DateTime(timezone=True), nullable=True)

    def __repr__(self):
        return f"<MenopauseQuestion(ID={self.ID}, ORDER_NO={self.ORDER_NO})>"


class MenopauseAnswer(Base):
    """
    갱년기 자가테스트 설문 응답

    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table
        QUESTION_ID: Foreign key to TB_MENOPAUSE_QUESTION
        ANSWER_VALUE: 응답 값
        CREATED_AT: 생성 시각
    """

    __tablename__ = "TB_MENOPAUSE_ANSWER"

    ID = Column(Integer, primary_key=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    QUESTION_ID = Column(
        Integer, ForeignKey("TB_MENOPAUSE_QUESTION.ID"), nullable=False, index=True
    )
    ANSWER_VALUE = Column(String(10), nullable=False)
    CREATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=True
    )

    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="menopause_answers")
    question = relationship("MenopauseQuestion", backref="answers")

    def __repr__(self):
        return f"<MenopauseAnswer(ID={self.ID}, USER_ID={self.USER_ID}, QUESTION_ID={self.QUESTION_ID})>"


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
    IS_DELETED = Column(String(1), nullable=False, default="N", server_default="N")
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False)
    UPDATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True)

    # Composite indexes for performance
    __table_args__ = (
        Index("idx_user_session_conv", "USER_ID", "SESSION_ID"),
        Index("idx_session_created", "SESSION_ID", "CREATED_AT"),
        Index("idx_user_deleted_conv", "USER_ID", "IS_DELETED"),
    )

    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="conversations")
    creator = relationship("User", foreign_keys=[CREATED_BY])
    updater = relationship("User", foreign_keys=[UPDATED_BY])

    def __repr__(self):
        return f"<Conversation(ID={self.ID}, USER_ID={self.USER_ID}, SESSION_ID={self.SESSION_ID}, SPEAKER={self.SPEAKER_TYPE})>"


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
    IS_DELETED = Column(String(1), nullable=False, default="N", server_default="N")
    LAST_ACCESSED_AT = Column(DateTime(timezone=True), server_default=func.now())
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False)
    UPDATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True)

    # Composite indexes
    __table_args__ = (
        Index("idx_user_category", "USER_ID", "CATEGORY"),
        Index("idx_user_deleted_gmem", "USER_ID", "IS_DELETED"),
        Index("idx_user_importance", "USER_ID", "IMPORTANCE"),
    )

    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="global_memories")
    creator = relationship("User", foreign_keys=[CREATED_BY])
    updater = relationship("User", foreign_keys=[UPDATED_BY])

    def __repr__(self):
        return f"<GlobalMemory(ID={self.ID}, USER_ID={self.USER_ID}, CATEGORY={self.CATEGORY}, IMPORTANCE={self.IMPORTANCE})>"


class SpeakerProfile(Base):
    """
    Speaker Profile model for voice verification
    Stores speaker embeddings and verification scores

    Attributes:
        ID: Primary key
        USER_ID: Foreign key to TB_USERS (owner of this profile)
        SPEAKER_TYPE: Speaker identifier (e.g., 'user-A', 'user-B')
        CURRENT_SCORE: Current confidence score (0.0-1.0)
        USER_NAME: User's real name (optional, for future use)
        IS_DELETED: Soft delete flag ('Y'/'N')
        EMBEDDING: Speaker embedding vector (JSON array of floats)
        CREATED_AT: Creation timestamp
        CREATED_BY: User who created this record
        UPDATED_AT: Last update timestamp
        UPDATED_BY: User who last updated this record
    """

    __tablename__ = "TB_SPEAKER_PROFILES"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    SPEAKER_TYPE = Column(String(50), nullable=False)
    CURRENT_SCORE = Column(Float, nullable=False, default=0.0)
    USER_NAME = Column(String(255), nullable=True)
    IS_DELETED = Column(String(1), nullable=False, default="N", server_default="N")
    EMBEDDING = Column(JSON, nullable=False)  # 256-dim float vector

    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False)
    UPDATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True)

    # Composite indexes
    __table_args__ = (
        Index("idx_user_speaker", "USER_ID", "SPEAKER_TYPE"),
        Index("idx_user_deleted_spk", "USER_ID", "IS_DELETED"),
    )

    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="speaker_profiles")
    creator = relationship("User", foreign_keys=[CREATED_BY])
    updater = relationship("User", foreign_keys=[UPDATED_BY])

    def __repr__(self):
        return f"<SpeakerProfile(ID={self.ID}, USER_ID={self.USER_ID}, SPEAKER_TYPE={self.SPEAKER_TYPE}, SCORE={self.CURRENT_SCORE})>"


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
    SOURCE_TYPE = Column(
        String(50), nullable=False
    )  # "manual", "apple_health", "google_fit"
    RAW_DATA = Column(JSON, nullable=True)  # Original data for extensibility
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())

    # Create composite index for faster lookups
    __table_args__ = (Index("idx_user_date", "USER_ID", "LOG_DATE"),)

    # Relationship to User
    user = relationship("User", backref="health_logs")

    def __repr__(self):
        return f"<HealthLog(ID={self.ID}, USER_ID={self.USER_ID}, LOG_DATE={self.LOG_DATE}, SOURCE_TYPE={self.SOURCE_TYPE})>"


class ManualHealthLog(Base):
    """
    Manual health log model
    Stores manually entered health data (one record per user)

    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table (unique, one record per user)
        LOG_DATE: Date when user entered the data (last input date)
        SLEEP_START_TIME: Sleep start time
        SLEEP_END_TIME: Sleep end time (wake time)
        STEP_COUNT: Step count
        SLEEP_DURATION_HOURS: Sleep duration in hours
        HEART_RATE_AVG: Average heart rate
        HEART_RATE_RESTING: Resting heart rate
        HEART_RATE_VARIABILITY: Heart rate variability (HRV)
        ACTIVE_MINUTES: Active minutes
        EXERCISE_MINUTES: Exercise minutes
        CALORIES_BURNED: Calories burned
        DISTANCE_KM: Distance traveled in kilometers
        RAW_DATA: Original health data in JSON format
        CREATED_AT: Creation timestamp
        UPDATED_AT: Last update timestamp
    """

    __tablename__ = "TB_MANUAL_HEALTH_LOGS"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(
        Integer, ForeignKey("TB_USERS.ID"), nullable=False, unique=True, index=True
    )
    LOG_DATE = Column(
        Date, nullable=False
    )  # Date when user entered the data (last input date)

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
    RAW_DATA = Column(JSON, nullable=True)  # Original data for extensibility
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    UPDATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationship to User
    user = relationship("User", backref="manual_health_log", uselist=False)

    def __repr__(self):
        return f"<ManualHealthLog(ID={self.ID}, USER_ID={self.USER_ID}, LOG_DATE={self.LOG_DATE})>"


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
    USER_ID = Column(
        Integer, ForeignKey("TB_USERS.ID"), nullable=False, unique=True, index=True
    )

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
    UPDATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

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
        USER_ID: User ID for personalized scenarios (NULL for public scenarios)
        TITLE: Scenario title
        TARGET_TYPE: Target relationship type (e.g., 'parent', 'friend', 'partner')
        CATEGORY: Scenario category ('TRAINING' or 'DRAMA')
        START_IMAGE_URL: Optional start image URL for the scenario
        CREATED_AT: Creation timestamp
        UPDATED_AT: Last update timestamp
    """

    __tablename__ = "TB_SCENARIOS"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(
        Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True
    )  # NULL for public scenarios
    TITLE = Column(String(255), nullable=False)
    TARGET_TYPE = Column(String(50), nullable=False)
    CATEGORY = Column(String(20), nullable=False)  # 'TRAINING' or 'DRAMA'
    START_IMAGE_URL = Column(String(500), nullable=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    UPDATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    user = relationship("User", foreign_keys=[USER_ID])
    nodes = relationship(
        "ScenarioNode", back_populates="scenario", cascade="all, delete-orphan"
    )
    results = relationship(
        "ScenarioResult", back_populates="scenario", cascade="all, delete-orphan"
    )
    play_logs = relationship("PlayLog", back_populates="scenario")

    def __repr__(self):
        return f"<Scenario(ID={self.ID}, TITLE={self.TITLE}, CATEGORY={self.CATEGORY}, USER_ID={self.USER_ID})>"


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
    SCENARIO_ID = Column(
        Integer, ForeignKey("TB_SCENARIOS.ID"), nullable=False, index=True
    )
    STEP_LEVEL = Column(Integer, nullable=False)
    SITUATION_TEXT = Column(Text, nullable=False)
    IMAGE_URL = Column(String(500), nullable=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())

    # Create composite index for faster lookups
    __table_args__ = (Index("idx_scenario_step", "SCENARIO_ID", "STEP_LEVEL"),)

    # Relationships
    scenario = relationship("Scenario", back_populates="nodes")
    options = relationship(
        "ScenarioOption",
        back_populates="node",
        foreign_keys="ScenarioOption.NODE_ID",
        cascade="all, delete-orphan",
    )

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
    NODE_ID = Column(
        Integer, ForeignKey("TB_SCENARIO_NODES.ID"), nullable=False, index=True
    )
    OPTION_TEXT = Column(Text, nullable=False)
    OPTION_CODE = Column(String(10), nullable=False)
    NEXT_NODE_ID = Column(
        Integer, ForeignKey("TB_SCENARIO_NODES.ID"), nullable=True, index=True
    )
    RESULT_ID = Column(
        Integer, ForeignKey("TB_SCENARIO_RESULTS.ID"), nullable=True, index=True
    )
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    node = relationship(
        "ScenarioNode", back_populates="options", foreign_keys=[NODE_ID]
    )
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
        RESULT_CODE: Result code for tracking (e.g., 'AAAA', 'BBBB')
        DISPLAY_TITLE: Result title displayed to user
        ANALYSIS_TEXT: Detailed analysis text
        ATMOSPHERE_IMAGE_TYPE: Image type for atmosphere (e.g., 'FLOWER', 'SUNNY', 'CLOUDY', 'STORM')
        SCORE: Score for this result (0-100) - Legacy field for existing scenarios
        RELATION_HEALTH_LEVEL: Relationship health level (GOOD/MIXED/BAD) - New field for Deep Agent
        BOUNDARY_STYLE: Boundary setting style - New field for Deep Agent
        RELATIONSHIP_TREND: Long-term relationship trend - New field for Deep Agent
        IMAGE_URL: Optional image URL for result (4컷만화 이미지)
        CREATED_AT: Creation timestamp
    """

    __tablename__ = "TB_SCENARIO_RESULTS"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    SCENARIO_ID = Column(
        Integer, ForeignKey("TB_SCENARIOS.ID"), nullable=False, index=True
    )
    RESULT_CODE = Column(String(50), nullable=False)
    DISPLAY_TITLE = Column(String(255), nullable=False)
    ANALYSIS_TEXT = Column(Text, nullable=False)
    ATMOSPHERE_IMAGE_TYPE = Column(String(50), nullable=True)
    SCORE = Column(Integer, nullable=True)  # Legacy: for existing scenarios
    RELATION_HEALTH_LEVEL = Column(String(20), nullable=True)  # New: GOOD/MIXED/BAD
    BOUNDARY_STYLE = Column(
        String(50), nullable=True
    )  # New: HEALTHY_ASSERTIVE/OVER_ADAPTIVE/ASSERTIVE_HARSH/AVOIDANT
    RELATIONSHIP_TREND = Column(
        String(20), nullable=True
    )  # New: IMPROVING/STABLE/WORSENING
    IMAGE_URL = Column(String(500), nullable=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())

    # Create composite index for faster lookups
    __table_args__ = (Index("idx_scenario_result", "SCENARIO_ID", "RESULT_CODE"),)

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
    SCENARIO_ID = Column(
        Integer, ForeignKey("TB_SCENARIOS.ID"), nullable=False, index=True
    )
    RESULT_ID = Column(
        Integer, ForeignKey("TB_SCENARIO_RESULTS.ID"), nullable=False, index=True
    )
    PATH_CODE = Column(String(255), nullable=False)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())

    # Create composite index for faster lookups
    __table_args__ = (
        Index("idx_user_scenario", "USER_ID", "SCENARIO_ID", "CREATED_AT"),
        Index("idx_scenario_result", "SCENARIO_ID", "RESULT_ID"),
    )

    # Relationships
    user = relationship("User", backref="play_logs")
    scenario = relationship("Scenario", back_populates="play_logs")
    result = relationship("ScenarioResult", back_populates="play_logs")

    def __repr__(self):
        return f"<PlayLog(ID={self.ID}, USER_ID={self.USER_ID}, SCENARIO_ID={self.SCENARIO_ID}, RESULT_ID={self.RESULT_ID})>"


class AgentPlan(Base):
    """
    Agent Plan model
    Stores future plans or scheduled actions generated by the agent

    Attributes:
        ID: Primary key
        USER_ID: Foreign key to TB_USERS
        PLAN_TYPE: Type of plan (e.g., 'routine', 'reminder', 'suggestion')
        TARGET_DATE: Scheduled date/time for the plan
        CONTENT: Plan details (JSON or Text)
        STATUS: Current status (e.g., 'pending', 'completed', 'cancelled')
        SOURCE_SESSION_ID: Session ID where this plan was created
        CREATED_AT: Creation timestamp
        UPDATED_AT: Last update timestamp
    """

    __tablename__ = "TB_AGENT_PLANS"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    PLAN_TYPE = Column(String(50), nullable=False)
    TARGET_DATE = Column(DateTime(timezone=True), nullable=True)
    CONTENT = Column(Text, nullable=False)
    STATUS = Column(String(20), nullable=False, default="pending")
    SOURCE_SESSION_ID = Column(String(255), nullable=True)

    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    UPDATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Composite indexes
    __table_args__ = (
        Index("idx_user_plan_date", "USER_ID", "TARGET_DATE"),
        Index("idx_user_plan_status", "USER_ID", "STATUS"),
    )

    # Relationships
    user = relationship("User", backref="agent_plans")

    def __repr__(self):
        return f"<AgentPlan(ID={self.ID}, USER_ID={self.USER_ID}, TYPE={self.PLAN_TYPE}, STATUS={self.STATUS})>"


# ============================================================================
# 신규 모델 (온보딩 설문) - Onboarding Survey
# ============================================================================


class UserProfile(Base):
    """
    User Profile model for onboarding survey
    Stores user profile data from onboarding survey (Q1-Q11)

    Attributes:
        ID: Primary key
        USER_ID: Foreign key to TB_USERS (unique, one profile per user)
        NICKNAME: User nickname (Q1)
        AGE_GROUP: Age group (Q2) - '40대', '50대', '60대', '70대 이상'
        GENDER: Gender (Q3) - '여성', '남성'
        MARITAL_STATUS: Marital status (Q4) - '미혼', '기혼', '이혼/사별', '말하고 싶지 않음'
        CHILDREN_YN: Children existence (Q5) - '있음', '없음'
        LIVING_WITH: Living with (Q6, multi-select) - JSON array of Korean text
        PERSONALITY_TYPE: Personality type (Q7) - '내향적', '외향적', '상황에따라'
        ACTIVITY_STYLE: Activity style (Q8) - '조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'
        STRESS_RELIEF: Stress relief methods (Q9, multi-select) - JSON array of Korean text
        HOBBIES: Hobbies (Q10, multi-select) - JSON array of Korean text
        ATMOSPHERE: Preferred atmosphere (Q11, multi-select, optional) - JSON array of Korean text
        IS_DELETED: Soft delete flag
        CREATED_AT: Creation timestamp
        CREATED_BY: Creator user ID
        UPDATED_AT: Last update timestamp
        UPDATED_BY: Last updater user ID
    """

    __tablename__ = "TB_USER_PROFILE"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(
        Integer, ForeignKey("TB_USERS.ID"), nullable=False, unique=True, index=True
    )

    # Q1: Nickname (text input)
    NICKNAME = Column(String(100), nullable=False)

    # Q2-Q8: Single selection (Korean text values)
    AGE_GROUP = Column(
        String(50), nullable=False
    )  # '40대', '50대', '60대', '70대 이상'
    GENDER = Column(String(50), nullable=False)  # '여성', '남성'
    MARITAL_STATUS = Column(
        String(50), nullable=False
    )  # '미혼', '기혼', '이혼/사별', '말하고 싶지 않음'
    CHILDREN_YN = Column(String(50), nullable=False)  # '있음', '없음'
    PERSONALITY_TYPE = Column(
        String(100), nullable=False
    )  # '내향적', '외향적', '상황에따라'
    ACTIVITY_STYLE = Column(
        String(100), nullable=False
    )  # '조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'

    # Q6, Q9, Q10, Q11: Multi-select (JSON arrays of Korean text)
    LIVING_WITH = Column(JSON, nullable=False)  # ["혼자", "배우자와", "자녀와", ...]
    STRESS_RELIEF = Column(JSON, nullable=False)  # ["산책을 해요", "운동을 해요", ...]
    HOBBIES = Column(JSON, nullable=False)  # ["독서", "음악감상", ...]
    ATMOSPHERE = Column(
        JSON, nullable=True
    )  # ["잔잔한 분위기", "밝고 명랑한 분위기", ...] - Optional for future use

    # Standard fields
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)

    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="profile")
    creator = relationship(
        "User", foreign_keys=[CREATED_BY], backref="created_profiles"
    )
    updater = relationship(
        "User", foreign_keys=[UPDATED_BY], backref="updated_profiles"
    )

    def __repr__(self):
        return f"<UserProfile(ID={self.ID}, USER_ID={self.USER_ID}, NICKNAME={self.NICKNAME})>"


# ============================================================================
# 신조어 퀴즈 게임 모델 (Slang Quiz Game)
# ============================================================================


class SlangQuizQuestion(Base):
    """
    Slang quiz question pool model
    Pre-generated questions for slang quiz game

    Attributes:
        ID: Primary key
        LEVEL: Difficulty level (beginner/intermediate/advanced)
        QUIZ_TYPE: Quiz type (word_to_meaning/meaning_to_word)
        WORD: Slang word
        QUESTION: Question text
        OPTIONS: Answer options (JSON array of 4 strings)
        ANSWER_INDEX: Correct answer index (0-3)
        EXPLANATION: Explanation text
        REWARD_MESSAGE: Reward card message
        REWARD_BACKGROUND_MOOD: Reward card background mood (warm/cheer/cool)
        IS_ACTIVE: Whether this question is active
        USAGE_COUNT: How many times this question has been used
        IS_DELETED: Soft delete flag
        CREATED_AT: Creation timestamp
        CREATED_BY: Creator user ID
        UPDATED_AT: Last update timestamp
        UPDATED_BY: Last updater user ID
    """

    __tablename__ = "TB_SLANG_QUIZ_QUESTIONS"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    LEVEL = Column(String(20), nullable=False, index=True)
    QUIZ_TYPE = Column(String(50), nullable=False, index=True)
    WORD = Column(String(100), nullable=False)
    QUESTION = Column(Text, nullable=False)
    OPTIONS = Column(JSON, nullable=False)
    ANSWER_INDEX = Column(Integer, nullable=False)
    EXPLANATION = Column(Text, nullable=False)
    REWARD_MESSAGE = Column(String(100), nullable=False)
    REWARD_BACKGROUND_MOOD = Column(String(20), nullable=False)
    IS_ACTIVE = Column(Boolean, default=True, nullable=False, index=True)
    USAGE_COUNT = Column(Integer, default=0, nullable=False)

    # Standard fields
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)

    # Indexes
    __table_args__ = (
        Index("idx_level_type", "LEVEL", "QUIZ_TYPE"),
        Index("idx_active_deleted", "IS_ACTIVE", "IS_DELETED"),
    )

    # Relationships
    creator = relationship(
        "User", foreign_keys=[CREATED_BY], backref="created_quiz_questions"
    )
    updater = relationship(
        "User", foreign_keys=[UPDATED_BY], backref="updated_quiz_questions"
    )

    def __repr__(self):
        return (
            f"<SlangQuizQuestion(ID={self.ID}, LEVEL={self.LEVEL}, WORD={self.WORD})>"
        )


class SlangQuizGame(Base):
    """
    Slang quiz game session model
    Represents a single game session with 5 questions

    Attributes:
        ID: Primary key
        USER_ID: Foreign key to TB_USERS
        LEVEL: Difficulty level (beginner/intermediate/advanced)
        QUIZ_TYPE: Quiz type (word_to_meaning/meaning_to_word)
        TOTAL_QUESTIONS: Total number of questions (default: 5)
        CORRECT_COUNT: Number of correct answers
        TOTAL_SCORE: Total score earned
        TOTAL_TIME_SECONDS: Total time spent on the game
        IS_COMPLETED: Whether the game is completed
        IS_DELETED: Soft delete flag
        CREATED_AT: Game start timestamp
        CREATED_BY: Creator user ID
        UPDATED_AT: Last update timestamp
        UPDATED_BY: Last updater user ID
    """

    __tablename__ = "TB_SLANG_QUIZ_GAMES"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    LEVEL = Column(String(20), nullable=False)
    QUIZ_TYPE = Column(String(50), nullable=False)
    TOTAL_QUESTIONS = Column(Integer, default=5, nullable=False)
    CORRECT_COUNT = Column(Integer, default=0, nullable=False)
    TOTAL_SCORE = Column(Integer, default=0, nullable=False)
    TOTAL_TIME_SECONDS = Column(Integer, nullable=True)
    IS_COMPLETED = Column(Boolean, default=False, nullable=False)

    # Standard fields
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)

    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="slang_quiz_games")
    creator = relationship(
        "User", foreign_keys=[CREATED_BY], backref="created_slang_quiz_games"
    )
    updater = relationship(
        "User", foreign_keys=[UPDATED_BY], backref="updated_slang_quiz_games"
    )

    def __repr__(self):
        return f"<SlangQuizGame(ID={self.ID}, USER_ID={self.USER_ID}, LEVEL={self.LEVEL}, SCORE={self.TOTAL_SCORE})>"


class SlangQuizAnswer(Base):
    """
    Slang quiz answer model
    Stores user's answer for each question in a game

    Attributes:
        ID: Primary key
        GAME_ID: Foreign key to TB_SLANG_QUIZ_GAMES
        USER_ID: Foreign key to TB_USERS
        QUESTION_ID: Foreign key to TB_SLANG_QUIZ_QUESTIONS
        QUESTION_NUMBER: Question number in the game (1-5)
        USER_ANSWER_INDEX: User's selected answer index (0-3)
        IS_CORRECT: Whether the answer is correct
        RESPONSE_TIME_SECONDS: Time taken to answer (seconds)
        EARNED_SCORE: Score earned for this question
        IS_DELETED: Soft delete flag
        CREATED_AT: Answer submission timestamp
        CREATED_BY: Creator user ID
        UPDATED_AT: Last update timestamp
        UPDATED_BY: Last updater user ID
    """

    __tablename__ = "TB_SLANG_QUIZ_ANSWERS"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    GAME_ID = Column(
        Integer, ForeignKey("TB_SLANG_QUIZ_GAMES.ID"), nullable=False, index=True
    )
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    QUESTION_ID = Column(
        Integer, ForeignKey("TB_SLANG_QUIZ_QUESTIONS.ID"), nullable=False, index=True
    )
    QUESTION_NUMBER = Column(Integer, nullable=False)
    USER_ANSWER_INDEX = Column(Integer, nullable=True)
    IS_CORRECT = Column(Boolean, nullable=True)
    RESPONSE_TIME_SECONDS = Column(Integer, nullable=True)
    EARNED_SCORE = Column(Integer, nullable=True)

    # Standard fields
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)

    # Indexes
    __table_args__ = (Index("idx_game_question_num", "GAME_ID", "QUESTION_NUMBER"),)

    # Relationships
    game = relationship("SlangQuizGame", backref="answers")
    user = relationship("User", foreign_keys=[USER_ID], backref="slang_quiz_answers")
    question = relationship("SlangQuizQuestion", backref="answers")
    creator = relationship(
        "User", foreign_keys=[CREATED_BY], backref="created_slang_quiz_answers"
    )
    updater = relationship(
        "User", foreign_keys=[UPDATED_BY], backref="updated_slang_quiz_answers"
    )

    def __repr__(self):
        return f"<SlangQuizAnswer(ID={self.ID}, GAME_ID={self.GAME_ID}, QUESTION_NUMBER={self.QUESTION_NUMBER}, IS_CORRECT={self.IS_CORRECT})>"


# ============================================================================
# 갱년기 설문 결과 및 답변 모델
# ============================================================================


class MenopauseSurveyResult(Base):
    """
    Menopause survey result model
    """

    __tablename__ = "TB_MENOPAUSE_SURVEY_RESULT"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    GENDER = Column(String(10), nullable=False)  # FEMALE / MALE
    TOTAL_SCORE = Column(Integer, nullable=False, default=0)
    RISK_LEVEL = Column(String(10), nullable=False)  # LOW / MID / HIGH
    COMMENT = Column(Text, nullable=True)

    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    UPDATED_AT = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    answers = relationship(
        "MenopauseSurveyAnswer", back_populates="result", cascade="all, delete-orphan"
    )


class MenopauseSurveyAnswer(Base):
    """
    Menopause survey individual answer
    """

    __tablename__ = "TB_MENOPAUSE_SURVEY_ANSWER"

    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    RESULT_ID = Column(
        Integer, ForeignKey("TB_MENOPAUSE_SURVEY_RESULT.ID"), nullable=False, index=True
    )
    QUESTION_ID = Column(
        Integer,
        ForeignKey("TB_MENOPAUSE_SURVEY_QUESTIONS.ID"),
        nullable=False,
        index=True,
    )
    ANSWER_VALUE = Column(Integer, nullable=False)  # 0 or 3

    IS_DELETED = Column(Boolean, default=False, nullable=False)
    CREATED_AT = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    result = relationship("MenopauseSurveyResult", back_populates="answers")
    question = relationship("MenopauseSurveyQuestion")


# ============================================================================
# Routine Recommendations (from Emotion Analysis)
# ============================================================================


class RoutineRecommendation(Base):
    """
    루틴 추천 결과 저장
    
    Attributes:
        ID: Primary key
        USER_ID: 사용자 ID
        RECOMMENDATION_DATE: 추천 날짜 (YYYY-MM-DD)
        EMOTION_SUMMARY: 하루 감정 요약 (JSON)
        ROUTINES: 추천된 루틴 목록 (JSON)
        TOTAL_EMOTIONS: 해당 날짜 총 감정 분석 수
        PRIMARY_EMOTION: 주요 감정
        SENTIMENT_OVERALL: 전체 감정 (positive/negative/neutral)
        IS_DELETED: Deletion flag
        CREATED_AT: Creation timestamp
        CREATED_BY: Creator user ID
        UPDATED_AT: Last update timestamp
        UPDATED_BY: Last updater user ID
    """
    
    __tablename__ = "TB_ROUTINE_RECOMMENDATIONS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    RECOMMENDATION_DATE = Column(Date, nullable=False, index=True)
    
    # 감정 요약
    EMOTION_SUMMARY = Column(JSON, nullable=True)  # 하루치 감정 분포
    TOTAL_EMOTIONS = Column(Integer, nullable=False, default=0)
    PRIMARY_EMOTION = Column(String(50), nullable=True)
    SENTIMENT_OVERALL = Column(String(20), nullable=True)
    
    # 루틴 추천 결과
    ROUTINES = Column(JSON, nullable=True)  # 추천된 루틴 목록
    
    # 표준 필드
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    
    # 인덱스
    __table_args__ = (
        Index("idx_user_date_routine", "USER_ID", "RECOMMENDATION_DATE"),
        Index("idx_date_deleted_routine", "RECOMMENDATION_DATE", "IS_DELETED"),
    )
    
    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="routine_recommendations")
    creator = relationship("User", foreign_keys=[CREATED_BY])
    updater = relationship("User", foreign_keys=[UPDATED_BY])
    
    def __repr__(self):
        return f"<RoutineRecommendation(ID={self.ID}, USER_ID={self.USER_ID}, DATE={self.RECOMMENDATION_DATE})>"


# ============================================================================
# Target Events (마음서랍 - 대상별 이벤트 기억)
# ============================================================================


class DailyTargetEvent(Base):
    """
    Daily target event model
    Stores daily events extracted from conversations with specific targets
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table
        EVENT_DATE: Date of the event
        EVENT_TYPE: Event type (alarm/event/memory)
        TARGET_TYPE: Target relationship type (HUSBAND/CHILD/FRIEND/COLLEAGUE/SELF)
        EVENT_SUMMARY: Event summary text
        EVENT_TIME: Event time (nullable)
        IMPORTANCE: Importance level (1-5)
        IS_FUTURE_EVENT: Whether this is a future event
        TAGS: Tags for filtering (JSON array)
        RAW_CONVERSATION_IDS: Original conversation IDs (JSON array)
        PRIMARY_EMOTION: Primary emotion from EVENT_SUMMARY analysis (JSON)
        IS_DELETED: Deletion flag
        CREATED_AT: Creation timestamp
        CREATED_BY: Creator user ID
        UPDATED_AT: Last update timestamp
        UPDATED_BY: Last updater user ID
    """
    
    __tablename__ = "TB_DAILY_TARGET_EVENTS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    EVENT_DATE = Column(Date, nullable=False, index=True)
    EVENT_TYPE = Column(String(20), nullable=False, default="event", index=True)  # alarm/event/memory
    TARGET_TYPE = Column(String(50), nullable=False)  # HUSBAND/CHILD/FRIEND/COLLEAGUE/SELF
    EVENT_SUMMARY = Column(Text, nullable=False)
    EVENT_TIME = Column(DateTime(timezone=True), nullable=True)
    IMPORTANCE = Column(Integer, nullable=False, default=3)  # 1-5
    IS_FUTURE_EVENT = Column(Boolean, nullable=False, default=False)
    TAGS = Column(JSON, nullable=True)  # ["#아들", "#픽업", "#오늘", "#중요"]
    RAW_CONVERSATION_IDS = Column(JSON, nullable=True)  # [123, 124, 125]
    
    # 감정 데이터
    PRIMARY_EMOTION = Column(JSON, nullable=True)  # {"code": "joy", "name_ko": "기쁨", "group": "positive", "intensity": 5, "confidence": 0.92}
    
    # 표준 필드
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    
    # 인덱스
    __table_args__ = (
        Index("idx_user_date_target", "USER_ID", "EVENT_DATE", "TARGET_TYPE"),
        Index("idx_date_deleted", "EVENT_DATE", "IS_DELETED"),
    )
    
    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="daily_target_events")
    creator = relationship("User", foreign_keys=[CREATED_BY])
    updater = relationship("User", foreign_keys=[UPDATED_BY])
    
    def __repr__(self):
        return f"<DailyTargetEvent(ID={self.ID}, USER_ID={self.USER_ID}, EVENT_DATE={self.EVENT_DATE}, TARGET_TYPE={self.TARGET_TYPE})>"


class WeeklyTargetEvent(Base):
    """
    Weekly target event model
    Stores weekly summary of events by target type
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table
        WEEK_START: Week start date (Monday)
        WEEK_END: Week end date (Sunday)
        TARGET_TYPE: Target relationship type (HUSBAND/CHILD/FRIEND/COLLEAGUE/SELF)
        EVENTS_SUMMARY: Weekly events summary (JSON array)
        TOTAL_EVENTS: Total number of events
        TAGS: Aggregated tags (JSON array)
        EMOTION_DISTRIBUTION: Weekly emotion distribution (JSON dict)
        PRIMARY_EMOTION: Primary emotion of the week
        SENTIMENT_OVERALL: Overall sentiment (positive/negative/neutral)
        IS_DELETED: Deletion flag
        CREATED_AT: Creation timestamp
        CREATED_BY: Creator user ID
        UPDATED_AT: Last update timestamp
        UPDATED_BY: Last updater user ID
    """
    
    __tablename__ = "TB_WEEKLY_TARGET_EVENTS"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=False, index=True)
    WEEK_START = Column(Date, nullable=False, index=True)
    WEEK_END = Column(Date, nullable=False)
    TARGET_TYPE = Column(String(50), nullable=False)
    EVENTS_SUMMARY = Column(JSON, nullable=True)  # 주간 이벤트 요약 배열
    TOTAL_EVENTS = Column(Integer, nullable=False, default=0)
    TAGS = Column(JSON, nullable=True)  # 주간 통합 태그
    
    # 주간 감정 데이터
    EMOTION_DISTRIBUTION = Column(JSON, nullable=True)  # 감정 비율 분포 {"안정": 35, "기쁨": 25, ...}
    PRIMARY_EMOTION = Column(String(50), nullable=True)  # 주요 감정
    SENTIMENT_OVERALL = Column(String(20), nullable=True)  # 전체 감정 (positive/negative/neutral)
    
    # 표준 필드
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    
    # 인덱스
    __table_args__ = (
        Index("idx_user_week_target", "USER_ID", "WEEK_START", "TARGET_TYPE"),
    )
    
    # Relationships
    user = relationship("User", foreign_keys=[USER_ID], backref="weekly_target_events")
    creator = relationship("User", foreign_keys=[CREATED_BY])
    updater = relationship("User", foreign_keys=[UPDATED_BY])
    
    def __repr__(self):
        return f"<WeeklyTargetEvent(ID={self.ID}, USER_ID={self.USER_ID}, WEEK_START={self.WEEK_START}, TARGET_TYPE={self.TARGET_TYPE})>"


# ============================================================================
# Weekly Emotion Report (for My Page)
# ============================================================================

from app.emotion_report.models_weekly import WeeklyEmotionReport  # noqa: F401, E402
