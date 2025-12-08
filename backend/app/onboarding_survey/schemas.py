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
