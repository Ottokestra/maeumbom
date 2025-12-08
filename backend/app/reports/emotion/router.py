from fastapi import APIRouter, HTTPException

from .chat_schemas import ReportChatSession, SendMessageRequest, StartChatRequest
from .chat_service import append_user_message, get_report_chat_session, start_report_chat
from .schemas import WeeklyEmotionReport
from .service import get_weekly_emotion_report

router = APIRouter(prefix="/api/reports/emotion", tags=["emotion-reports"])


@router.get("/weekly", response_model=WeeklyEmotionReport)
def read_weekly_emotion_report(user_id: int = 1):
    """
    주간 감정 리포트 목 API.
    - 현재는 user_id=1 고정 / 쿼리 파라미터로 받아서 사용
    - 나중에 인증 붙이면 토큰에서 user_id를 읽도록 수정 예정
    """
    return get_weekly_emotion_report(user_id=user_id)


@router.post("/weekly/chat/start", response_model=ReportChatSession)
def start_weekly_report_chat(payload: StartChatRequest):
    """리포트 기반 대화 세션을 시작하고 첫 멘트를 반환한다."""

    return start_report_chat(user_id=payload.user_id)


@router.get("/weekly/chat/{session_id}", response_model=ReportChatSession)
def read_report_chat_session(session_id: str):
    try:
        return get_report_chat_session(session_id)
    except KeyError as exc:  # pragma: no cover - 단순 예외 변환
        raise HTTPException(status_code=404, detail="세션을 찾을 수 없습니다.") from exc


@router.post("/weekly/chat/{session_id}/messages", response_model=ReportChatSession)
def send_report_chat_message(session_id: str, payload: SendMessageRequest):
    try:
        return append_user_message(session_id=session_id, text=payload.text)
    except KeyError as exc:  # pragma: no cover - 단순 예외 변환
        raise HTTPException(status_code=404, detail="세션을 찾을 수 없습니다.") from exc
