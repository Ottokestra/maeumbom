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
from app.db.models import EmotionAnalysis, User


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
        EmotionAnalysis(
            USER_ID=user.ID,
            CHECK_ROOT="conversation",
            TEXT="기쁨이 느껴진 대화",
            PRIMARY_EMOTION={"code": "joy", "name_ko": "기쁨", "intensity": 0.8},
            SENTIMENT_OVERALL="positive",
            MIXED_EMOTION={"mixed_ratio": 0.2},
            SERVICE_SIGNALS={"risk_level": "risk"},
            REPORT_TAGS=["기쁨 경향"],
            CREATED_AT=datetime.combine(week_start + timedelta(days=1), datetime.min.time()),
        ),
        EmotionAnalysis(
            USER_ID=user.ID,
            CHECK_ROOT="conversation",
            TEXT="불만이 있는 대화",
            PRIMARY_EMOTION={"code": "discontent", "name_ko": "불만", "intensity": 0.7},
            SENTIMENT_OVERALL="negative",
            MIXED_EMOTION={"mixed_ratio": 0.6},
            SERVICE_SIGNALS={"risk_level": "watch"},
            REPORT_TAGS=["불만 호소"],
            CREATED_AT=datetime.combine(week_start + timedelta(days=2), datetime.min.time()),
        ),
        EmotionAnalysis(
            USER_ID=user.ID,
            CHECK_ROOT="conversation",
            TEXT="중립적인 대화",
            PRIMARY_EMOTION={"code": "neutral", "name_ko": "중립", "intensity": 0.2},
            SENTIMENT_OVERALL="neutral",
            MIXED_EMOTION={"mixed_ratio": 0.1},
            SERVICE_SIGNALS={"risk_level": "normal"},
            REPORT_TAGS=[],
            CREATED_AT=datetime.combine(week_start + timedelta(days=3), datetime.min.time()),
        ),
        EmotionAnalysis(
            USER_ID=user.ID,
            CHECK_ROOT="conversation",
            TEXT="또 다른 기쁨",
            PRIMARY_EMOTION={"code": "joy", "name_ko": "기쁨", "intensity": 0.9},
            SENTIMENT_OVERALL="positive",
            MIXED_EMOTION={"mixed_ratio": 0.3},
            SERVICE_SIGNALS={"risk_level": "normal"},
            REPORT_TAGS=["기쁨"],
            CREATED_AT=datetime.combine(week_start + timedelta(days=4), datetime.min.time()),
        ),
        EmotionAnalysis(
            USER_ID=user.ID,
            CHECK_ROOT="conversation",
            TEXT="워치 신호",
            PRIMARY_EMOTION={"code": "anger", "name_ko": "분노", "intensity": 0.5},
            SENTIMENT_OVERALL="negative",
            MIXED_EMOTION={"mixed_ratio": 0.5},
            SERVICE_SIGNALS={"risk_level": "watch"},
            REPORT_TAGS=["분노"],
            CREATED_AT=datetime.combine(week_start + timedelta(days=5), datetime.min.time()),
        ),
        # Outside the target week
        EmotionAnalysis(
            USER_ID=user.ID,
            CHECK_ROOT="conversation",
            TEXT="다음 주 데이터",
            PRIMARY_EMOTION={"code": "sadness", "name_ko": "슬픔", "intensity": 0.4},
            SENTIMENT_OVERALL="negative",
            CREATED_AT=datetime.combine(week_start - timedelta(days=2), datetime.min.time()),
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

    assert report.dominant_emotion.code in ["joy", "discontent"]
    assert report.dominant_emotion.count >= 2
    assert report.overall_score_percent >= 50
    assert len(report.daily_characters) == 7
    assert any(sticker.has_record for sticker in report.daily_characters)
    assert len(report.sentiment_timeline) == 5
    assert {point.sentiment_score for point in report.sentiment_timeline} == {1.0, 0.0, -1.0}
    assert len(report.highlight_conversations) <= 5


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
    assert body["dominant_emotion"]["code"] in ["joy", "discontent"]
    assert body["overall_score_percent"] >= 50
    assert len(body["daily_characters"]) == 7
    assert len(body["sentiment_timeline"]) == 5
    assert len(body["highlight_conversations"]) <= 5
