from datetime import date
from unittest.mock import Mock

import pytest

pytest.importorskip("sqlalchemy")

from app.reports.emotion_weekly.services import (
    _calculate_temperature,
    _determine_badge,
    build_weekly_emotion_report,
)
from app.reports.emotion_weekly.schemas import WeeklyEmotionReportResponse


class DummyRecord:
    def __init__(self, label: str, score: float):
        self.label = label
        self.score = score


def test_temperature_level_and_score_hot_when_positive_dominant():
    records = [DummyRecord(label="기쁨", score=0.8), DummyRecord(label="희망", score=0.6)]

    temperature = _calculate_temperature(records)

    assert temperature.score == 100
    assert temperature.level == "hot"
    assert temperature.positive_ratio == 1.0
    assert temperature.negative_ratio == 0.0


def test_badge_selection_for_worried_week():
    records = [DummyRecord(label="불안", score=0.6), DummyRecord(label="슬픔", score=0.2)]

    badge = _determine_badge(records)

    assert badge.code == "WORRIED_WEEK"
    assert "걱정" in badge.label


def test_build_weekly_report_handles_empty_records():
    repository = Mock()
    repository.fetch_emotion_records.return_value = []
    repository.fetch_conversations.return_value = []

    report = build_weekly_emotion_report(user_id=1, week_start=date(2024, 12, 1), repository=repository)

    assert isinstance(report, WeeklyEmotionReportResponse)
    assert report.temperature.level == "neutral"
    assert report.badge.code == "BALANCED_WEEK"
    assert report.summary_bubbles == []
