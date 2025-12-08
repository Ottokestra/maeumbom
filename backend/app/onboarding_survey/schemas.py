from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class OnboardingAnswer(BaseModel):
    question_id: str
    answer_id: Optional[str] = None
    answer_text: Optional[str] = None


class OnboardingSurveySubmitRequest(BaseModel):
    model_config = ConfigDict(extra="allow")

    # 유저 식별자는 현재 로그인 토큰/헤더에서 처리된다고 가정하고, 여기서는 옵션으로 둔다.
    user_id: Optional[int] = None
    answers: List[OnboardingAnswer] = Field(default_factory=list)


class OnboardingProfileSnapshot(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    # 클라이언트에서는 camelCase 로 사용하므로 alias 를 지정한다.
    profile_id: Optional[int] = Field(default=0, alias="profileId")
    score: Optional[float] = 0.0
    level: Optional[int] = 0
    progress: Optional[float] = 0.0
    # Optional 필드들은 None 을 그대로 내려보내도록 명시한다.
    stage: Optional[str] = None


class OnboardingSurveySubmitResponse(BaseModel):
    """온보딩 설문 제출 응답 모델.

    - 숫자 필드는 기본값을 지정하여 null 을 피한다.
    - Optional 로 선언된 필드만 None 이 내려갈 수 있다.
    """

    status: str = "OK"
    message: str = "Onboarding survey received (stub)."
    profile: OnboardingProfileSnapshot
