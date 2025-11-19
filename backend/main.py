"""
팀 프로젝트 메인 FastAPI 애플리케이션
"""
import os
import sys
from pathlib import Path
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from typing import List
from fastapi.middleware.cors import CORSMiddleware
import json
from pathlib import Path

import numpy as np
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse



# 하이픈이 있는 폴더명을 import하기 위해 경로 추가
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

# ✅ TTS 모듈이 있는 폴더를 파이썬 경로에 추가
tts_path = backend_path / "engine" / "text-to-speech"
sys.path.insert(0, str(tts_path))

# =========================
# Emotion Analysis 라우터 로딩 (옵션)
# =========================

import importlib.util

emotion_router = None
try:
    emotion_analysis_path = backend_path / "engine" / "emotion-analysis" / "api" / "routes.py"
    spec = importlib.util.spec_from_file_location("emotion_routes", emotion_analysis_path)
    emotion_routes = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(emotion_routes)
    emotion_router = emotion_routes.router
    print("[INFO] Emotion analysis router loaded successfully.")
except Exception as e:
    # 여기서 막혀도 서버 전체는 계속 뜨도록
    print("[WARN] Emotion analysis module load failed:", e)
    emotion_router = None

# =========================
# TTS 모델 import
# =========================

from tts_model import synthesize_to_wav


# routine_recommend 엔진과 모델 import
from engine.routine_recommend.engine import RoutineRecommendFromEmotionEngine
from engine.routine_recommend.models.schemas import EmotionAnalysisResult, RoutineRecommendationItem

# Create FastAPI app
app = FastAPI(
    title="Team Project API",
    description="팀 프로젝트 통합 API 서비스 (Emotion + STT + TTS)",
    version="1.0.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],  # React dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include emotion analysis routes
app.include_router(emotion_router, prefix="/emotion/api", tags=["emotion"])
# 하위 호환성을 위해 /api 경로도 지원
app.include_router(emotion_router, prefix="/api", tags=["emotion"])




# LangChain Agent routes
from fastapi import HTTPException
from pydantic import BaseModel

class AgentTextRequest(BaseModel):
    user_text: str
    session_id: str = None

class AgentAudioRequest(BaseModel):
    audio_bytes: bytes
    session_id: str = None

@app.post("/api/agent/text")
async def agent_text_endpoint(request: AgentTextRequest):
    """LangChain Agent - 텍스트 입력"""
    try:
        from engine.langchain_agent import run_ai_bomi_from_text
        result = run_ai_bomi_from_text(
            user_text=request.user_text,
            session_id=request.session_id
        )
        return result
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/agent/audio")
async def agent_audio_endpoint(request: AgentAudioRequest):
    """LangChain Agent - 음성 입력"""
    try:
        from engine.langchain_agent import run_ai_bomi_from_audio
        result = run_ai_bomi_from_audio(
            audio_bytes=request.audio_bytes,
            session_id=request.session_id
        )
        return result
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/agent/memory/{session_id}")
async def get_agent_memory(session_id: str, limit: int = None):
    """LangChain Agent - 특정 세션의 대화 히스토리 조회"""
    try:
        from engine.langchain_agent import get_conversation_store
        store = get_conversation_store()
        history = store.get_history(session_id, limit=limit)
        return {
            "session_id": session_id,
            "message_count": len(history),
            "messages": history
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/agent/sessions")
async def get_all_agent_sessions():
    """LangChain Agent - 모든 세션 정보 조회"""
    try:
        from engine.langchain_agent import get_all_sessions
        sessions = get_all_sessions()
        return {
            "session_count": len(sessions),
            "sessions": sessions
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

# STT 엔진 초기화 (전역)
stt_engine = None

def get_stt_engine():
    """STT 엔진 싱글톤"""
    global stt_engine
    if stt_engine is None:
        import importlib.util
        stt_engine_path = backend_path / "engine" / "speech-to-text" / "faster_whisper" / "stt_engine.py"
        spec = importlib.util.spec_from_file_location("stt_engine", stt_engine_path)
        stt_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(stt_module)
        
        # config.yaml 경로
        config_path = backend_path / "engine" / "speech-to-text" / "faster_whisper" / "config.yaml"
        stt_engine = stt_module.MaumBomSTT(str(config_path))
    return stt_engine


@app.websocket("/stt/stream")
async def stt_websocket(websocket: WebSocket):
    await websocket.accept()
    
    try:
        engine = get_stt_engine()
        await websocket.send_json({"status": "ready", "message": "STT 엔진 준비 완료"})
        
        while True:
            data = await websocket.receive()
            
            if "bytes" in data:
                audio_bytes = data["bytes"]
                audio_chunk = np.frombuffer(audio_bytes, dtype=np.float32)

                # 512 샘플이 맞는지 확인 (선택적)
                if len(audio_chunk) != 512:
                    continue

                # VAD 처리
                is_speech_end, speech_audio, is_short_pause = engine.vad.process_chunk(audio_chunk)
                
                if is_speech_end and speech_audio is not None:
                    transcript, quality = engine.whisper.transcribe(speech_audio, callback=None)
                    
                    # 모든 품질에 대해 결과 전송 (quality가 안좋으면 text는 null)
                    response = {
                        "text": transcript if quality in ["success", "medium"] else None,
                        "quality": quality
                    }
                    await websocket.send_json(response)

                    engine.vad.reset()

            elif "text" in data:
                command = data["text"]
                if command == "reset":
                    engine.vad.reset()
                    await websocket.send_json({"status": "reset", "message": "VAD 리셋 완료"})
                    
    except WebSocketDisconnect:
        print("STT WebSocket 연결 종료")
    except Exception as e:
        print(f"STT WebSocket 오류: {e}")
        import traceback
        traceback.print_exc()
        await websocket.send_json({"error": str(e)})
        await websocket.close()


@app.post(
    "/api/engine/routine-from-emotion",
    response_model=List[RoutineRecommendationItem],
    tags=["routine-recommend"],
)
async def recommend_routine_from_emotion(emotion: EmotionAnalysisResult):
    """
    감정 분석 결과를 기반으로 루틴을 추천합니다.

    프로세스:
    1. RAG를 사용하여 ChromaDB에서 관련 루틴 후보 검색
    2. GPT-4o-mini를 사용하여 최종 추천 루틴 선택 및 설명 생성

    Args:
        emotion: 감정 분석 결과 (EmotionAnalysisResult)

    Returns:
        추천된 루틴 리스트 (reason, ui_message 포함)
    """
    try:
        engine = RoutineRecommendFromEmotionEngine()
        recommendations = engine.recommend(emotion)
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"루틴 추천 실패: {str(e)}")



# =========================
# TTS (3-7 텍스트 -> 음성)
# =========================

@app.get("/health")
async def health():
    """전체 서비스 헬스 체크 (TTS 기준)"""
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
    speed = payload.get("speed")                # 없으면 None
    tone = payload.get("tone", "senior_calm")   # 기본 톤
    engine = payload.get("engine", "melo")      # 현재는 'melo'만 사용

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
        import sys as _sys, traceback as _traceback

        print("[TTS ERROR]", e, file=_sys.stderr)
        _traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"TTS error: {e}")

    # 5) wav 파일 반환
    return FileResponse(
        path=str(wav_path),
        filename=wav_path.name,
        media_type="audio/wav",
    )


# =========================
# Root 엔드포인트
# =========================

@app.get("/")
async def root():
    """Root endpoint"""
    modules = {
        "stt": "/stt/stream",
        "tts": "/api/tts",
    }
    if emotion_router is not None:
        modules["emotion_analysis"] = "/emotion/api"

    return {
        "message": "Team Project API",
        "version": "1.0.0",
        "docs": "/docs",
        "modules": {
            "emotion_analysis": "/emotion/api",
            "stt": "/stt/stream"
        }
    }


if __name__ == "__main__":
    import uvicorn
    print("=" * 50)
    print("팀 프로젝트 API 서버 시작")
    print("=" * 50)
    print("\n서버 정보:")
    print("  - URL: http://localhost:8000")
    print("  - API 문서: http://localhost:8000/docs")
    print("  - 감정 분석: http://localhost:8000/emotion/api")
    print("  - STT 스트리밍: ws://localhost:8000/stt/stream")
    print("  - LangChain Agent: http://localhost:8000/api/agent")
    print("  - Agent 테스트: http://localhost:8000/agent.html")
    print("  - TTS: POST http://localhost:8000/api/tts")
    print("\n최초 실행 시:")
    print("  1. 서버 시작 후 http://localhost:8000/docs 접속")
    print("  2. POST /emotion/api/init 엔드포인트 실행하여 벡터 DB 초기화")
    print("\n" + "=" * 50 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)

