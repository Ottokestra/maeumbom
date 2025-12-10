from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.onboarding_survey.router import router


def create_app() -> FastAPI:
    app = FastAPI()
    app.include_router(router)
    return app


def test_onboarding_survey_submit_numeric_fields_are_not_null() -> None:
    client = TestClient(create_app())

    payload = {
        "user_id": 123,
        "answers": [
            {"question_id": "q1", "answer_id": "a1"},
            {"question_id": "q2", "answer_text": "text"},
        ],
    }

    response = client.post("/api/onboarding-survey/submit", json=payload)

    assert response.status_code == 200

    data = response.json()
    profile = data["profile"]

    for field in ("profileId", "score", "level", "progress"):
        assert field in profile
        assert profile[field] is not None

    assert isinstance(profile["score"], (int, float))
    assert isinstance(profile["level"], (int, float))
    assert isinstance(profile["progress"], (int, float))
    assert profile["progress"] >= 0.0
    assert profile["progress"] <= 1.0
