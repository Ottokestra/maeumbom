import os
from datetime import datetime, timedelta

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.auth.dependencies import get_current_user
from app.db.database import Base, get_db
from app.db.models import User, UserEmotionLog
from app.reports.router import router as reports_router
from app.reports.services import get_user_report


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


def seed_user_with_logs(session: Session) -> User:
    user = User(SOCIAL_ID="social-1", EMAIL="user@example.com", NICKNAME="tester")
    session.add(user)
    session.commit()
    session.refresh(user)

    now = datetime.utcnow()
    logs = [
        UserEmotionLog(
            user_id=user.ID,
            session_id="s1",
            emotion_label="sad",
            sentiment_score=-0.5,
            created_at=now - timedelta(hours=1),
        ),
        UserEmotionLog(
            user_id=user.ID,
            session_id="s1",
            emotion_label="sad",
            sentiment_score=-0.2,
            created_at=now - timedelta(hours=2),
        ),
        UserEmotionLog(
            user_id=user.ID,
            session_id="s2",
            emotion_label="happy",
            sentiment_score=0.6,
            created_at=now - timedelta(days=1),
        ),
    ]
    session.add_all(logs)
    session.commit()
    return user


def test_get_user_report_returns_metrics(db_session):
    user = seed_user_with_logs(db_session)

    report = get_user_report(db_session, user_id=user.ID, period_type="daily", now=datetime.utcnow())

    assert report.metrics.total_messages == 2
    assert report.metrics.total_sessions == 1
    assert report.metrics.top_emotions[0].label == "sad"
    assert report.recommendation
    assert report.recent_highlights


def test_daily_report_endpoint_returns_data(db_session):
    user = seed_user_with_logs(db_session)

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
    app.include_router(reports_router, prefix="/api")

    client = TestClient(app)
    response = client.get("/api/reports/me/daily")

    assert response.status_code == 200
    body = response.json()
    assert body["metrics"]["total_messages"] == 2
    assert body["metrics"]["total_sessions"] == 1
    assert body["metrics"]["top_emotions"][0]["label"] == "sad"
