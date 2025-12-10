from datetime import date, datetime, timedelta

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.auth.dependencies import get_current_user
from app.dashboard.routes import router as dashboard_router
from app.dashboard.service import get_weekly_mood_report
from app.db.database import Base, get_db
from app.db.models import User, UserEmotionLog


TEST_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)


@pytest.fixture
def db_session():
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


def seed_weekly_logs(session: Session, week_start: date) -> User:
    user = User(SOCIAL_ID="weekly-seed", EMAIL="weekly@example.com", NICKNAME="tester")
    session.add(user)
    session.commit()
    session.refresh(user)

    records = [
        UserEmotionLog(
            user_id=user.ID,
            session_id="s1",
            emotion_label="happy",
            sentiment_score=0.8,
            created_at=datetime.combine(week_start + timedelta(days=1), datetime.min.time()),
        ),
        UserEmotionLog(
            user_id=user.ID,
            session_id="s1",
            emotion_label="sad",
            sentiment_score=-0.4,
            created_at=datetime.combine(week_start + timedelta(days=2), datetime.min.time()),
        ),
        UserEmotionLog(
            user_id=user.ID,
            session_id="s2",
            emotion_label="happy",
            sentiment_score=0.6,
            created_at=datetime.combine(week_start + timedelta(days=3), datetime.min.time()),
        ),
        # Outside the target week
        UserEmotionLog(
            user_id=user.ID,
            session_id="s3",
            emotion_label="anger",
            sentiment_score=-0.9,
            created_at=datetime.combine(week_start - timedelta(days=2), datetime.min.time()),
        ),
    ]
    session.add_all(records)
    session.commit()
    return user


def test_get_weekly_mood_report_service(db_session: Session):
    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    user = seed_weekly_logs(db_session, week_start)

    report = get_weekly_mood_report(
        db=db_session, user_id=user.ID, week_start=week_start, week_end=week_start + timedelta(days=6)
    )

    assert report.dominant_emotion.code == "JOY"
    assert report.dominant_emotion.count == 2
    assert report.overall_score_percent >= 60
    assert len(report.daily_characters) == 7
    assert any(sticker.has_record for sticker in report.daily_characters)


def test_weekly_mood_report_endpoint(db_session: Session):
    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    user = seed_weekly_logs(db_session, week_start)

    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    def override_get_current_user():
        return user

    app = FastAPI()
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = override_get_current_user
    app.include_router(dashboard_router, prefix="/api/dashboard")

    client = TestClient(app)
    response = client.get("/api/dashboard/weekly-mood-report")

    assert response.status_code == 200
    body = response.json()
    assert body["dominant_emotion"]["code"] == "JOY"
    assert body["overall_score_percent"] >= 60
    assert len(body["daily_characters"]) == 7
