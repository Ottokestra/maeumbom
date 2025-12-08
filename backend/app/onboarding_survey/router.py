import logging
from typing import Any, Dict

from fastapi import APIRouter, Request

from .schemas import OnboardingSurveySubmitRequest

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/onboarding-survey",
    tags=["onboarding-survey"],
)


@router.post("/submit")
async def submit_onboarding_survey(
    payload: OnboardingSurveySubmitRequest,
    request: Request,
) -> Dict[str, Any]:
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

    return {
        "status": "OK",
        "message": "Onboarding survey received (stub).",
        "profile_id": dummy_profile_id,
    }
