from datetime import datetime, timedelta
from typing import List, Optional, Literal
from uuid import uuid4

from fastapi import FastAPI
from pydantic import BaseModel

# 이 파일은 예시용 "통합 봄이 백엔드" 코드입니다.
# 실제 LLM/감정분석/DB는 프로젝트에 맞게 교체하세요.

app = FastAPI(title="Bomi Backend Example")

# -----------------------
# 데이터 모델 (임시 인메모리)
# -----------------------

class ConversationLog(BaseModel):
    id: str
    user_id: str
    conversation_id: str
    turn_index: int
    created_at: datetime
    user_text: str
    assistant_text: str
    emotion: str
    emotion_score: float

LOGS: List[ConversationLog] = []


# -----------------------
# 요청/응답 모델
# -----------------------

class BomiRequest(BaseModel):
    user_id: str
    user_text: str
    source: Literal["voice", "text"] = "text"
    voice_enabled: bool = True
    conversation_id: Optional[str] = None   # 2-1-1 버튼 누를 때 다시 넘겨주는 값


class BomiReply(BaseModel):
    conversation_id: str
    turn_index: int
    reply_text: str
    emotion: str
    emotion_score: float
    audio_url: Optional[str] = None


# -----------------------
# 더미 감정 분석 & LLM (여기만 너네 3-4 / 3-8 코드로 교체)
# -----------------------

def dummy_analyze_emotion(text: str) -> tuple[str, float]:
    # TODO: 3-4 감정 분석 엔진 결과로 교체
    if "슬프" in text or "우울" in text:
        return "sad", 0.8
    return "neutral", 0.5


def dummy_generate_bomi_reply(text: str, emotion: str) -> str:
    # TODO: 3-8 LLM 엔진 호출 코드로 교체
    if emotion == "sad":
        return "오늘 말씀해 주신 것만으로도 정말 큰 용기 내신 거예요. 많이 힘드셨죠."
    return "말씀 잘 들었어요. 조금 더 자세히 이야기해 주셔도 괜찮아요."


# -----------------------
# TTS 호출 (지금 우리가 만든 3-7 서버 재사용)
# -----------------------

from tts_model import synthesize_to_wav

def synthesize_reply_audio(reply_text: str, emotion: str) -> str:
    wav_path = synthesize_to_wav(
        text=reply_text,
        speed=None,
        tone=emotion,   # sad/happy/angry/... 프리셋 적용
        engine="melo",
    )
    # 프론트/리버스 프록시에 맞게 URL 조정
    return f"/{wav_path}"


# -----------------------
# 1) /api/bomi/reply  (초기 진입 + 2-1-1 버튼 모두 이거 호출)
# -----------------------

@app.post("/api/bomi/reply", response_model=BomiReply)
def bomi_reply(req: BomiRequest):
    # 1. conversation_id 없으면 새로 생성 (2-1-1 순환 대비)
    conversation_id = req.conversation_id or uuid4().hex

    # 2. 이번 턴 번호 계산
    same_conv_logs = [log for log in LOGS if log.conversation_id == conversation_id]
    turn_index = len(same_conv_logs) + 1

    # 3. 감정 분석 (3-4)
    emotion, score = dummy_analyze_emotion(req.user_text)

    # 4. LLM 응답 생성 (3-8)
    reply_text = dummy_generate_bomi_reply(req.user_text, emotion)

    # 5. TTS (3-7) - 음성 응답을 원하는 경우만
    audio_url = None
    if req.voice_enabled:
        audio_url = synthesize_reply_audio(reply_text, emotion)

    # 6. 로그 저장 (리포트용)
    log = ConversationLog(
        id=uuid4().hex,
        user_id=req.user_id,
        conversation_id=conversation_id,
        turn_index=turn_index,
        created_at=datetime.utcnow(),
        user_text=req.user_text,
        assistant_text=reply_text,
        emotion=emotion,
        emotion_score=score,
    )
    LOGS.append(log)

    return BomiReply(
        conversation_id=conversation_id,
        turn_index=turn_index,
        reply_text=reply_text,
        emotion=emotion,
        emotion_score=score,
        audio_url=audio_url,
    )


# -----------------------
# 2) 리포트용 API (마이페이지 / 가족공유 공통 기반)
# -----------------------

class ReportPoint(BaseModel):
    date: datetime
    dominant_emotion: str      # 하루의 대표 감정
    counts: dict               # 감정별 횟수


class ReportResponse(BaseModel):
    user_id: str
    start_date: datetime
    end_date: datetime
    points: list[ReportPoint]


def _aggregate_logs(user_id: str, days: int) -> ReportResponse:
    end = datetime.utcnow()
    start = end - timedelta(days=days)

    logs = [
        l for l in LOGS
        if l.user_id == user_id and start <= l.created_at <= end
    ]

    buckets: dict[str, list[ConversationLog]] = {}
    for log in logs:
        day_key = log.created_at.date().isoformat()
        buckets.setdefault(day_key, []).append(log)

    points: list[ReportPoint] = []

    for day_key, day_logs in sorted(buckets.items()):
        counts: dict[str, int] = {}
        for log in day_logs:
            counts[log.emotion] = counts.get(log.emotion, 0) + 1

        dominant = max(counts.items(), key=lambda x: x[1])[0] if counts else "neutral"
        day_dt = datetime.fromisoformat(day_key)

        points.append(ReportPoint(
            date=day_dt,
            dominant_emotion=dominant,
            counts=counts,
        ))

    return ReportResponse(
        user_id=user_id,
        start_date=start,
        end_date=end,
        points=points,
    )


@app.get("/api/report/mypage", response_model=ReportResponse)
def mypage_report(user_id: str, days: int = 7):
    """마이페이지용 일/주간 리포트 (기본 7일)."""
    return _aggregate_logs(user_id, days)


@app.get("/api/report/family", response_model=ReportResponse)
def family_report(user_id: str, days: int = 7):
    """가족/보호자 공유용 리포트.

    현재는 mypage와 동일 구조를 쓰고,
    나중에 민감한 내용 필터링 정책이 생기면 여기서 따로 적용.
    """
    return _aggregate_logs(user_id, days)
