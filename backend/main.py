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
from typing import List, Optional

import numpy as np
from fastapi import (
    FastAPI,
    WebSocket,
    WebSocketDisconnect,
    HTTPException,
    Request,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from app.weather.routes import router as weather_router
from pydantic import BaseModel


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
from engine.routine_recommend.models.schemas import (
    EmotionAnalysisResult,
    RoutineRecommendationItem,
)

# 날씨 / 루틴 설문 라우터
from app.weather.routes import router as weather_router
from app.routine_survey.routers import router as routine_survey_router

# 루틴 설문 기본 seed
from app.routine_survey.models import seed_default_mr_survey

# DB 세션/초기화
from app.db.database import SessionLocal, init_db

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
    from app.weather.routes import router as weather_router
    app.include_router(weather_router)
    print("[INFO] Weather router loaded successfully.")
except Exception as e:
    import traceback
    print(f"[WARN] Weather module load failed: {e}")
    traceback.print_exc()
    
try:
    daily_mood_check_path = backend_path / "app" / "daily_mood_check" / "routes.py"
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
        import traceback
        print(f"[WARN] Daily mood check / Weather module load failed: {e}")
        traceback.print_exc()
        
        
except Exception as e:
    import traceback
    print(f"[WARN] Daily mood check module load failed: {e}")
    traceback.print_exc()

# ============================================================
# Routine survey 라우터
# ============================================================

app.include_router(routine_survey_router, prefix="/api", tags=["routine-survey"])

# ============================================================
# Authentication (Google OAuth + JWT)
# =========================
try:
    from app.auth import router as auth_router
    from app.db.database import init_db
    
    # Initialize database tables
    init_db()
    
    # 시나리오 데이터 자동 import (init_db 직후 실행)
    try:
        from app.relation_training.import_data import import_all
        from pathlib import Path

        data_dir = Path(__file__).parent / "app" / "relation_training" / "data"
        if data_dir.exists():
            # Excel과 JSON 파일 모두 확인
            excel_files = list(data_dir.glob('*.xlsx'))
            excel_files = [f for f in excel_files if not f.name.startswith('~') and f.name != 'template.xlsx']
            json_files = list(data_dir.glob('*.json'))
            json_files = [f for f in json_files if f.name != 'template.json']

            if excel_files or json_files:
                print(f"[INFO] Importing scenario files (Excel: {len(excel_files)}, JSON: {len(json_files)})...")
                try:
                    import_all(data_dir, update=False, clear=False)
                except Exception as import_error:
                    import traceback
                    print(f"[ERROR] Scenario import 실행 중 에러 발생: {import_error}")
                    traceback.print_exc()
            else:
                print("[INFO] No scenario files found in data folder.")
        else:
            print(f"[WARN] Scenario data directory not found: {data_dir}")
    except Exception as e:
        import traceback
        print(f"[ERROR] Scenario data auto-import setup failed: {e}")
        traceback.print_exc()
        # 에러가 발생해도 서버는 계속 실행

    # Include auth router
    app.include_router(auth_router, prefix="/auth", tags=["authentication"])
    print("[INFO] Authentication router loaded successfully.")

    # Include dashboard router
    from app.dashboard.routes import router as dashboard_router
    app.include_router(dashboard_router, prefix="/api/dashboard", tags=["dashboard"])
    print("[INFO] Dashboard router loaded successfully.")
except Exception as e:
    import traceback
    print(f"[WARN] Authentication/Dashboard module load failed: {e}")
    traceback.print_exc()

# =========================
# User Phase Service
# =========================
try:
    from app.user_phase.routes import router as user_phase_router

    app.include_router(user_phase_router, tags=["user-phase"])
    print("[INFO] User Phase router loaded successfully.")
except Exception as e:
    import traceback
    print(f"[WARN] User Phase module load failed: {e}")
    traceback.print_exc()

# =========================
# Relation Training Service (Interactive Scenario)
# =========================
try:
    from app.relation_training.routes import router as relation_training_router

    app.include_router(
        relation_training_router,
        prefix="/api/service/relation-training",
        tags=["relation-training"]
    )
    print("[INFO] Relation training router loaded successfully.")

except Exception as e:
    import traceback
    print(f"[WARN] Relation training module load failed: {e}")
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

# ============================================================================
# V2 APIs - JWT 인증 필수, DB 기반 저장소 사용 (점진적 마이그레이션)
# ============================================================================
from fastapi import Depends
from app.auth.dependencies import get_current_user
from app.db.models import User

@app.post("/api/agent/v2/text")
async def agent_text_v2_endpoint(
    request: AgentTextRequest,
    current_user: User = Depends(get_current_user)
):
    """
    LangChain Agent V2 - 텍스트 입력 (JWT 인증 필수, DB 저장)

    인증 필요: Bearer token
    """
    try:
        from engine.langchain_agent.agent_v2 import run_ai_bomi_from_text_v2

        user_id = current_user.ID
        session_id = request.session_id or f"user_{user_id}_default"
        
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
                    "session_id": session_id,
                    "stt_quality": request.stt_quality,
                    "user_id": user_id,
                    "storage": "database",
                    "api_version": "v2",
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
                    "session_id": session_id,
                    "stt_quality": request.stt_quality,
                    "user_id": user_id,
                    "storage": "database",
                    "api_version": "v2",
                    "note": "low_quality_audio"
                }
            }
        
        # V2 함수 호출 - DB에 저장됨
        result = await run_ai_bomi_from_text_v2(
            user_text=request.user_text,
            user_id=user_id,
            session_id=session_id,
            stt_quality=request.stt_quality
        )

        return result
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/agent/v2/sessions")
async def get_all_agent_sessions_v2(current_user: User = Depends(get_current_user)):
    """
    LangChain Agent V2 - 현재 유저의 모든 세션 정보 조회

    인증 필요: Bearer token
    """
    try:
        from engine.langchain_agent.db_conversation_store import get_conversation_store

        user_id = current_user.ID
        store = get_conversation_store()

        # 유저별 세션 조회 (DB 기반)
        sessions = store.get_user_sessions(user_id)

        return {
            "user_id": user_id,
            "session_count": len(sessions),
            "sessions": sessions
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/agent/v2/sessions/{session_id}")
async def get_agent_session_v2(
    session_id: str,
    current_user: User = Depends(get_current_user),
    limit: int = None
):
    """
    LangChain Agent V2 - 특정 세션의 대화 히스토리 조회 (유저 검증)

    인증 필요: Bearer token
    """
    try:
        from engine.langchain_agent.db_conversation_store import get_conversation_store

        user_id = current_user.ID
        store = get_conversation_store()
        
        # 유저별 히스토리 조회
        history = store.get_history(user_id, session_id, limit=limit)
        metadata = store.get_session_metadata(user_id, session_id)
        
        return {
            "session_id": session_id,
            "user_id": user_id,
            "metadata": metadata,
            "message_count": len(history),
            "messages": history
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/agent/v2/sessions/{session_id}")
async def delete_agent_session_v2(
    session_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    LangChain Agent V2 - 특정 세션 삭제 (Soft Delete)

    인증 필요: Bearer token
    """
    try:
        from engine.langchain_agent.db_conversation_store import get_conversation_store

        user_id = current_user.ID
        store = get_conversation_store()
        
        # Soft delete (IS_DELETED = 'Y')
        store.clear_session(user_id, session_id)

        return {
            "status": "success",
            "message": f"Session {session_id} soft deleted",
            "user_id": user_id,
            "session_id": session_id
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# 테스트용 완전 삭제 API (Cleanup Endpoints)
# ============================================================================

@app.delete("/api/agent/cleanup/conversations")
async def cleanup_conversations(current_user: User = Depends(get_current_user)):
    """테스트용: 현재 유저의 모든 대화 내역 완전 삭제"""
    try:
        from engine.langchain_agent.db_conversation_store import get_conversation_store

        user_id = current_user.ID
        store = get_conversation_store()

        count = store.hard_delete_all_conversations(user_id)

        return {
            "status": "success",
            "message": f"Deleted {count} conversation records",
            "user_id": user_id
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/agent/cleanup/session-memories")
async def cleanup_session_memories(current_user: User = Depends(get_current_user)):
    """테스트용: 현재 유저의 모든 세션 메모리 완전 삭제"""
    try:
        from app.db.database import SessionLocal
        from app.db.models import SessionMemory

        user_id = current_user.ID
        db = SessionLocal()
        try:
            count = db.query(SessionMemory).filter(
                SessionMemory.USER_ID == user_id
            ).delete()
            db.commit()

            return {
                "status": "success",
                "message": f"Deleted {count} session memory records",
                "user_id": user_id
            }
        finally:
            db.close()
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/agent/cleanup/global-memories")
async def cleanup_global_memories(current_user: User = Depends(get_current_user)):
    """테스트용: 현재 유저의 모든 전역 메모리 완전 삭제"""
    try:
        from app.db.database import SessionLocal
        from app.db.models import GlobalMemory

        user_id = current_user.ID
        db = SessionLocal()
        try:
            count = db.query(GlobalMemory).filter(
                GlobalMemory.USER_ID == user_id
            ).delete()
            db.commit()

            return {
                "status": "success",
                "message": f"Deleted {count} global memory records",
                "user_id": user_id
            }
        finally:
            db.close()
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
                    # 🆕 화자 검증 로직 (DB 기반)
                    # ========================================================================
                    speaker_id = None
                    user_id = 1  # Default user ID for now (until auth is added to websocket)
                    
                    if quality in ["success", "medium"]:
                        try:
                            stt_config_path = (
                                backend_path / "engine" / "speech-to-text" / "faster_whisper" / "config.yaml"
                            )
                            sys.path.insert(
                                0, str(backend_path / "engine" / "speech-to-text" / "faster_whisper")
                            )
                            from speaker_verifier import SpeakerVerifier
                            from engine.langchain_agent import get_conversation_store

                            verifier = SpeakerVerifier(config_path=str(stt_config_path))
                            current_embedding = verifier.extract_embedding(speech_audio)

                            if current_embedding is not None:
                                store = get_conversation_store()
                                
                                # 1. DB에서 프로필 조회
                                db_profiles = store.get_speaker_profiles(user_id)
                                
                                # 2. Verifier 포맷으로 변환
                                existing_profiles = {}
                                for p in db_profiles:
                                    existing_profiles[p["speaker_type"]] = {
                                        "embedding": np.array(p["embedding"]),
                                        "current_score": p["current_score"],
                                        "quality": "success" # DB에는 품질 저장 안하므로 기본값
                                    }

                                # 3. 화자 식별
                                speaker_id, similarity = verifier.identify_speaker(
                                    current_embedding, existing_profiles
                                )
                                print(f"[Speaker] 화자 식별: {speaker_id} (유사도: {similarity:.3f})")

                                if speaker_id not in existing_profiles:
                                    # 4. 신규 등록
                                    store.save_speaker_profile(
                                        user_id, speaker_id, current_embedding.tolist(), similarity
                                    )
                                    print(f"[Speaker] 🆕 신규 등록: {speaker_id}")
                                else:
                                    # 5. 기존 화자 업데이트 (점수가 더 높을 때만)
                                    current_score = existing_profiles[speaker_id]["current_score"]
                                    if similarity > current_score:
                                        # 임베딩 업데이트 (가중 평균)
                                        old_embedding = existing_profiles[speaker_id]["embedding"]
                                        updated_embedding = verifier.update_embedding(
                                            old_embedding, current_embedding, speaker_id=speaker_id
                                        )
                                        
                                        # DB 업데이트
                                        profile_id = next(p["id"] for p in db_profiles if p["speaker_type"] == speaker_id)
                                        store.update_speaker_profile(
                                            profile_id, updated_embedding.tolist(), similarity, user_id
                                        )
                                        print(f"[Speaker] 🔄 프로필 업데이트: {speaker_id} (Score: {current_score:.3f} -> {similarity:.3f})")
                                    else:
                                        print(f"[Speaker] ✓ 기존 사용자: {speaker_id} (업데이트 불필요, Score: {current_score:.3f} >= {similarity:.3f})")

                                # 디버깅용 출력
                                all_speaker_ids = [p["speaker_type"] for p in store.get_speaker_profiles(user_id)]
                                print(f"[Speaker Debug] 현재 등록된 화자: {all_speaker_ids}")
                            else:
                                print("[Speaker] ⚠️ 임베딩 추출 실패")
                        except Exception as e:
                            print(f"[Speaker] ❌ 화자 검증 오류: {e}")
                            import traceback
                            traceback.print_exc()
                    else:
                        print(f"[Speaker] ⚠️ 품질 부족으로 화자 검증 skip (quality={quality})")

                    # 결과 전송
                    await websocket.send_json(
                        {
                            "text": transcript if quality in ["success", "medium"] else None,
                            "quality": quality,
                            "speaker_id": speaker_id,
                        }
                    )


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
        try:
            await websocket.send_json({"error": str(e)})
        except:
            pass
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

# ============================================================
# STT + Agent WebSocket
# ============================================================

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
        await websocket.send_json(
            {
                "type": "status",
                "status": "connecting",
                "message": "STT + Agent 엔진 초기화 중...",
            }
        )

        stt_engine_instance = get_stt_engine()

        await websocket.send_json(
            {
                "type": "status",
                "status": "ready",
                "message": "준비 완료. 말씀하세요.",
            }
        )

        while True:
            try:
                data = await websocket.receive()
            except RuntimeError as e:
                if "disconnect" in str(e).lower():
                    print("[Agent WebSocket] 클라이언트 연결 종료")
                    break
                raise

            if "text" in data:
                try:
                    message = json.loads(data["text"]) if isinstance(data["text"], str) else data["text"]
                    if isinstance(message, dict) and "session_id" in message:
                        session_id = message["session_id"]
                        print(f"[Agent WebSocket] 세션 ID 설정: {session_id}")
                        await websocket.send_json(
                            {"type": "status", "message": f"세션 ID 설정됨: {session_id}"}
                        )
                        continue
                except Exception:
                    pass

            if "bytes" in data:
                audio_bytes = data["bytes"]
                audio_chunk = np.frombuffer(audio_bytes, dtype=np.float32)

                if len(audio_chunk) != 512:
                    continue

                is_speech_end, speech_audio, is_short_pause = stt_engine_instance.vad.process_chunk(
                    audio_chunk
                )

                if is_speech_end and speech_audio is not None:
                    print("[Agent WebSocket] 발화 종료 감지, STT + Agent 처리 시작")

                    transcript, quality = stt_engine_instance.whisper.transcribe(
                        speech_audio, callback=None
                    )
                    print(f"[Agent WebSocket] STT 결과: text='{transcript}', quality={quality}")

                    # ========================================================================
                    # 🆕 화자 검증 로직 (DB 기반)
                    # ========================================================================
                    speaker_id = None
                    user_id = 1  # Default user ID for now
                    
                    if quality in ["success", "medium"]:
                        try:
                            stt_config_path = (
                                backend_path / "engine" / "speech-to-text" / "faster_whisper" / "config.yaml"
                            )
                            sys.path.insert(
                                0, str(backend_path / "engine" / "speech-to-text" / "faster_whisper")
                            )
                            from speaker_verifier import SpeakerVerifier
                            from engine.langchain_agent import get_conversation_store

                            verifier = SpeakerVerifier(config_path=str(stt_config_path))
                            current_embedding = verifier.extract_embedding(speech_audio)

                            if current_embedding is not None:
                                store = get_conversation_store()
                                
                                # 1. DB에서 프로필 조회
                                db_profiles = store.get_speaker_profiles(user_id)
                                
                                # 2. Verifier 포맷으로 변환
                                existing_profiles = {}
                                for p in db_profiles:
                                    existing_profiles[p["speaker_type"]] = {
                                        "embedding": np.array(p["embedding"]),
                                        "current_score": p["current_score"],
                                        "quality": "success"
                                    }

                                # 3. 화자 식별
                                speaker_id, similarity = verifier.identify_speaker(
                                    current_embedding, existing_profiles
                                )
                                print(f"[Speaker] 화자 식별: {speaker_id} (유사도: {similarity:.3f})")

                                if speaker_id not in existing_profiles:
                                    # 4. 신규 등록
                                    store.save_speaker_profile(
                                        user_id, speaker_id, current_embedding.tolist(), similarity
                                    )
                                    print(f"[Speaker] 🆕 신규 등록: {speaker_id}")
                                else:
                                    # 5. 기존 화자 업데이트
                                    current_score = existing_profiles[speaker_id]["current_score"]
                                    if similarity > current_score:
                                        old_embedding = existing_profiles[speaker_id]["embedding"]
                                        updated_embedding = verifier.update_embedding(
                                            old_embedding, current_embedding, speaker_id=speaker_id
                                        )
                                        
                                        profile_id = next(p["id"] for p in db_profiles if p["speaker_type"] == speaker_id)
                                        store.update_speaker_profile(
                                            profile_id, updated_embedding.tolist(), similarity, user_id
                                        )
                                        print(f"[Speaker] 🔄 프로필 업데이트: {speaker_id} (Score: {current_score:.3f} -> {similarity:.3f})")
                                    else:
                                        print(f"[Speaker] ✓ 기존 사용자: {speaker_id} (업데이트 불필요)")

                                all_speaker_ids = [p["speaker_type"] for p in store.get_speaker_profiles(user_id)]
                                print(f"[Speaker Debug] 현재 등록된 화자: {all_speaker_ids}")
                            else:
                                print("[Speaker] ⚠️ 임베딩 추출 실패")
                        except Exception as e:
                            print(f"[Speaker] ❌ 화자 검증 오류: {e}")
                            import traceback
                            traceback.print_exc()
                    else:
                        print(f"[Speaker] ⚠️ 품질 부족으로 화자 검증 skip (quality={quality})")

                    await websocket.send_json(
                        {
                            "type": "stt_result",
                            "text": transcript if quality != "no_speech" else None,
                            "quality": quality,
                            "speaker_id": speaker_id,
                        }
                    )

                    if quality in ["success", "medium"] and transcript:
                        try:
                            from engine.langchain_agent import run_ai_bomi_from_text_v2

                            await websocket.send_json(
                                {
                                    "type": "status",
                                    "status": "processing",
                                    "message": "AI 봄이가 생각 중...",
                                }
                            )

                            result = await run_ai_bomi_from_text_v2(
                                user_text=transcript,
                                user_id=user_id,
                                session_id=session_id or "websocket_default",
                                stt_quality=quality,
                                speaker_id=speaker_id,
                            )

                            await websocket.send_json(
                                {
                                    "type": "agent_response",
                                    "data": result,
                                }
                            )
                            print("[Agent WebSocket] Agent 응답 완료")
                        except Exception as e:
                            print(f"[Agent WebSocket] Agent 처리 오류: {e}")
                            import traceback

                            traceback.print_exc()
                            await websocket.send_json(
                                {
                                    "type": "error",
                                    "message": f"Agent 처리 오류: {str(e)}",
                                }
                            )

                    stt_engine_instance.vad.reset()

    except WebSocketDisconnect:
        print("[Agent WebSocket] 연결 종료")
    except Exception as e:
        print(f"[Agent WebSocket] 오류: {e}")
        import traceback

        traceback.print_exc()
        try:
            await websocket.send_json({"type": "error", "message": str(e)})
        except Exception:
            pass
    finally:
        if stt_engine_instance is not None:
            try:
                stt_engine_instance.vad.reset()
            except Exception:
                pass


@app.post(
    "/api/engine/routine-from-emotion",
    response_model=List[RoutineRecommendationItem],
    tags=["routine-recommend"],
)
async def recommend_routine_from_emotion(
    emotion: EmotionAnalysisResult,
    city: Optional[str] = "Seoul",
    country: str = "KR",
):
    """
    감정 분석 결과를 기반으로 루틴을 추천합니다.
    """
    try:
        engine = RoutineRecommendFromEmotionEngine()
        recommendations = await engine.recommend(
            emotion,
            city=city,
            country=country,
        )
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"루틴 추천 실패: {str(e)}")

# ============================================================
# TTS
# ============================================================

@app.get("/health")
async def health():
    """전체 서비스 헬스 체크 (TTS 기준)"""
    return {"status": "ok"}


@app.post("/api/tts")
async def tts(request: Request):
    """
    텍스트 -> 음성 변환 API (3-7)
    """
    raw = await request.body()

    try:
        body_str = raw.decode("utf-8")
    except UnicodeDecodeError:
        body_str = raw.decode("cp949", errors="replace")

    try:
        payload = json.loads(body_str)
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"json parse error: {e}; body={body_str!r}",
        )

    text = payload.get("text")
    speed = payload.get("speed")
    tone = payload.get("tone", "senior_calm")
    engine_name = payload.get("engine", "melo")

    if not text or not str(text).strip():
        raise HTTPException(status_code=400, detail="text is required")

    try:
        wav_path = synthesize_to_wav(
            text=str(text),
            speed=speed,
            tone=str(tone),
            engine=str(engine_name),
        )
    except Exception as e:
        import sys as _sys, traceback as _traceback

        print("[TTS ERROR]", e, file=_sys.stderr)
        _traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"TTS error: {e}")

    return FileResponse(
        path=str(wav_path),
        filename=wav_path.name,
        media_type="audio/wav",
    )

# ============================================================
# Root
# ============================================================

# ============================================================================
# Debug & Cleanup APIs
# ============================================================================

@app.delete("/api/debug/cleanup/history")
async def cleanup_history(current_user: User = Depends(get_current_user)):
    """
    [Debug] 대화 내역 완전 삭제 (DB + RAG)
    """
    try:
        user_id = current_user.ID

        # 1. DB 삭제
        from engine.langchain_agent.db_conversation_store import get_conversation_store
        store = get_conversation_store()
        db_count = store.hard_delete_all_conversations(user_id)

        # 2. RAG 삭제 (Legacy V1 제거로 인해 비활성화)
        # from engine.langchain_agent.conversation_vectorstore import get_conversation_vectorstore
        # vectorstore = get_conversation_vectorstore()
        # vectorstore.hard_delete_user_data(user_id)

        return {
            "status": "success",
            "message": f"Deleted {db_count} conversation records and all RAG data for user {user_id}"
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/debug/cleanup/memories")
async def cleanup_memories(current_user: User = Depends(get_current_user)):
    """
    [Debug] 기억 데이터 완전 삭제 (단기 + 장기)
    """
    try:
        from app.db.database import SessionLocal
        from app.db.models import SessionMemory, GlobalMemory

        user_id = current_user.ID
        db = SessionLocal()
        try:
            # 1. Session Memories 삭제
            session_count = db.query(SessionMemory).filter(
                SessionMemory.USER_ID == user_id
            ).delete()

            # 2. Global Memories 삭제
            global_count = db.query(GlobalMemory).filter(
                GlobalMemory.USER_ID == user_id
            ).delete()

            db.commit()

            return {
                "status": "success",
                "message": f"Deleted {session_count} session memories and {global_count} global memories for user {user_id}"
            }
        finally:
            db.close()
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


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
