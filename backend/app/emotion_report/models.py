from sqlalchemy import Column, Date, DateTime, Integer, JSON, String, func

from app.database import Base


class EmotionWeeklyReport(Base):
    __tablename__ = "emotion_weekly_reports"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True, nullable=False)

    week_start = Column(Date, nullable=False)
    week_end = Column(Date, nullable=False)

    main_character_code = Column(String(50), nullable=False)
    main_emotion_label = Column(String(100), nullable=False)

    temperature = Column(Integer, nullable=False)

    weekly_emotions = Column(JSON, nullable=False)

    suggestion = Column(String(500), nullable=True)

    created_at = Column(DateTime, server_default=func.now(), nullable=False)
