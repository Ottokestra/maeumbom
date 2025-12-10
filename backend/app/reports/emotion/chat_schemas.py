from typing import List, Literal, Optional

from pydantic import BaseModel


class StartChatRequest(BaseModel):
    user_id: int


class SendMessageRequest(BaseModel):
    text: str


class ReportChatMessage(BaseModel):
    id: str
    role: str  # "assistant" | "user"
    text: str
    character_id: Optional[str] = None
    character_label: Optional[str] = None


class ReportChatSession(BaseModel):
    session_id: str
    user_id: int
    messages: List[ReportChatMessage]


# 캐릭터 말풍선 감정 리포트
BubbleRole = Literal["character", "user"]


class EmotionReportBubble(BaseModel):
    role: BubbleRole  # "character" | "user"
    text: str


class EmotionReportCharacterMeta(BaseModel):
    key: str  # ex) "worried_fox"
    display_name: str  # ex) "걱정이 폭송이"
    mood: str  # ex) "worry", "angry", "calm"


class EmotionReportChatResponse(BaseModel):
    period: str  # "weekly" 등
    headline: str  # ex) "이번 주의 너는 '걱정이 폭송이'"
    character: EmotionReportCharacterMeta
    bubbles: List[EmotionReportBubble]
    summary_stats: Optional[dict] = None
