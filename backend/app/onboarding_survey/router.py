import logging

from fastapi import APIRouter, Request

from .schemas import (
    OnboardingProfileSnapshot,
    OnboardingSurveySubmitRequest,
    OnboardingSurveySubmitResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/onboarding-survey",
    tags=["onboarding-survey"],
)


def _float(value: float | int | None, default: float = 0.0) -> float:
    """Coerce nullable numeric values into a concrete float for responses."""

    return float(value) if value is not None else default


def _int(value: int | None, default: int = 0) -> int:
    """Coerce nullable integer values into a concrete int for responses."""

    return int(value) if value is not None else default


@router.post("/submit", response_model=OnboardingSurveySubmitResponse)
async def submit_onboarding_survey(
    payload: OnboardingSurveySubmitRequest,
    request: Request,
) -> OnboardingSurveySubmitResponse:
    """
    개발용 더미 온보딩 설문 제출 엔드포인트.

    - 현재는 DB에 아무 것도 저장하지 않는다.
    - 들어온 payload 를 로그로 남기고,
      프론트가 후속 화면(홈/리포트)로 넘어갈 수 있도록
      항상 200 OK 와 간단한 더미 profile 정보를 응답한다.
    - 나중에 실제 구현 시 이 함수 내부만 교체하면 되도록 최대한 단순하게 둔다.
    """
    logger.info(
        "Received onboarding survey (stub): user_id=%s, answers=%d",
        payload.user_id,
        len(payload.answers),
    )

    # TODO: 실제 구현에서는 여기에서 DB에 저장하고, 생성/갱신된 profile_id 를 리턴한다.
    dummy_profile_id = -1

    # 숫자 필드는 기본값을 채워 null-safe 하게 내려보낸다.
    # progress 는 답변 수를 기반으로 최소 0.0~1.0 사이 값으로 보정한다.
    total_questions = len(payload.answers)
    progress = 1.0 if total_questions else 0.0

    response = OnboardingSurveySubmitResponse(
        status="OK",
        message="Onboarding survey received (stub).",
        profile=OnboardingProfileSnapshot(
            profile_id=_int(dummy_profile_id, default=0),
            score=_float(0.0),
            level=_int(0),
            progress=_float(progress),
            stage="onboarding-complete",
        ),
    )

    # 예시 요청/응답:
    # 요청
    # {
    #   "user_id": 123,
    #   "answers": [
    #     {"question_id": "q1", "answer_id": "a1"}
    #   ]
    # }
    # 응답
    # {
    #   "status": "OK",
    #   "message": "Onboarding survey received (stub).",
    #   "profile": {
    #     "profileId": -1,
    #     "score": 0.0,
    #     "level": 0,
    #     "progress": 1.0,
    #     "stage": "onboarding-complete"
    #   }
    # }

    return response
