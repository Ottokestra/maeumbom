# tts.py  (원래 main.py 역할: 3-7 텍스트 → 음성 변환 엔진)
import json

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from tts_model import synthesize_to_wav

# 3-7 TTS 전용 FastAPI 앱
app = FastAPI(title="Bomi TTS Service (3-7)")

# CORS (프론트 어디서든 호출 가능하게)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/api/tts")
async def tts(request: Request):
    """
    텍스트 -> 음성 변환 API (3-7)

    요청 JSON 예시:
    {
      "text": "오늘 하루 많이 힘드셨죠.",
      "speed": 1.0,                # 선택 (없으면 프리셋 기본값 사용)
      "tone": "sad",               # sad / happy / angry / neutral / senior_calm ...
      "engine": "melo"             # 현재는 'melo'만 사용
    }

    응답: audio/wav 파일 스트림
    """
    raw = await request.body()

    # 1) 인코딩 처리 (UTF-8 우선, 안 되면 CP949 시도)
    try:
        body_str = raw.decode("utf-8")
    except UnicodeDecodeError:
        body_str = raw.decode("cp949", errors="replace")

    # 2) JSON 파싱
    try:
        payload = json.loads(body_str)
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"json parse error: {e}; body={body_str!r}",
        )

    # 3) 파라미터 추출
    text = payload.get("text")
    speed = payload.get("speed")              # 없으면 None
    tone = payload.get("tone", "senior_calm") # 기본 톤
    engine = payload.get("engine", "melo")    # 현재는 'melo'만 사용

    if not text or not str(text).strip():
        raise HTTPException(status_code=400, detail="text is required")

    # 4) 합성
    try:
        wav_path = synthesize_to_wav(
            text=str(text),
            speed=speed,
            tone=str(tone),
            engine=str(engine),
        )
    except Exception as e:
        import sys, traceback
        print("[TTS ERROR]", e, file=sys.stderr)
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"TTS error: {e}")

    # 5) wav 파일 반환
    return FileResponse(
        path=str(wav_path),
        filename=wav_path.name,
        media_type="audio/wav",
    )
