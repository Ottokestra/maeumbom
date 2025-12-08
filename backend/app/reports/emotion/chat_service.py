import uuid
from datetime import datetime
from typing import Dict

from .chat_schemas import (
    ReportChatSession,
    ReportChatMessage,
)
from .schemas import WeeklyEmotionReport
from .service import get_weekly_emotion_report

# 인메모리 세션 저장소 (데모용)
_SESSIONS: Dict[str, ReportChatSession] = {}


# 리포트의 dominant_emotion / 요약을 기반으로 캐릭터 선택 규칙
def _pick_character_from_report(report: WeeklyEmotionReport) -> tuple[str, str]:
    """
    dominant_emotion, summary_text 등을 보고 캐릭터 id/label을 고른다.
    실제 캐릭터 이미지는 프론트에서 id를 기반으로 매핑해서 사용.
    """
    dom = (report.dominant_emotion or "").lower()

    # 아주 단순한 규칙 기반 매핑
    if "걱정" in dom or "불안" in dom:
        return "worried-cloud", "걱정이 구름이"
    if "우울" in dom or "슬픔" in dom:
        return "sad-rock", "우울한 돌멩이"
    if "분노" in dom or "화" in dom:
        return "angry-fire", "불꽃 화난이"
    if "피로" in dom or "피곤" in dom:
        return "tired-sloth", "피곤한 나무늘보"
    # 기본값: 밝은 캐릭터
    return "happy-star", "반짝이 별이"


def start_report_chat(user_id: int) -> ReportChatSession:
    """
    리포트 기반 대화 세션 시작.
    - WeeklyEmotionReport를 불러와서
      첫 assistant 메시지를 생성.
    """
    report = get_weekly_emotion_report(user_id=user_id)
    character_id, character_label = _pick_character_from_report(report)

    session_id = uuid.uuid4().hex

    first_msg_text = (
        f"이번 주 리포트를 보니까, 전체적으로는 '{report.dominant_emotion}' 감정이 많이 느껴졌어.\n"
        "어떤 하루가 특히 기억에 남는지, 혹은 지금 제일 마음에 남는 일이 있다면 얘기해줄래?"
    )

    first_message = ReportChatMessage(
        id=uuid.uuid4().hex,
        role="assistant",
        character_id=character_id,
        character_label=character_label,
        text=first_msg_text,
        created_at=datetime.utcnow(),
    )

    session = ReportChatSession(
        session_id=session_id,
        user_id=user_id,
        messages=[first_message],
    )

    _SESSIONS[session_id] = session
    return session


def get_report_chat_session(session_id: str) -> ReportChatSession:
    session = _SESSIONS.get(session_id)
    if not session:
        raise KeyError("session not found")
    return session


def append_user_message(session_id: str, text: str) -> ReportChatSession:
    """
    유저 메시지를 추가하고, 간단한 규칙 기반 assistant 답변을 하나 생성해서 같이 저장.
    """
    session = get_report_chat_session(session_id)

    user_msg = ReportChatMessage(
        id=uuid.uuid4().hex,
        role="user",
        character_id=None,
        character_label=None,
        text=text,
        created_at=datetime.utcnow(),
    )
    session.messages.append(user_msg)

    # report 재조회 (실서비스에서는 캐시/저장된 값을 쓰도록 개선 가능)
    report = get_weekly_emotion_report(user_id=session.user_id)
    character_id, character_label = _pick_character_from_report(report)

    # 아주 단순한 규칙: 특정 키워드에 따라 코멘트 달기
    lower = text.lower()
    if "힘들" in lower or "버거워" in lower:
        reply_body = (
            "이야기만 들어도 정말 버거웠을 것 같아.\n"
            "그 상황에서 여기까지 버텨준 것만으로도 이미 대단해. "
            "이번 주 중에 스스로를 위해 쉬어주고 싶은 날이 있다면 언제야?"
        )
    elif "기뻤" in lower or "좋았" in lower:
        reply_body = (
            "그 순간이 많이 소중했나 보다 😊\n"
            "그때 네가 느꼈던 감정이나 생각을 조금 더 들려줄래?"
        )
    else:
        reply_body = (
            "말해줘서 고마워. 네가 느낀 감정을 정리하는 데 내가 같이 옆자리에 앉아있을게.\n"
            "조금 더 자세히 나눠보고 싶은 상황이 있다면 편하게 이어서 얘기해줘."
        )

    assistant_msg = ReportChatMessage(
        id=uuid.uuid4().hex,
        role="assistant",
        character_id=character_id,
        character_label=character_label,
        text=reply_body,
        created_at=datetime.utcnow(),
    )
    session.messages.append(assistant_msg)

    _SESSIONS[session_id] = session
    return session
