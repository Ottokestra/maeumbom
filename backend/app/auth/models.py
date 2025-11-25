"""
SQLAlchemy models for authentication
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, Date, Index, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .database import Base


class User(Base):
    """
    User model for authentication
    
    Attributes:
        id: Primary key
        social_id: Unique identifier from OAuth provider (e.g., Google sub)
        provider: OAuth provider name (default: 'google')
        email: User email
        nickname: User display name
        refresh_token: Current valid refresh token (Whitelist strategy)
        created_at: Account creation timestamp
        updated_at: Last update timestamp
    """
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    social_id = Column(String(255), unique=True, nullable=False, index=True)
    provider = Column(String(50), nullable=False, default="google")
    email = Column(String(255), nullable=False)
    nickname = Column(String(255), nullable=False)
    refresh_token = Column(Text, nullable=True)  # Whitelist: store valid refresh token
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Create composite index for faster lookups
    __table_args__ = (
        Index('idx_provider_social_id', 'provider', 'social_id'),
    )
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, provider={self.provider})>"


class DailyMoodSelection(Base):
    """
    Daily mood check image selection model
    
    Attributes:
        id: Primary key
        user_id: Foreign key to users table
        selected_date: Date when image was selected (YYYY-MM-DD)
        image_id: Selected image ID
        sentiment: Sentiment classification (negative/neutral/positive)
        filename: Image filename
        description: Image description text
        emotion_result: Emotion analysis result (JSON)
        created_at: Selection timestamp
    """
    __tablename__ = "daily_mood_selections"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    selected_date = Column(Date, nullable=False, index=True)
    image_id = Column(Integer, nullable=False)
    sentiment = Column(String(20), nullable=False)  # negative, neutral, positive
    filename = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    emotion_result = Column(JSON, nullable=True)  # Store emotion analysis result as JSON
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Create composite index for faster lookups (user_id + selected_date)
    __table_args__ = (
        Index('idx_user_date', 'user_id', 'selected_date'),
    )
    
    # Relationship to User
    user = relationship("User", backref="daily_mood_selections")
    
    def __repr__(self):
        return f"<DailyMoodSelection(id={self.id}, user_id={self.user_id}, date={self.selected_date}, sentiment={self.sentiment})>"

