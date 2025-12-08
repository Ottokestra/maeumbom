from fastapi import APIRouter, HTTPException

from .chat_schemas import (
    StartChatRequest,
    SendMessageRequest,
    ReportChatSession,
)
from .chat_service import (
    start_report_chat,
    get_report_chat_session,
    append_user_message,
)

router = APIRouter(
    prefix="/api/reports/emotion/weekly/chat",
    tags=["emotion-report-chat"],
)


@router.post("/", response_model=ReportChatSession)
def start_chat(req: StartChatRequest):
    """
    리포트 기반 대화 세션 시작.
    - body: { "user_id": 1 }
    - response: session_id + 첫 assistant 메시지 포함
    """
    return start_report_chat(user_id=req.user_id)


@router.get("/{session_id}", response_model=ReportChatSession)
def read_chat(session_id: str):
    """
    특정 세션 상태 조회.
    """
    try:
        return get_report_chat_session(session_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="session not found")


@router.post("/{session_id}/messages", response_model=ReportChatSession)
def send_message(session_id: str, req: SendMessageRequest):
    """
    유저 메시지 추가 + assistant 응답 생성 후 전체 세션 반환.
    """
    try:
        return append_user_message(session_id, text=req.text)
    except KeyError:
        raise HTTPException(status_code=404, detail="session not found")
