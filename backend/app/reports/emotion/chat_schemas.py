from typing import List, Optional

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
