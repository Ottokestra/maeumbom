"""팀 프로젝트 메인 FastAPI 애플리케이션"""

import os
import sys
from pathlib import Path
from typing import List, Optional

import numpy as np
from fastapi import (
    FastAPI,
    WebSocket,
    WebSocketDisconnect,
    HTTPException,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, ConfigDict

# ============================================================
# 경로 설정
# ============================================================

backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

# ✅ TTS 모듈이 있는 폴더를 파이썬 경로에 추가
tts_path = backend_path / "engine" / "text-to-speech"
sys.path.insert(0, str(tts_path))

# ============================================================
# 서브 모듈 import
# ============================================================

# Emotion 분석 라우터는 동적 로딩
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
    print("[WARN] Emotion analysis module load failed:", e)
    emotion_router = None

# TTS 엔진 레지스트리
from engine.text_to_speech import get_tts_engine

# 루틴 추천 엔진
from engine.routine_recommend.engine import RoutineRecommendFromEmotionEngine
from engine.routine_recommend.models.schemas import (
    EmotionAnalysisResult,
    RoutineRecommendationItem,
)

# 날씨 / 루틴 설문 라우터
from app.weather.routes import router as weather_router
from app.routine_survey.routers import router as routine_survey_router
from app.routes.emotion_report import router as emotion_report_router
from app.menopause_survey.router import router as menopause_survey_router
from app.reports.router import router as reports_router

# 루틴 설문 기본 seed
from app.routine_survey.models import seed_default_mr_survey

# DB 세션/초기화
from app.db.database import SessionLocal, init_db

# ============================================================
# FastAPI 앱 생성
# ============================================================

app = FastAPI(
    title="Team Project API",
    description="팀 프로젝트 통합 API 서비스 (Emotion + STT + TTS)",
    version="1.0.0",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------------------------------
# Startup: DB 테이블 생성 + 루틴 설문 기본 seed
# ------------------------------------------------------------

@app.on_event("startup")
def on_startup():
    """DB 초기화 및 루틴 설문 기본 데이터 seed"""
    try:
        # 테이블 생성
        init_db()

        # 루틴 설문 기본 세트 삽입
        db = SessionLocal()
        try:
            seed_default_mr_survey(db)
            print("[INFO] 기본 루틴 설문 seed 완료")
        finally:
            db.close()
    except Exception as e:
        import traceback
        print(f"[WARN] Startup 초기화 오류: {e}")
        traceback.print_exc()

# ============================================================
# Emotion 분석 라우터
# ============================================================

if emotion_router is not None:
    app.include_router(emotion_router, prefix="/emotion/api", tags=["emotion"])
    # 하위 호환성을 위해 /api 경로도 지원
    app.include_router(emotion_router, prefix="/api", tags=["emotion"])

# ============================================================
# Daily Mood Check + Weather Service
# ============================================================

try:
    # Daily mood check 라우터는 파일 경로 기반 동적 로딩
    daily_mood_check_path = backend_path / "app" / "daily_mood_check" / "routes.py"
    if not daily_mood_check_path.exists():
        print(f"[WARN] Daily mood check routes file not found: {daily_mood_check_path}")
    else:
        spec = importlib.util.spec_from_file_location("daily_mood_check_routes", daily_mood_check_path)
        daily_mood_check_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(daily_mood_check_module)
        daily_mood_check_router = daily_mood_check_module.router
        app.include_router(
            daily_mood_check_router,
            prefix="/api/service/daily-mood-check",
            tags=["daily-mood-check"],
        )
        print("[INFO] Daily mood check router loaded successfully.")

    # Weather 라우터
    app.include_router(
        weather_router,
        prefix="/api/service/weather",
        tags=["weather"],
    )
    print("[INFO] Weather router loaded successfully.")
except Exception as e:
    import traceback
    print(f"[WARN] Daily mood check / Weather module load failed: {e}")
    traceback.print_exc()

# ============================================================
# Routine survey 라우터
# ============================================================

app.include_router(routine_survey_router, prefix="/api", tags=["routine-survey"])
app.include_router(emotion_report_router)
app.include_router(reports_router)
app.include_router(menopause_survey_router, prefix="/api", tags=["menopause-survey"])

# ============================================================
# Authentication (Google OAuth + JWT)
# ============================================================

try:
    from app.auth import router as auth_router

    # init_db() 는 startup 에서 이미 호출되므로 여기서는 라우터만 포함
    app.include_router(auth_router, prefix="/auth", tags=["authentication"])
    print("[INFO] Authentication router loaded successfully.")
except Exception as e:
    import traceback
    print(f"[WARN] Authentication module load failed: {e}")
    traceback.print_exc()

# ============================================================
# LangChain Agent REST API
# ============================================================

class AgentTextRequest(BaseModel):
    user_text: str
    session_id: Optional[str] = None
    stt_quality: Optional[str] = None  # "success" | "medium" | "low_quality" | "no_speech" | None


class AgentTextV2Request(AgentTextRequest):
    pass


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
                    "note": "no_speech_detected",
                },
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
                    "note": "low_quality_audio",
                },
            }

        # 정상 품질 또는 텍스트 입력인 경우 Agent 실행
        result = run_ai_bomi_from_text(
            user_text=request.user_text,
            session_id=request.session_id,
            stt_quality=request.stt_quality,
        )
        return result
    except Exception as e:
        import traceback

        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/agent/v2/text")
async def agent_text_v2_endpoint(request: AgentTextV2Request):
    """LangChain Agent v2 - 텍스트 입력 (캐릭터 정보 포함)"""
    try:
        from engine.langchain_agent import run_ai_bomi_from_text_v2

        default_meta = {
            "model": os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
            "used_tools": [],
            "session_id": request.session_id or "default",
            "stt_quality": request.stt_quality,
            "tts_engine_default": "cute_bomi",
        }
        default_character = {"id": "cloud_white", "emotion_label": "NEUTRAL"}

        if request.stt_quality == "no_speech":
            return {
                "reply_text": "음성이 감지되지 않았어요. 다시 말씀해주시겠어요?",
                "input_text": request.user_text or "",
                "emotion_result": None,
                "routine_result": None,
                "character": default_character,
                "meta": {
                    **default_meta,
                    "note": "no_speech_detected",
                },
            }
        elif request.stt_quality == "low_quality":
            return {
                "reply_text": "소음이 심해서 잘 들리지 않았어요. 조용한 곳에서 다시 말씀해주시겠어요?",
                "input_text": request.user_text or "",
                "emotion_result": None,
                "routine_result": None,
                "character": default_character,
                "meta": {
                    **default_meta,
                    "note": "low_quality_audio",
                },
            }

        result = run_ai_bomi_from_text_v2(
            user_text=request.user_text,
            session_id=request.session_id or "default",
            stt_quality=request.stt_quality,
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
            session_id=request.session_id,
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
            "messages": history,
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
            "sessions": sessions,
        }
    except Exception as e:
        import traceback

        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================
# STT WebSocket
# ============================================================

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

        # STT 엔진 초기화
        engine = get_stt_engine()

        # 엔진 준비 완료 메시지
        await websocket.send_json({"status": "ready", "message": "STT 엔진 준비 완료"})

        while True:
            try:
                data = await websocket.receive()
            except RuntimeError as e:
                if "disconnect" in str(e).lower():
                    print("클라이언트 연결 종료 감지")
                    break
                raise

            if "bytes" in data:
                audio_bytes = data["bytes"]
                audio_chunk = np.frombuffer(audio_bytes, dtype=np.float32)

                if len(audio_chunk) != 512:
                    continue

                # VAD 처리
                is_speech_end, speech_audio, is_short_pause = engine.vad.process_chunk(audio_chunk)

                # 디버그 카운터
                if hasattr(engine.vad, "_debug_counter"):
                    engine.vad._debug_counter = getattr(engine.vad, "_debug_counter", 0) + 1
                else:
                    engine.vad._debug_counter = 1

                if engine.vad._debug_counter % 100 == 0:
                    print(
                        f"[STT DEBUG] 청크 처리: speech_end={is_speech_end}, "
                        f"short_pause={is_short_pause}, "
                        f"speech_audio_len={len(speech_audio) if speech_audio is not None else 0}"
                    )

                if is_speech_end and speech_audio is not None:
                    print(f"[STT] 발화 종료 감지, STT 처리 시작 (오디오 길이: {len(speech_audio)} 샘플)")

                    await websocket.send_json(
                        {
                            "status": "processing",
                            "message": "듣고 생각하는 중...",
                        }
                    )

                    transcript, quality = engine.whisper.transcribe(speech_audio, callback=None)
                    print(f"[STT] STT 결과: text='{transcript}', quality={quality}")

                    # -------------------------- 화자 검증 --------------------------
                    speaker_id = None
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
                                existing_profiles = store._speaker_profiles

                                speaker_id, similarity = verifier.identify_speaker(
                                    current_embedding, existing_profiles
                                )
                                print(f"[Speaker] 화자 식별: {speaker_id} (유사도: {similarity:.3f})")

                                if speaker_id not in existing_profiles:
                                    store.add_speaker_profile(
                                        speaker_id, current_embedding, quality, session_id=None
                                    )
                                    print(f"[Speaker] 🆕 신규 등록: {speaker_id}")
                                else:
                                    old_quality = existing_profiles[speaker_id]["quality"]
                                    if verifier.should_update_profile(quality, old_quality):
                                        old_embedding = existing_profiles[speaker_id]["embedding"]
                                        updated_embedding = verifier.update_embedding(
                                            old_embedding, current_embedding, speaker_id=speaker_id
                                        )
                                        store.update_speaker_embedding(
                                            speaker_id, updated_embedding, quality
                                        )
                                        print(f"[Speaker] 🔄 프로필 업데이트: {speaker_id}")
                                    else:
                                        print(f"[Speaker] ✓ 기존 사용자: {speaker_id} (업데이트 불필요)")

                                all_speaker_ids = store.get_all_speaker_ids()
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

                    engine.vad.reset()

            elif "text" in data:
                command = data["text"]
                if command == "reset":
                    engine.vad.reset()
                    await websocket.send_json({"status": "reset", "message": "VAD 리셋 완료"})
                elif command == "force_process":
                    print("[STT] 강제 인식 요청 수신")
                    try:
                        if hasattr(engine.vad, "get_current_buffer"):
                            buffered_audio = engine.vad.get_current_buffer()
                            if buffered_audio is not None and len(buffered_audio) > 0:
                                print(
                                    f"[STT] 강제 인식 처리 (오디오 길이: {len(buffered_audio)} 샘플)"
                                )
                                transcript, quality = engine.whisper.transcribe(
                                    buffered_audio, callback=None
                                )
                                response = {
                                    "text": transcript if quality in ["success", "medium"] else None,
                                    "quality": quality,
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
            pass
    finally:
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

                    # 화자 검증
                    speaker_id = None
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
                                existing_profiles = store._speaker_profiles

                                speaker_id, similarity = verifier.identify_speaker(
                                    current_embedding, existing_profiles
                                )
                                print(f"[Speaker] 화자 식별: {speaker_id} (유사도: {similarity:.3f})")

                                if speaker_id not in existing_profiles:
                                    store.add_speaker_profile(
                                        speaker_id, current_embedding, quality, session_id=session_id
                                    )
                                    print(f"[Speaker] 🆕 신규 등록: {speaker_id}")
                                else:
                                    old_quality = existing_profiles[speaker_id]["quality"]
                                    if verifier.should_update_profile(quality, old_quality):
                                        old_embedding = existing_profiles[speaker_id]["embedding"]
                                        updated_embedding = verifier.update_embedding(
                                            old_embedding, current_embedding, speaker_id=speaker_id
                                        )
                                        store.update_speaker_embedding(
                                            speaker_id, updated_embedding, quality
                                        )
                                        print(f"[Speaker] 🔄 프로필 업데이트: {speaker_id}")
                                    else:
                                        print(f"[Speaker] ✓ 기존 사용자: {speaker_id} (업데이트 불필요)")

                                all_speaker_ids = store.get_all_speaker_ids()
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
                            from engine.langchain_agent import run_ai_bomi_from_text

                            await websocket.send_json(
                                {
                                    "type": "status",
                                    "status": "processing",
                                    "message": "AI 봄이가 생각 중...",
                                }
                            )

                            result = run_ai_bomi_from_text(
                                user_text=transcript,
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

# ============================================================
# 루틴 추천 엔진 API
# ============================================================

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


class TTSRequest(BaseModel):
    model_config = ConfigDict(extra="allow")

    text: str
    engine: str | None = None
    character_id: str | None = None
    emotion_label: str | None = None
    tone: str | None = None  # backward compatibility


@app.post("/api/tts")
async def tts_endpoint(payload: TTSRequest):
    """텍스트 -> 음성 변환 API"""

    if not payload.text.strip():
        raise HTTPException(status_code=400, detail="text is required")

    emotion_label = payload.emotion_label or payload.tone
    engine_name = payload.engine

    tts_engine = get_tts_engine(engine_name)

    try:
        wav_path = tts_engine.synthesize_to_wav(
            text=payload.text,
            voice_id=payload.character_id,
            emotion=emotion_label,
        )
    except Exception as e:  # pragma: no cover - runtime logging aid
        import sys as _sys, traceback as _traceback

        print("[TTS ERROR]", e, file=_sys.stderr)
        _traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"TTS error: {e}")

    filename = f"tts_{tone or 'neutral'}.wav"
    return StreamingResponse(
        BytesIO(audio_bytes),
        media_type="audio/wav",
        headers={"Content-Disposition": f"attachment; filename=\"{filename}\""},
    )

# ============================================================
# Root
# ============================================================

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
        "modules": modules,
    }

# ============================================================
# __main__
# ============================================================

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
    print("  - TTS: POST http://localhost:8000/api/tts")
    print("\n" + "=" * 50 + "\n")

    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)
