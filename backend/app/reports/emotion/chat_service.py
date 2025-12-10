from __future__ import annotations

import os
from typing import Dict, List
from uuid import uuid4

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI

from .chat_schemas import ReportChatMessage, ReportChatSession
from .schemas import WeeklyEmotionReport
from .service import get_weekly_emotion_report


_sessions: Dict[str, ReportChatSession] = {}
_llm_client: ChatOpenAI | None = None


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


def _get_llm_client() -> ChatOpenAI:
    global _llm_client

    if _llm_client is not None:
        return _llm_client

    model_name = os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini")
    api_key = os.getenv("OPENAI_API_KEY")

    if not api_key:
        raise ValueError("OPENAI_API_KEY 환경변수가 설정되지 않았습니다.")

    _llm_client = ChatOpenAI(
        model=model_name,
        temperature=0.6,
        api_key=api_key,
    )
    return _llm_client


def _build_report_chat_messages(
    *,
    report: WeeklyEmotionReport,
    history: List[ReportChatMessage],
    user_text: str,
    character_label: str,
) -> List[SystemMessage | AIMessage | HumanMessage]:
    system_prompt = (
        f"너는 감정 케어 캐릭터 '{character_label}'야. "
        "사용자의 한 주 감정 리포트를 바탕으로 짧고 따뜻한 한국어로 대답해. "
        "1~3문장 정도로, 너무 장황하지 않게 이야기해. "
        "상담사가 아니라 따뜻한 친구처럼 공감해 주고, 가벼운 제안만 해줘."
    )

    report_context = (
        f"이번 주 주요 감정: {report.dominant_emotion}\n"
        f"요약: {report.summary_text}"
    )

    messages: List[SystemMessage | AIMessage | HumanMessage] = [
        SystemMessage(content=system_prompt),
        SystemMessage(content=report_context),
    ]

    for m in history[-6:]:
        if m.role == "assistant":
            messages.append(AIMessage(content=m.text))
        else:
            messages.append(HumanMessage(content=m.text))

    messages.append(HumanMessage(content=user_text))
    return messages


def _call_report_llm(messages: List[SystemMessage | AIMessage | HumanMessage]) -> str:
    client = _get_llm_client()
    response = client.invoke(messages)
    return response.content


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

    history = list(session.messages)

    user_message = ReportChatMessage(
        id=_build_message_id(session),
        role="user",
        text=text,
    )
    session.messages.append(user_message)

    report = get_weekly_emotion_report(user_id=session.user_id)
    character_id = session.messages[0].character_id or "happy-star"
    character_label = report.character_bubble.character_name or "봄이"

    messages = _build_report_chat_messages(
        report=report,
        history=history,
        user_text=text,
        character_label=character_label,
    )

    try:
        reply_text = _call_report_llm(messages)
    except Exception:
        reply_text = (
            "말해줘서 고마워. 이번 주에도 정말 열심히 보낸 것 같아! "
            "조금 더 나누고 싶은 이야기가 있다면 이어서 말해줘."
        )

    assistant_reply = ReportChatMessage(
        id=_build_message_id(session),
        role="assistant",
        text=reply_text,
        character_id=character_id,
        character_label=character_label,
    )
    session.messages.append(assistant_reply)

    return session
