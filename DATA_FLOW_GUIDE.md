# STT -> 감정분석 -> LLM -> TTS 데이터 플로우 가이드

## 📋 목차
1. [전체 흐름도](#전체-흐름도)
2. [프론트엔드 구현](#프론트엔드-구현)
3. [백엔드 처리 과정](#백엔드-처리-과정)
4. [주요 코드 포인트](#주요-코드-포인트)

---

## 전체 흐름도

```
┌─────────────┐
│  사용자 음성 │
└──────┬──────┘
       │ 🎤 마이크 입력
       ▼
┌─────────────────────────────────────────────────────┐
│ 프론트엔드 (agent.js)                                │
│ ─────────────────────────────────────────────────   │
│ 1. WebSocket 연결: ws://localhost:8000/stt/stream   │
│ 2. Float32Array(512) 오디오 청크 전송                │
└──────┬─────────────────────────────────ㅗ─────────────┘
       │ 📡 WebSocket
       ▼
┌─────────────────────────────────────────────────────┐
│ 백엔드 STT (main.py)                                │
│ ─────────────────────────────────────────────────   │
│ 1. VAD로 발화 종료 감지                              │
│ 2. Faster-Whisper로 텍스트 변환                      │
│ 3. 품질 평가 (successㅗ|medium|low_quality|no_speech) │
└──────┬──────────────────────────────────────────────┘
       │ 📤 {"text": "...", "quality": "success"}
       ▼
┌─────────────────────────────────────────────────────┐
│ 프론트엔드 (agent.js)                                │
│ ─────────────────────────────────────────────────   │
│ 1. STT 결과 수신                                     │
│ 2. 입력창에 텍스트 자동 입력                          │
│ 3. 0.1초 후 sendMessage() 자동 호출                 │
└──────┬──────────────────────────────────────────────┘
       │ 📡 HTTP POST
       ▼
┌─────────────────────────────────────────────────────┐
│ API 호출: POST /api/agent/v2/text                   │
│ ─────────────────────────────────────────────────   │
│ Headers:                                            │
│   Authorization: Bearer {jwt_token}                 │
│   Content-Type: application/json                    │
│                                                     │
│ Body:                                               │
│   {                                                 │
│     "user_text": "인식된 텍스트",                    │
│     "session_id": "user_1_uuid",                    │
│     "stt_quality": "success"                        │
│   }                                                 │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│ 백엔드 Agent V2 (agent_v2.py)                       │
│ ═════════════════════════════════════════════════   │
│                                                     │
│ ⏱️ FAST TRACK (즉시 실행)                           │
│ ───────────────────────────────────────────────     │
│ 1. 감정 분석 (EmotionAnalyzer)                      │
│    - 17개 감정 군집 분석                             │
│    - 긍정/부정/중립 판별                             │
│    - Service Signals 생성                           │
│                                                     │
│ 2. LLM 응답 생성 (OpenAI GPT-4o-mini)               │
│    - 시스템 프롬프트 작성:                           │
│      • 페르소나 (AI 상담사 봄이)                     │
│      • 사용자 정보 (이름, 나이 등)                   │
│      • 기억 (장기 메모리 from DB)                    │
│      • 대화 히스토리                                │
│      • 현재 감정 상태                                │
│    - LLM 호출 → reply_text 생성                     │
│                                                     │
│ 3. 대화 저장 (DB)                                   │
│    - TB_CONVERSATIONS에 user/assistant 메시지 저장   │
│                                                     │
│ ⏱️ SLOW TRACK (비동기 백그라운드)                    │
│ ───────────────────────────────────────────────     │
│ 4. 메모리 관리 (Memory Manager)                     │
│    - LLM으로 중요 정보 추출                          │
│    - TB_GLOBAL_MEMORIES에 저장/업데이트/삭제         │
│                                                     │
│ 5. 루틴 추천 (Routine Recommender)                  │
│    - RAG로 ChromaDB 검색                            │
│    - LLM으로 정제 및 설명 생성                       │
│    - 날씨/시간대 필터링                              │
│                                                     │
│ ⏱️ 타임아웃: Slow Track 최대 5초 대기               │
└──────┬──────────────────────────────────────────────┘
       │ 📤 JSON Response
       ▼
┌─────────────────────────────────────────────────────┐
│ 응답 데이터 (Response)                               │
│ ─────────────────────────────────────────────────   │
│ {                                                   │
│   "reply_text": "AI 응답 텍스트",                   │
│   "input_text": "사용자 입력",                      │
│   "emotion_result": { ... },                       │
│   "routine_result": [ ... ],                       │
│   "meta": {                                         │
│     "model": "gpt-4o-mini",                         │
│     "session_id": "...",                            │
│     "speaker_id": "user-A",                         │
│     "memory_used": true,                            │
│     "rag_used": false                               │
│   }                                                 │
│ }                                                   │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│ 프론트엔드 (agent.js)                                │
│ ─────────────────────────────────────────────────   │
│ 1. 응답 수신 및 UI 업데이트                          │
│ 2. 디버그 패널 업데이트 (감정/루틴/LLM 상태)         │
└──────┬──────────────────────────────────────────────┘
       │ 📡 HTTP POST
       ▼
┌─────────────────────────────────────────────────────┐
│ TTS 생성: POST /api/tts                             │
│ ─────────────────────────────────────────────────   │
│ Body:                                               │
│   {                                                 │
│     "text": "AI 응답 텍스트",                        │
│     "tone": "senior_calm",                          │
│     "engine": "melo"                                │
│   }                                                 │
└──────┬──────────────────────────────────────────────┘
       │ 📤 audio/wav
       ▼
┌─────────────────────────────────────────────────────┐
│ 프론트엔드 (agent.js)                                │
│ ─────────────────────────────────────────────────   │
│ 1. WAV Blob 수신                                    │
│ 2. URL.createObjectURL()로 재생 URL 생성            │
│ 3. Audio 객체로 자동 재생                            │
│ 4. 메시지에 재생 버튼(🔊) 추가                       │
└─────────────────────────────────────────────────────┘
```

---

## 프론트엔드 구현

### 1. STT (음성 인식)

**파일**: `frontend-test/agent.js` (라인 277-378)

```javascript
// 1. 마이크 권한 요청 + WebSocket 연결
async function startVoiceInput() {
    // 마이크 스트림 획득 (16kHz, 1채널)
    mediaStream = await navigator.mediaDevices.getUserMedia({
        audio: {
            channelCount: 1,
            sampleRate: 16000,
            echoCancellation: true,
            noiseSuppression: true
        }
    });

    // AudioContext 생성
    audioContext = new AudioContext({ sampleRate: 16000 });
    const source = audioContext.createMediaStreamSource(mediaStream);
    scriptProcessor = audioContext.createScriptProcessor(512, 1, 1);

    // WebSocket 연결
    sttWebSocket = new WebSocket('ws://localhost:8000/stt/stream');

    // 2. 오디오 청크를 WebSocket으로 전송
    scriptProcessor.onaudioprocess = (e) => {
        if (sttWebSocket && sttWebSocket.readyState === WebSocket.OPEN) {
            const inputData = e.inputBuffer.getChannelData(0);
            const float32Array = new Float32Array(inputData);
            sttWebSocket.send(float32Array.buffer);  // ✅ 512 샘플 전송
        }
    };

    // 3. STT 결과 수신
    sttWebSocket.onmessage = (event) => {
        handleSTTMessage(JSON.parse(event.data));
    };
}

// 4. STT 결과 처리
function handleSTTMessage(data) {
    if (data.text && data.text.trim()) {
        document.getElementById('userInput').value = data.text;
        stopVoiceInput();
        setTimeout(() => sendMessage(), 500);  // 자동 전송
    }
}
```

---

### 2. Agent API 호출

**파일**: `frontend-test/agent.js` (라인 477-580)

```javascript
async function sendMessage() {
    const text = input.value.trim();
    
    // 1. 사용자 메시지 UI에 추가
    appendMessage('user', text);
    
    // 2. Agent API 호출
    const token = getToken();  // JWT 토큰
    const response = await fetch(`${API_BASE}/api/agent/v2/text`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`  // ✅ 인증
        },
        body: JSON.stringify({
            user_text: text,
            session_id: currentSessionId  // 세션 ID
        })
    });

    const result = await response.json();
    
    // 3. 감정 분석 결과 표시
    if (result.emotion_result) {
        showToolContent('emotion', result.emotion_result);
    }
    
    // 4. 루틴 추천 결과 표시
    if (result.routine_result) {
        showToolContent('routine', result.routine_result);
    }
    
    // 5. TTS 생성 및 재생 (다음 단계)
    await generateAndPlayTTS(result.reply_text);
}
```

---

### 3. TTS (음성 합성)

**파일**: `frontend-test/agent.js` (라인 543-573)

```javascript
// 1. TTS API 호출
const ttsResponse = await fetch(`${API_BASE}/api/tts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
        text: result.reply_text,
        tone: "senior_calm",
        engine: "melo"
    })
});

// 2. WAV Blob 수신 및 재생
if (ttsResponse.ok) {
    const blob = await ttsResponse.blob();
    const url = URL.createObjectURL(blob);
    const audio = new Audio(url);
    audio.play();  // ✅ 자동 재생

    // 3. 메시지에 재생 버튼 추가
    appendMessage('assistant', result.reply_text, null, url);
}
```

---

## 백엔드 처리 과정

### 1. STT WebSocket 엔드포인트

**파일**: `backend/main.py` (라인 488-580)

```python
@app.websocket("/stt/stream")
async def stt_websocket(websocket: WebSocket):
    await websocket.accept()
    engine = get_stt_engine()  # Faster-Whisper
    
    while True:
        data = await websocket.receive()
        
        if "bytes" in data:
            audio_bytes = data["bytes"]
            audio_chunk = np.frombuffer(audio_bytes, dtype=np.float32)
            
            # VAD로 발화 종료 감지
            is_speech_end, speech_audio, _ = engine.vad.process_chunk(audio_chunk)
            
            if is_speech_end and speech_audio is not None:
                # Whisper로 텍스트 변환
                transcript, quality = engine.whisper.transcribe(speech_audio)
                
                # 결과 전송
                await websocket.send_json({
                    "text": transcript,
                    "quality": quality  # success|medium|low_quality|no_speech
                })
```

---

### 2. Agent V2 메인 로직

**파일**: `backend/engine/langchain_agent/agent_v2.py` (라인 10-100)

```python
async def run_ai_bomi_from_text_v2(
    user_text: str,
    user_id: int,
    session_id: str,
    stt_quality: str = None,
    speaker_id: str = None
):
    # ═══════════════════════════════════════
    # FAST TRACK (즉시 실행)
    # ═══════════════════════════════════════
    
    # 1️⃣ 감정 분석
    emotion_result = emotion_analyzer.analyze_emotion(user_text)
    
    # 2️⃣ 시스템 프롬프트 작성
    persona = "당신은 갱년기 여성을 위한 AI 상담사 봄이입니다..."
    user_info = get_user_info(user_id)  # DB에서 사용자 정보 조회
    memories = get_memories_for_prompt(session_id, user_id)  # 장기 기억
    history = store.get_history(user_id, session_id, limit=20)  # 대화 이력
    
    system_prompt = f"{persona}\n\n{user_info}\n\n{memories}"
    
    # 3️⃣ LLM 호출
    messages = [{"role": "system", "content": system_prompt}]
    messages.extend(history)
    messages.append({"role": "user", "content": user_text})
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages
    )
    reply_text = response.choices[0].message.content
    
    # 4️⃣ 대화 저장
    store.add_message(user_id, session_id, "user", user_text)
    store.add_message(user_id, session_id, "assistant", reply_text)
    
    # ═══════════════════════════════════════
    # SLOW TRACK (비동기 백그라운드, 최대 5초)
    # ═══════════════════════════════════════
    slow_results = await asyncio.wait_for(
        run_slow_track(user_id, session_id, user_text, emotion_result),
        timeout=5.0
    )
    
    return {
        "reply_text": reply_text,
        "emotion_result": emotion_result,
        "routine_result": slow_results.get("routine"),
        "meta": { ... }
    }
```

---

### 3. Slow Track (메모리 + 루틴)

**파일**: `backend/engine/langchain_agent/agent_v2.py` (라인 78-200)

```python
async def run_slow_track(user_id, session_id, user_text, emotion_result):
    # 병렬 실행
    memory_task = asyncio.create_task(memory_manager())
    routine_task = asyncio.create_task(routine_recommender())
    
    await asyncio.gather(memory_task, routine_task)
    
    # ──────────────────────────────────
    # 메모리 관리자
    # ──────────────────────────────────
    async def memory_manager():
        # 기존 기억 조회
        existing_memories = get_memories_for_prompt(session_id, user_id)
        
        # LLM에게 분석 요청
        memory_prompt = f"""
        중요 정보를 추출하세요.
        기존 기억: {existing_memories}
        새 대화: {user_text}
        
        출력: JSON
        {{
          "action": "create|update|delete",
          "category": "health|emotion|preference|info",
          "content": "저장할 내용",
          "importance": 1-5,
          "old_content_keyword": "삭제/수정할 키워드"
        }}
        """
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "system", "content": memory_prompt}]
        )
        
        # DB 저장/업데이트
        if action == "create":
            promote_memory(user_id, session_id, category, content, ...)
        elif action == "update":
            delete_memory(user_id, old_keyword)
            promote_memory(user_id, session_id, category, content, ...)
        elif action == "delete":
            delete_memory(user_id, old_keyword)
    
    # ──────────────────────────────────
    # 루틴 추천자
    # ──────────────────────────────────
    async def routine_recommender():
        # 1. RAG 검색 (ChromaDB)
        candidates = retrieve_candidates(emotion_result, top_k=20)
        
        # 2. LLM으로 정제
        recommendations = select_and_explain_routines(
            emotion=emotion_result,
            candidates=candidates,
            max_recommend=9
        )
        
        # 3. 날씨/시간대 필터링
        final = filter_by_weather_and_time(recommendations)
        
        return final
```

---

### 4. TTS 엔드포인트

**파일**: `backend/main.py` (라인 949-995)

```python
@app.post("/api/tts")
async def tts(request: Request):
    raw = await request.body()
    payload = json.loads(raw.decode("utf-8"))
    
    text = payload.get("text")
    tone = payload.get("tone", "senior_calm")
    engine_name = payload.get("engine", "melo")
    
    # MeloTTS로 음성 생성
    wav_path = synthesize_to_wav(
        text=text,
        tone=tone,
        engine=engine_name
    )
    
    # WAV 파일 반환
    return FileResponse(
        path=str(wav_path),
        media_type="audio/wav"
    )
```

---

## 주요 코드 포인트

### 프론트엔드

| 기능 | 파일 | 라인 | 설명 |
|------|------|------|------|
| STT WebSocket | `agent.js` | 298 | `ws://localhost:8000/stt/stream` 연결 |
| 오디오 전송 | `agent.js` | 320-326 | Float32Array(512) 전송 |
| Agent API 호출 | `agent.js` | 505-515 | `POST /api/agent/v2/text` |
| TTS 호출 | `agent.js` | 547-551 | `POST /api/tts` |
| 음성 재생 | `agent.js` | 554-560 | Blob → Audio 재생 |

### 백엔드

| 기능 | 파일 | 라인 | 설명 |
|------|------|------|------|
| STT WebSocket | `main.py` | 488-580 | VAD + Whisper |
| Agent 엔트리포인트 | `main.py` | 259-323 | `/api/agent/v2/text` |
| Agent 메인 로직 | `agent_v2.py` | 10-100 | Fast Track + Slow Track |
| 감정 분석 | `agent_v2.py` | 35 | `emotion_analyzer.analyze_emotion()` |
| LLM 호출 | `agent_v2.py` | 245-260 | OpenAI GPT-4o-mini |
| 메모리 관리 | `agent_v2.py` | 97-197 | Memory Manager |
| 루틴 추천 | `agent_v2.py` | 199-226 | RAG + LLM |
| TTS 생성 | `main.py` | 949-995 | MeloTTS |

---

## 타이밍 예시

| 단계 | 소요 시간 (예상) | 비고 |
|------|----------------|------|
| STT (음성→텍스트) | 300-800ms | VAD + Whisper |
| 감정 분석 | 200-500ms | LLM 1회 호출 |
| LLM 응답 생성 | 1-3초 | GPT-4o-mini |
| 대화 저장 | 50-100ms | DB INSERT |
| **Fast Track 총합** | **~2-4초** | 사용자가 기다리는 시간 |
| 메모리 관리 | 300-1000ms | LLM 1회 호출 (백그라운드) |
| 루틴 추천 | 1-2초 | RAG + LLM (백그라운드) |
| TTS 생성 | 500-1500ms | MeloTTS |
| 음성 재생 | 2-10초 | 텍스트 길이에 따라 다름 |

---

## 데이터 흐름 요약

1. **STT**: 마이크 → WebSocket → Whisper → `{"text": "..."}`
2. **Agent**: HTTP POST → 감정 분석 → LLM → DB 저장 → `{"reply_text": "..."}`
3. **TTS**: HTTP POST → MeloTTS → `audio/wav` Blob
4. **재생**: Blob → Audio 객체 → 스피커
5. **백그라운드**: 메모리 저장 + 루틴 추천 (5초 내)
