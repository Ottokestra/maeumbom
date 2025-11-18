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
    """
    STT WebSocket 엔드포인트
    실시간 오디오 스트리밍을 받아 텍스트로 변환
    """
    await websocket.accept()
    
    try:
        engine = get_stt_engine()
        
        # 클라이언트에게 준비 완료 메시지 전송
        await websocket.send_json({"status": "ready", "message": "STT 엔진 준비 완료"})
        
        # Silero VAD는 16000Hz에서 512 샘플씩 처리
        vad_chunk_size = 512
        
        while True:
            # 오디오 데이터 수신 (바이너리 또는 JSON)
            data = await websocket.receive()
            
            if "bytes" in data:
                # 바이너리 오디오 데이터
                audio_bytes = data["bytes"]
                
                # numpy 배열로 변환
                audio_chunk = np.frombuffer(audio_bytes, dtype=np.float32)
                
                # 큰 청크를 512 샘플씩 나눠서 VAD 처리
                for i in range(0, len(audio_chunk), vad_chunk_size):
                    sub_chunk = audio_chunk[i:i+vad_chunk_size]
                    
                    # 512 샘플이 안 되면 패딩 (또는 스킵)
                    if len(sub_chunk) < vad_chunk_size:
                        # 남은 샘플이 부족하면 0으로 패딩
                        sub_chunk = np.pad(sub_chunk, (0, vad_chunk_size - len(sub_chunk)), mode='constant')
                    
                    # VAD 처리
                    is_speech_end, speech_audio, is_short_pause = engine.vad.process_chunk(sub_chunk)
                    
                    if is_speech_end and speech_audio is not None:
                        # 음성 인식 실행
                        transcript, quality = engine.whisper.transcribe(speech_audio, callback=None)
                        
                        # 결과 전송
                        if transcript and quality in ["success", "medium"]:
                            await websocket.send_json({
                                "text": transcript,
                                "quality": quality
                            })
                        
                        # VAD 리셋
                        engine.vad.reset()
            
            elif "text" in data:
                # 텍스트 명령어 (예: reset)
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

