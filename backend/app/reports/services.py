"""Service layer for emotion reports."""
from __future__ import annotations

from datetime import date
from sqlalchemy.orm import Session

from .schemas import (
    DateRange,
    DialogLine,
    EmotionMetrics,
    ReportCharacter,
    WeeklyEmotionReportResponse,
)


def get_default_characters() -> list[ReportCharacter]:
    """Return the default set of report characters."""
    return [
        ReportCharacter(
            id="bomi",
            name="봄이",
            role="메인",
            color="#FBCFE8",
            avatar_url=None,
        ),
        ReportCharacter(
            id="coach",
            name="코치봄",
            role="코치",
            color="#BFDBFE",
            avatar_url=None,
        ),
        ReportCharacter(
            id="guardian",
            name="수호봄",
            role="수호",
            color="#BBF7D0",
            avatar_url=None,
        ),
    ]


def build_mock_weekly_metrics(user_id: int) -> EmotionMetrics:
    """Build a mock metrics snapshot for a user."""
    return EmotionMetrics(
        mood_score=62,
        stress_score=45,
        stability_score=70,
        talk_count=18,
        positive_ratio=0.6,
        negative_ratio=0.2,
        neutral_ratio=0.2,
        main_emotion="걱정",
        secondary_emotion="안도",
    )


def build_weekly_dialog(metrics: EmotionMetrics) -> list[DialogLine]:
    """Craft character dialog based on the provided metrics."""
    dialog: list[DialogLine] = [
        DialogLine(
            speaker_id="bomi",
            type="opening",
            emotion="warm",
            text="이번 주 마음을 같이 돌아봤어요.",
        ),
        DialogLine(
            speaker_id="coach",
            type="analysis",
            emotion="calm",
            text=(
                f"총 {metrics.talk_count}번의 대화를 나눴고, "
                f"그 중 {int(metrics.positive_ratio * 100)}%는 긍정적인 감정이었어요."
            ),
        ),
    ]

    if metrics.stress_score >= 60:
        dialog.append(
            DialogLine(
                speaker_id="guardian",
                type="warning",
                emotion="serious",
                text="스트레스가 높았던 한 주였어요. 잠깐 숨을 고르고, 가벼운 산책이나 스트레칭 어떨까요?",
            )
        )
    else:
        dialog.append(
            DialogLine(
                speaker_id="guardian",
                type="tip",
                emotion="calm",
                text="잘 버텨내고 있어요. 짧은 휴식 루틴을 이어가면 지금의 안정감을 오래 유지할 수 있을 거예요.",
            )
        )

    dialog.append(
        DialogLine(
            speaker_id="bomi",
            type="closing",
            emotion="warm",
            text="이번 주도 잘 버텨줘서 고마워요. 다음 주에는 조금 더 가벼운 마음이길 바랄게요.",
        )
    )

    return dialog


def build_weekly_report(
    db: Session,
    user_id: int,
    week_start: date,
    week_end: date,
    mock: bool,
) -> WeeklyEmotionReportResponse:
    """Assemble the weekly emotion report for the given user and period."""
    if mock:
        characters = get_default_characters()
        metrics = build_mock_weekly_metrics(user_id)
        dialog = build_weekly_dialog(metrics)

        return WeeklyEmotionReportResponse(
            has_data=True,
            period="WEEKLY",
            date_range=DateRange(start=week_start, end=week_end),
            title="금주의 너는 '걱정이 복숭아'",
            summary="이번 주 감정은 걱정이 조금 많았지만 잘 버텨냈어요.",
            characters=characters,
            metrics=metrics,
            dialog=dialog,
        )

    # TODO: Aggregate recent 7 days of chat and emotion logs from the database
    #       to compute metrics and build a dialog dynamically once the pipeline is ready.

    return WeeklyEmotionReportResponse(
        has_data=False,
        period="WEEKLY",
        date_range=DateRange(start=week_start, end=week_end),
        title=None,
        summary=None,
        characters=get_default_characters(),
        metrics=None,
        dialog=[],
    )
