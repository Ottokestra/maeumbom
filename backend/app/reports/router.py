"""Demo-friendly weekly emotion report API."""
from __future__ import annotations

from datetime import date, timedelta
from typing import List

from fastapi import APIRouter

from .schemas import (
    DateRange,
    DialogLine,
    EmotionMetrics,
    ReportCharacter,
    WeeklyEmotionReportResponse,
)

router = APIRouter(prefix="/api/reports", tags=["reports"])


def get_default_characters() -> List[ReportCharacter]:
    """Return the default set of characters used in the report."""
    return [
        ReportCharacter(id="bomi", name="봄이", color="#F6E6FF", role="메인"),
        ReportCharacter(id="coach", name="코치봄", color="#E0F0FF", role="코치"),
        ReportCharacter(id="guardian", name="수호봄", color="#E4FFE0", role="수호"),
    ]


def build_mock_metrics() -> EmotionMetrics:
    """Create a static set of emotion metrics for demo purposes."""
    return EmotionMetrics(
        mood_score=62,
        stress_score=48,
        stability_score=73,
        talk_count=18,
        positive_ratio=0.6,
        negative_ratio=0.2,
        neutral_ratio=0.2,
        main_emotion="걱정",
        secondary_emotion="피곤",
    )


def build_mock_dialog(metrics: EmotionMetrics) -> List[DialogLine]:
    """Construct a set of dialog lines referencing the provided metrics."""
    return [
        DialogLine(
            speaker_id="bomi",
            type="opening",
            emotion="따뜻함",
            text="이번 주 대일님의 마음을 같이 돌아봤어요. 솔직하게 나눠줘서 고마워요.",
        ),
        DialogLine(
            speaker_id="coach",
            type="analysis",
            emotion="격려",
            text=(
                f"이번 주에는 총 {metrics.talk_count}번의 대화를 나눴고, "
                f"그 중 약 {metrics.positive_ratio * 100:.0f}%는 긍정적인 감정이었어요."
            ),
        ),
        DialogLine(
            speaker_id="guardian",
            type="warning",
            emotion="걱정",
            text=(
                "특히 밤 시간에 걱정과 피곤함이 자주 나타났어요. "
                "자기 전에는 휴대폰 대신 가벼운 스트레칭을 추천드릴게요."
            ),
        ),
        DialogLine(
            speaker_id="coach",
            type="tip",
            emotion="안정",
            text="하루에 5분만이라도 숨 고르는 시간을 만들어보면 마음의 안정감이 조금씩 올라갈 거예요.",
        ),
        DialogLine(
            speaker_id="bomi",
            type="closing",
            emotion="희망",
            text=(
                "이번 주에도 잘 버텨줘서 고마워요. 다음 주에는 걱정 대신 가벼운 웃음이 "
                "조금 더 늘어나길 바라요 :)"
            ),
        ),
    ]


@router.get("/emotion/weekly", response_model=WeeklyEmotionReportResponse)
async def get_weekly_emotion_report() -> WeeklyEmotionReportResponse:
    """Return a mock weekly emotion report without requiring authentication or DB access."""
    today = date.today()
    date_range = DateRange(start=today - timedelta(days=6), end=today)

    metrics = build_mock_metrics()
    characters = get_default_characters()
    dialog = build_mock_dialog(metrics)

    return WeeklyEmotionReportResponse(
        has_data=True,
        period="WEEKLY",
        date_range=date_range,
        title="금주의 너는 '걱정이 복숭아'",
        summary="걱정이 많았지만 차분함을 유지하려는 노력이 돋보인 한 주였어요.",
        characters=characters,
        metrics=metrics,
        dialog=dialog,
    )
