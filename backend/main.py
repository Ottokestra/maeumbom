"""
팀 프로젝트 메인 FastAPI 애플리케이션
"""
import os
import sys
from pathlib import Path
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Request
from typing import List
from fastapi.middleware.cors import CORSMiddleware
import json
from pathlib import Path

import numpy as np
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from service.weather.routes import router as weather_router


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

# =========================p
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
if emotion_router is not None:
    app.include_router(emotion_router, prefix="/emotion/api", tags=["emotion"])
    # 하위 호환성을 위해 /api 경로도 지원
    app.include_router(emotion_router, prefix="/api", tags=["emotion"])

# =========================
# Daily Mood Check Service
# =========================
try:
    from service.weather.routes import router as weather_router
    app.include_router(weather_router)
    print("[INFO] Weather router loaded successfully.")
except Exception as e:
    import traceback
    print(f"[WARN] Weather module load failed: {e}")
    traceback.print_exc()
    
try:
    daily_mood_check_path = backend_path / "service" / "daily_mood_check" / "routes.py"
    if not daily_mood_check_path.exists():
        print(f"[WARN] Daily mood check routes file not found: {daily_mood_check_path}")
    else:
        spec = importlib.util.spec_from_file_location("daily_mood_check_routes", daily_mood_check_path)
        daily_mood_check_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(daily_mood_check_module)
        daily_mood_check_router = daily_mood_check_module.router
        app.include_router(daily_mood_check_router, prefix="/api/service/daily-mood-check", tags=["daily-mood-check"])
        print("[INFO] Daily mood check router loaded successfully.")

    # =========================
    # Weather Service
    # =========================
    try:
        app.include_router(
            weather_router,
            prefix="/api/service/weather",
            tags=["weather"]
        )
        print("[INFO] Weather router loaded successfully.")
    except Exception as e:
        print(f"[WARN] Weather router load failed: {e}")
        
        
except Exception as e:
    import traceback
    print(f"[WARN] Daily mood check module load failed: {e}")
    traceback.print_exc()

# =========================
# Authentication (Google OAuth + JWT)
# =========================
try:
    from app.auth import router as auth_router
    from app.auth.database import init_db
    
    # Initialize database tables
    init_db()
    
    # Include auth router
    app.include_router(auth_router, prefix="/auth", tags=["authentication"])
    print("[INFO] Authentication router loaded successfully.")
except Exception as e:
    import traceback
    print(f"[WARN] Authentication module load failed: {e}")
    traceback.print_exc()




# LangChain Agent routes
from fastapi import HTTPException
from pydantic import BaseModel
from typing import Optional

class AgentTextRequest(BaseModel):
    user_text: str
    session_id: Optional[str] = None
    stt_quality: Optional[str] = None  # "success" | "medium" | "low_quality" | "no_speech" | None

class AgentAudioRequest(BaseModel):
    audio_bytes: bytes
    session_id: Optional[str] = None

@app.post("/api/agent/text")
async def agent_text_endpoint(request: AgentTextRequest):
    """LangChain Agent - 텍스트 입력 (STT Quality 전처리 포함)"""
    try:
        from engine.langchain_agent import run_ai_bomi_from_text
        
        # STT Quality 전처리
        if request.stt_quality == "no_speech":
            return {
                "reply_text": "음성이 감지되지 않았어요. 다시 말씀해주시겠어요?",
                "input_text": request.user_text or "",
                "emotion_result": None,
                "routine_result": None,
                "meta": {
                    "model": os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
                    "used_tools": [],
                    "session_id": request.session_id or "default",
                    "stt_quality": request.stt_quality,
                    "note": "no_speech_detected"
                }
            }
        elif request.stt_quality == "low_quality":
            return {
                "reply_text": "소음이 심해서 잘 들리지 않았어요. 조용한 곳에서 다시 말씀해주시겠어요?",
                "input_text": request.user_text or "",
                "emotion_result": None,
                "routine_result": None,
                "meta": {
                    "model": os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
                    "used_tools": [],
                    "session_id": request.session_id or "default",
                    "stt_quality": request.stt_quality,
                    "note": "low_quality_audio"
                }
            }
        
        # 정상 품질 또는 텍스트 입력인 경우 Agent 실행
        result = run_ai_bomi_from_text(
            user_text=request.user_text,
            session_id=request.session_id,
            stt_quality=request.stt_quality
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
async def get_agent_memory_legacy(session_id: str, limit: int = None):
    """Legacy endpoint for backward compatibility"""
    return await get_agent_session(session_id, limit)

@app.get("/api/agent/sessions/{session_id}")
async def get_agent_session(session_id: str, limit: int = None):
    """LangChain Agent - 특정 세션의 대화 히스토리 및 메타데이터 조회"""
    try:
        from engine.langchain_agent import get_conversation_store
        store = get_conversation_store()
        
        # 히스토리 조회
        history = store.get_history(session_id, limit=limit)
        
        # 메타데이터 조회
        metadata = store.get_session_metadata(session_id)
        
        return {
            "session_id": session_id,
            "metadata": metadata,
            "message_count": len(history),
            "messages": history
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/agent/sessions/{session_id}")
async def delete_agent_session(session_id: str):
    """LangChain Agent - 특정 세션 삭제"""
    try:
        from engine.langchain_agent import get_conversation_store
        store = get_conversation_store()
        
        # 세션 존재 여부 확인 (선택적)
        if session_id not in store._store and session_id not in store._session_metadata:
             raise HTTPException(status_code=404, detail="Session not found")
             
        store.clear_session(session_id)
        return {"status": "success", "message": f"Session {session_id} deleted"}
    except HTTPException:
        raise
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
    engine = None
    
    try:
        # 즉시 연결 확인 메시지 전송
        await websocket.send_json({"status": "connecting", "message": "STT 엔진 초기화 중..."})
        
        # STT 엔진 초기화 (시간이 걸릴 수 있음)
        engine = get_stt_engine()
        
        # 엔진 준비 완료 메시지
        await websocket.send_json({"status": "ready", "message": "STT 엔진 준비 완료"})
        
        while True:
            try:
                data = await websocket.receive()
            except RuntimeError as e:
                # 연결이 이미 끊긴 경우
                if "disconnect" in str(e).lower():
                    print("클라이언트 연결 종료 감지")
                    break
                raise
            
            if "bytes" in data:
                audio_bytes = data["bytes"]
                audio_chunk = np.frombuffer(audio_bytes, dtype=np.float32)

                # 512 샘플이 맞는지 확인 (선택적)
                if len(audio_chunk) != 512:
                    continue

                # VAD 처리
                is_speech_end, speech_audio, is_short_pause = engine.vad.process_chunk(audio_chunk)
                
                # 디버깅: VAD 상태 로그 (100번마다 한 번씩)
                if hasattr(engine.vad, '_debug_counter'):
                    engine.vad._debug_counter = getattr(engine.vad, '_debug_counter', 0) + 1
                else:
                    engine.vad._debug_counter = 1
                
                if engine.vad._debug_counter % 100 == 0:
                    print(f"[STT DEBUG] 청크 처리: speech_end={is_speech_end}, short_pause={is_short_pause}, speech_audio_len={len(speech_audio) if speech_audio is not None else 0}")
                
                if is_speech_end and speech_audio is not None:
                    print(f"[STT] 발화 종료 감지, STT 처리 시작 (오디오 길이: {len(speech_audio)} 샘플)")
                    
                    # 클라이언트에게 처리 중 알림
                    await websocket.send_json({
                        "status": "processing",
                        "message": "듣고 생각하는 중..."
                    })
                    
                    transcript, quality = engine.whisper.transcribe(speech_audio, callback=None)
                    print(f"[STT] STT 결과: text='{transcript}', quality={quality}")
                    
                    # ========================================================================
                    # 🆕 화자 검증 로직 (품질 게이트 + 점진적 프로필 완성)
                    # ========================================================================
                    speaker_id = None
                    if quality in ["success", "medium"]:
                        try:
                            # Speaker Verifier 임포트 (Lazy)
                            stt_config_path = backend_path / "engine" / "speech-to-text" / "faster_whisper" / "config.yaml"
                            import sys
                            sys.path.insert(0, str(backend_path / "engine" / "speech-to-text" / "faster_whisper"))
                            from speaker_verifier import SpeakerVerifier
                            from engine.langchain_agent import get_conversation_store
                            
                            # Verifier 초기화
                            verifier = SpeakerVerifier(config_path=str(stt_config_path))
                            
                            # 현재 오디오에서 임베딩 추출
                            current_embedding = verifier.extract_embedding(speech_audio)
                            
                            if current_embedding is not None:
                                # 기존 프로필 조회
                                store = get_conversation_store()
                                existing_profiles = store._speaker_profiles
                                
                                # 화자 식별
                                speaker_id, similarity = verifier.identify_speaker(
                                    current_embedding, 
                                    existing_profiles
                                )
                                
                                print(f"[Speaker] 화자 식별: {speaker_id} (유사도: {similarity:.3f})")
                                
                                # 프로필 저장/업데이트 로직
                                if speaker_id not in existing_profiles:
                                    # 신규 화자 등록
                                    store.add_speaker_profile(
                                        speaker_id, 
                                        current_embedding, 
                                        quality,
                                        session_id=None
                                    )
                                    print(f"[Speaker] 🆕 신규 등록: {speaker_id}")
                                else:
                                    # 기존 화자 - 품질 비교 후 업데이트 여부 결정
                                    old_quality = existing_profiles[speaker_id]["quality"]
                                    if verifier.should_update_profile(quality, old_quality):
                                        # 점진적 업데이트
                                        old_embedding = existing_profiles[speaker_id]["embedding"]
                                        updated_embedding = verifier.update_embedding(
                                            old_embedding, 
                                            current_embedding,
                                            speaker_id=speaker_id
                                        )
                                        store.update_speaker_embedding(
                                            speaker_id, 
                                            updated_embedding, 
                                            quality
                                        )
                                        print(f"[Speaker] 🔄 프로필 업데이트: {speaker_id}")
                                    else:
                                        print(f"[Speaker] ✓ 기존 사용자: {speaker_id} (업데이트 불필요)")
                                
                                # 디버그 정보 출력
                                all_speaker_ids = store.get_all_speaker_ids()
                                print(f"[Speaker Debug] 현재 등록된 화자: {all_speaker_ids}")
                            else:
                                print(f"[Speaker] ⚠️  임베딩 추출 실패 (오디오 길이 부족 또는 오류)")
                            
                        except Exception as e:
                            print(f"[Speaker] ❌ 화자 검증 오류: {e}")
                            import traceback
                            traceback.print_exc()
                            # 오류가 발생해도 STT 결과는 전송
                    else:
                        print(f"[Speaker] ⚠️  품질 부족으로 화자 검증 skip (quality={quality})")
                    # ========================================================================
                    
                    # 모든 품질에 대해 결과 전송 (quality가 안좋으면 text는 null)
                    response = {
                        "text": transcript if quality in ["success", "medium"] else None,
                        "quality": quality,
                        "speaker_id": speaker_id  # 화자 ID 추가
                    }
                    await websocket.send_json(response)

                    engine.vad.reset()

            elif "text" in data:
                command = data["text"]
                if command == "reset":
                    engine.vad.reset()
                    await websocket.send_json({"status": "reset", "message": "VAD 리셋 완료"})
                elif command == "force_process":
                    # 강제로 현재 버퍼의 오디오를 처리
                    print("[STT] 강제 인식 요청 수신")
                    try:
                        # VAD의 현재 버퍼를 가져와서 처리
                        if hasattr(engine.vad, 'get_current_buffer'):
                            buffered_audio = engine.vad.get_current_buffer()
                            if buffered_audio is not None and len(buffered_audio) > 0:
                                print(f"[STT] 강제 인식 처리 (오디오 길이: {len(buffered_audio)} 샘플)")
                                transcript, quality = engine.whisper.transcribe(buffered_audio, callback=None)
                                response = {
                                    "text": transcript if quality in ["success", "medium"] else None,
                                    "quality": quality
                                }
                                await websocket.send_json(response)
                                engine.vad.reset()
                            else:
                                await websocket.send_json({"error": "처리할 오디오가 없습니다"})
                        else:
                            await websocket.send_json({"error": "강제 인식 기능을 사용할 수 없습니다"})
                    except Exception as e:
                        print(f"[STT] 강제 인식 오류: {e}")
                        import traceback
                        traceback.print_exc()
                        await websocket.send_json({"error": str(e)})
                    
    except WebSocketDisconnect:
        print("STT WebSocket 연결 종료 (WebSocketDisconnect)")
    except Exception as e:
        print(f"STT WebSocket 오류: {e}")
        import traceback
        traceback.print_exc()
        # 연결이 닫혔을 수 있으므로 try-except로 감싸기
        try:
            await websocket.send_json({"error": str(e)})
        except:
            pass  # 이미 닫힌 연결이면 무시
        try:
            await websocket.close()
        except:
            pass  # 이미 닫혀있으면 무시
    finally:
        # 연결 종료 시 VAD 상태 초기화
        if engine is not None:
            try:
                engine.vad.reset()
                print("VAD 상태 초기화 완료")
            except Exception as e:
                print(f"VAD 리셋 오류 (무시): {e}")


@app.websocket("/agent/stream")
async def agent_websocket(websocket: WebSocket):
    """
    통합 STT + Agent WebSocket 엔드포인트
    
    음성 입력을 받아 STT 처리 후 자동으로 Agent 실행
    """
    await websocket.accept()
    stt_engine_instance = None
    session_id = None
    
    try:
        # 초기화 메시지
        await websocket.send_json({
            "type": "status",
            "status": "connecting",
            "message": "STT + Agent 엔진 초기화 중..."
        })
        
        # STT 엔진 초기화
        stt_engine_instance = get_stt_engine()
        
        # 준비 완료
        await websocket.send_json({
            "type": "status",
            "status": "ready",
            "message": "준비 완료. 말씀하세요."
        })
        
        while True:
            try:
                data = await websocket.receive()
            except RuntimeError as e:
                if "disconnect" in str(e).lower():
                    print("[Agent WebSocket] 클라이언트 연결 종료")
                    break
                raise
            
            # JSON 메시지 처리 (세션 ID 설정 등)
            if "text" in data:
                try:
                    message = json.loads(data["text"]) if isinstance(data["text"], str) else data["text"]
                    if isinstance(message, dict) and "session_id" in message:
                        session_id = message["session_id"]
                        print(f"[Agent WebSocket] 세션 ID 설정: {session_id}")
                        await websocket.send_json({
                            "type": "status",
                            "message": f"세션 ID 설정됨: {session_id}"
                        })
                        continue
                except:
                    pass  # JSON 파싱 실패 시 무시
            
            # 오디오 바이트 처리
            if "bytes" in data:
                audio_bytes = data["bytes"]
                audio_chunk = np.frombuffer(audio_bytes, dtype=np.float32)
                
                if len(audio_chunk) != 512:
                    continue
                
                # VAD 처리
                is_speech_end, speech_audio, is_short_pause = stt_engine_instance.vad.process_chunk(audio_chunk)
                
                if is_speech_end and speech_audio is not None:
                    print(f"[Agent WebSocket] 발화 종료 감지, STT + Agent 처리 시작")
                    
                    # STT 처리
                    transcript, quality = stt_engine_instance.whisper.transcribe(speech_audio, callback=None)
                    print(f"[Agent WebSocket] STT 결과: text='{transcript}', quality={quality}")
                    
                    # ========================================================================
                    # 🆕 화자 검증 로직 (품질 게이트 + 점진적 프로필 완성)
                    # ========================================================================
                    speaker_id = None
                    if quality in ["success", "medium"]:
                        try:
                            # Speaker Verifier 임포트 (Lazy)
                            stt_config_path = backend_path / "engine" / "speech-to-text" / "faster_whisper" / "config.yaml"
                            import sys
                            sys.path.insert(0, str(backend_path / "engine" / "speech-to-text" / "faster_whisper"))
                            from speaker_verifier import SpeakerVerifier
                            from engine.langchain_agent import get_conversation_store
                            
                            # Verifier 초기화
                            verifier = SpeakerVerifier(config_path=str(stt_config_path))
                            
                            # 현재 오디오에서 임베딩 추출
                            current_embedding = verifier.extract_embedding(speech_audio)
                            
                            if current_embedding is not None:
                                # 기존 프로필 조회
                                store = get_conversation_store()
                                existing_profiles = store._speaker_profiles
                                
                                # 화자 식별
                                speaker_id, similarity = verifier.identify_speaker(
                                    current_embedding, 
                                    existing_profiles
                                )
                                
                                print(f"[Speaker] 화자 식별: {speaker_id} (유사도: {similarity:.3f})")
                                
                                # 프로필 저장/업데이트 로직
                                if speaker_id not in existing_profiles:
                                    # 신규 화자 등록
                                    store.add_speaker_profile(
                                        speaker_id, 
                                        current_embedding, 
                                        quality,
                                        session_id=session_id
                                    )
                                    print(f"[Speaker] 🆕 신규 등록: {speaker_id}")
                                else:
                                    # 기존 화자 - 품질 비교 후 업데이트 여부 결정
                                    old_quality = existing_profiles[speaker_id]["quality"]
                                    if verifier.should_update_profile(quality, old_quality):
                                        # 점진적 업데이트
                                        old_embedding = existing_profiles[speaker_id]["embedding"]
                                        updated_embedding = verifier.update_embedding(
                                            old_embedding, 
                                            current_embedding,
                                            speaker_id=speaker_id
                                        )
                                        store.update_speaker_embedding(
                                            speaker_id, 
                                            updated_embedding, 
                                            quality
                                        )
                                        print(f"[Speaker] 🔄 프로필 업데이트: {speaker_id}")
                                    else:
                                        print(f"[Speaker] ✓ 기존 사용자: {speaker_id} (업데이트 불필요)")
                                
                                # 디버그 정보 출력
                                all_speaker_ids = store.get_all_speaker_ids()
                                print(f"[Speaker Debug] 현재 등록된 화자: {all_speaker_ids}")
                            else:
                                print(f"[Speaker] ⚠️  임베딩 추출 실패 (오디오 길이 부족 또는 오류)")
                            
                        except Exception as e:
                            print(f"[Speaker] ❌ 화자 검증 오류: {e}")
                            import traceback
                            traceback.print_exc()
                            # 오류가 발생해도 Agent 처리는 계속 진행
                    else:
                        print(f"[Speaker] ⚠️  품질 부족으로 화자 검증 skip (quality={quality})")
                    # ========================================================================
                    
                    # STT 결과 전송 (speaker_id 포함)
                    await websocket.send_json({
                        "type": "stt_result",
                        "text": transcript if quality != "no_speech" else None,
                        "quality": quality,
                        "speaker_id": speaker_id  # 화자 ID 추가
                    })
                    
                    # Agent 자동 실행 (quality가 success 또는 medium인 경우)
                    if quality in ["success", "medium"] and transcript:
                        try:
                            from engine.langchain_agent import run_ai_bomi_from_text
                            
                            # Agent 처리 중 메시지
                            await websocket.send_json({
                                "type": "status",
                                "status": "processing",
                                "message": "AI 봄이가 생각 중..."
                            })
                            
                            result = run_ai_bomi_from_text(
                                user_text=transcript,
                                session_id=session_id or "websocket_default",
                                stt_quality=quality,
                                speaker_id=speaker_id  # 화자 ID 전달
                            )
                            
                            # Agent 응답 전송
                            await websocket.send_json({
                                "type": "agent_response",
                                "data": result
                            })
                            
                            print(f"[Agent WebSocket] Agent 응답 완료")
                            
                        except Exception as e:
                            print(f"[Agent WebSocket] Agent 처리 오류: {e}")
                            import traceback
                            traceback.print_exc()
                            await websocket.send_json({
                                "type": "error",
                                "message": f"Agent 처리 오류: {str(e)}"
                            })
                    
                    stt_engine_instance.vad.reset()
                    
    except WebSocketDisconnect:
        print("[Agent WebSocket] 연결 종료")
    except Exception as e:
        print(f"[Agent WebSocket] 오류: {e}")
        import traceback
        traceback.print_exc()
        try:
            await websocket.send_json({
                "type": "error",
                "message": str(e)
            })
        except:
            pass
    finally:
        if stt_engine_instance is not None:
            try:
                stt_engine_instance.vad.reset()
            except:
                pass


@app.post(
    "/api/engine/routine-from-emotion",
    response_model=List[RoutineRecommendationItem],
    tags=["routine-recommend"],
)
async def recommend_routine_from_emotion(
    emotion: EmotionAnalysisResult,
    city: Optional[str] = "Seoul",      # 🌦️ 쿼리 파라미터로 도시 받기 (기본: Seoul)
    country: str = "KR"                  # 🌦️ 쿼리 파라미터로 국가 받기 (기본: KR)
):
    """
    감정 분석 결과를 기반으로 루틴을 추천합니다.

    프로세스:
    1. RAG를 사용하여 ChromaDB에서 관련 루틴 후보 검색
    2. 🌦️ 날씨 정보 조회 (비/눈/뇌우 시 야외 루틴 필터링)
    3. GPT-4o-mini를 사용하여 최종 추천 루틴 선택 및 설명 생성

    Args:
        emotion: 감정 분석 결과 (EmotionAnalysisResult)
        city: 날씨 조회 도시 (선택, 기본값: "Seoul")
        country: 날씨 조회 국가 코드 (선택, 기본값: "KR")

    Returns:
        추천된 루틴 리스트 (reason, ui_message 포함)
    
    Example:
        POST /api/engine/routine-from-emotion?city=Busan&country=KR
        
    Note:
        - city 파라미터를 전달하지 않으면 Seoul 기준으로 날씨 조회
        - 프론트엔드에서 사용자 위치 정보를 얻으면 city 파라미터로 전달 가능
    """
    try:
        engine = RoutineRecommendFromEmotionEngine()
        
        # 🌦️ 날씨 정보를 고려한 루틴 추천
        recommendations = await engine.recommend(
            emotion,
            city=city,
            country=country
        )
        
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

