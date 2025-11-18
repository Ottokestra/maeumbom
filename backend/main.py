"""
팀 프로젝트 메인 FastAPI 애플리케이션
"""
import sys
from pathlib import Path
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import json
import numpy as np

# 하이픈이 있는 폴더명을 import하기 위해 경로 추가
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

# emotion-analysis 폴더를 import하기 위해 importlib 사용
import importlib.util
emotion_analysis_path = backend_path / "engine" / "emotion-analysis" / "api" / "routes.py"
spec = importlib.util.spec_from_file_location("emotion_routes", emotion_analysis_path)
emotion_routes = importlib.util.module_from_spec(spec)
spec.loader.exec_module(emotion_routes)
emotion_router = emotion_routes.router

# Create FastAPI app
app = FastAPI(
    title="Team Project API",
    description="팀 프로젝트 통합 API 서비스",
    version="1.0.0"
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
                
                # 바로 VAD 처리 (for 루프 불필요!)
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

@app.get("/")
async def root():
    """Root endpoint"""
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
    print("\n최초 실행 시:")
    print("  1. 서버 시작 후 http://localhost:8000/docs 접속")
    print("  2. POST /emotion/api/init 엔드포인트 실행하여 벡터 DB 초기화")
    print("\n" + "=" * 50 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)

