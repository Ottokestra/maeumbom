from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel


class ReportChatMessage(BaseModel):
    id: str
    role: Literal["user", "assistant"]
    character_id: Optional[str] = None  # "worried-peach", "happy-star" 등
    character_label: Optional[str] = None  # '걱정이 복숭아' 처럼 사용자에게 보여줄 이름
    text: str
    created_at: datetime


class StartChatRequest(BaseModel):
    user_id: int


class SendMessageRequest(BaseModel):
    text: str


class ReportChatSession(BaseModel):
    session_id: str
    user_id: int
    messages: List[ReportChatMessage]
