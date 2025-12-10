from fastapi import APIRouter, HTTPException

from .chat_schemas import (
    EmotionReportChatResponse,
    StartChatRequest,
    SendMessageRequest,
    ReportChatSession,
)
from .chat_service import (
    start_report_chat,
    get_report_chat_session,
    append_user_message,
)
from .service import get_weekly_emotion_report
from engine.langchain_agent.agent_v2 import generate_weekly_emotion_report_story

router = APIRouter(
    prefix="/api/reports/emotion/weekly/chat",
    tags=["emotion-report-chat"],
)


@router.get("/", response_model=EmotionReportChatResponse)
def get_weekly_emotion_report_chat(user_id: int = 1):
    """
    기존 주간 감정 요약 데이터를 가져와 캐릭터 말풍선 리포트로 변환한다.

    - 현재는 user_id=1 고정 / 쿼리 파라미터로 받아서 사용
    - 나중에 인증 붙이면 토큰에서 user_id를 읽도록 수정 예정
    """

    weekly_summary = get_weekly_emotion_report(user_id=user_id)
    if weekly_summary is None:
        raise HTTPException(status_code=404, detail="No weekly emotion summary found")

    story_dict = generate_weekly_emotion_report_story(weekly_summary)
    return EmotionReportChatResponse(**story_dict)


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
