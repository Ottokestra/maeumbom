from __future__ import annotations

from typing import Dict
from uuid import uuid4

from .chat_schemas import ReportChatMessage, ReportChatSession


_sessions: Dict[str, ReportChatSession] = {}


def _build_message_id(session: ReportChatSession) -> str:
    return f"m{len(session.messages) + 1}"


def _make_intro_message() -> ReportChatMessage:
    return ReportChatMessage(
        id="m1",
        role="assistant",
        text=(
            "이번 주 감정 리포트를 바탕으로 이야기를 시작해볼게요. "
            "편하게 이번 주를 보낸 소감이나 기억에 남는 순간을 알려줘!"
        ),
        character_id="happy-star",
        character_label="봄이",
    )


def _build_assistant_reply(text: str) -> ReportChatMessage:
    return ReportChatMessage(
        id="",
        role="assistant",
        text=(
            "말해줘서 고마워. "
            "이번 주에도 정말 열심히 보낸 것 같아! \n"
            "조금 더 나누고 싶은 이야기가 있다면 이어서 말해줘."
        ),
        character_id="happy-star",
        character_label="봄이",
    )


def start_report_chat(user_id: int) -> ReportChatSession:
    session_id = str(uuid4())
    intro = _make_intro_message()
    session = ReportChatSession(session_id=session_id, user_id=user_id, messages=[intro])
    _sessions[session_id] = session
    return session


def get_report_chat_session(session_id: str) -> ReportChatSession:
    if session_id not in _sessions:
        raise KeyError("session not found")
    return _sessions[session_id]


def append_user_message(session_id: str, text: str) -> ReportChatSession:
    session = get_report_chat_session(session_id)

    user_message = ReportChatMessage(
        id=_build_message_id(session),
        role="user",
        text=text,
    )
    session.messages.append(user_message)

    assistant_reply = _build_assistant_reply(text)
    assistant_reply.id = _build_message_id(session)
    session.messages.append(assistant_reply)

    return session
