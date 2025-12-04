# API 엔드포인트 문서 (API Endpoints Documentation)

## 목차 (Table of Contents)
- [인증 (Authentication)](#인증-authentication)
- [AI 에이전트 (Agent)](#ai-에이전트-agent)
- [감정 분석 (Emotion Analysis)](#감정-분석-emotion-analysis)
- [루틴 추천 (Routine Recommendation)](#루틴-추천-routine-recommendation)
- [날씨 (Weather)](#날씨-weather)
- [일일 감정 체크 (Daily Mood Check)](#일일-감정-체크-daily-mood-check)
- [대시보드 (Dashboard)](#대시보드-dashboard)
- [사용자 페이즈 (User Phase)](#사용자-페이즈-user-phase)
- [관계 훈련 (Relation Training)](#관계-훈련-relation-training)
- [루틴 설문 (Routine Survey)](#루틴-설문-routine-survey)
- [음성 인식 (STT)](#음성-인식-stt)
- [음성 합성 (TTS)](#음성-합성-tts)
- [디버그/정리 (Debug/Cleanup)](#디버그정리-debugcleanup)

---

## 인증 (Authentication)

### 1. Google OAuth 로그인
**경로**: `POST /auth/google/login`  
**인증**: 불필요  
**설명**: Google OAuth를 통한 로그인  

**요청 Body**:
```json
{
  "id_token": "string"  // Google ID Token
}
```

**응답**:
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "token_type": "bearer",
  "user": {
    "id": "integer",
    "email": "string",
    "nickname": "string"
  }
}
```

### 2. 토큰 갱신
**경로**: `POST /auth/refresh`  
**인증**: 불필요  
**설명**: Refresh Token으로 Access Token 갱신  

**요청 Body**:
```json
{
  "refresh_token": "string"
}
```

**응답**:
```json
{
  "access_token": "string",
  "token_type": "bearer"
}
```

### 3. 로그아웃
**경로**: `POST /auth/logout`  
**인증**: 필요 (Bearer Token)  
**설명**: 로그아웃 및 Refresh Token 무효화  

**응답**:
```json
{
  "message": "Logged out successfully"
}
```

---

## AI 에이전트 (Agent)

### 1. 텍스트 기반 대화
**경로**: `POST /api/agent/v2/text`  
**인증**: 필요 (Bearer Token)  
**설명**: 텍스트 입력을 통한 AI 대화  

**요청 Body**:
```json
{
  "user_text": "string",             // 필수: 사용자 입력
  "session_id": "string",            // 선택: 세션 ID (기본값: user_{user_id}_default)
  "stt_quality": "success|medium|low_quality|no_speech"  // 선택: STT 품질
}
```

**응답**:
```json
{
  "reply_text": "string",
  "input_text": "string",
  "emotion_result": { /* EmotionAnalysisResult */ },
  "routine_result": [ /* RoutineRecommendationItem[] */ ],
  "meta": {
    "model": "string",
    "used_tools": ["string"],
    "session_id": "string",
    "stt_quality": "string",
    "speaker_id": "string",
    "memory_used": "boolean",
    "rag_used": "boolean",
    "user_id": "integer",
    "storage": "database",
    "api_version": "v2_deepagents"
  }
}
```

### 2. 세션 목록 조회
**경로**: `GET /api/agent/v2/sessions`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 사용자의 모든 대화 세션 조회  

**응답**:
```json
{
  "user_id": "integer",
  "session_count": "integer",
  "sessions": [
    {
      "session_id": "string",
      "created_at": "datetime",
      "message_count": "integer"
    }
  ]
}
```

### 3. 세션 히스토리 조회
**경로**: `GET /api/agent/v2/sessions/{session_id}`  
**인증**: 필요 (Bearer Token)  
**설명**: 특정 세션의 대화 내역 조회  

**Query Parameters**:
- `limit` (optional, integer): 메시지 제한 개수

**응답**:
```json
{
  "session_id": "string",
  "user_id": "integer",
  "metadata": {},
  "message_count": "integer",
  "messages": [
    {
      "role": "user|assistant",
      "content": "string",
      "created_at": "datetime"
    }
  ]
}
```

### 4. 세션 삭제
**경로**: `DELETE /api/agent/v2/sessions/{session_id}`  
**인증**: 필요 (Bearer Token)  
**설명**: 특정 세션 삭제 (Soft Delete: IS_DELETED='Y')  

**응답**:
```json
{
  "status": "success",
  "message": "Session {session_id} soft deleted",
  "user_id": "integer",
  "session_id": "string"
}
```

---

## 감정 분석 (Emotion Analysis)

### 1. 감정 분석 수행
**경로**: `POST /emotion/api/analyze` 또는 `POST /api/analyze`  
**인증**: 불필요  
**설명**: 텍스트 감정 분석 (17개 감정 군집)  

**요청 Body**:
```json
{
  "text": "string",
  "language": "ko"  // 기본값
}
```

**응답**:
```json
{
  "text": "string",
  "language": "ko",
  "raw_distribution": [
    {
      "code": "joy|sadness|anger|...",
      "name_ko": "기쁨|슬픔|화|...",
      "group": "positive|negative",
      "score": "float(0-1)"
    }
  ],
  "primary_emotion": {
    "code": "string",
    "name_ko": "string",
    "group": "positive|negative",
    "score": "float",
    "intensity": "integer(1-5)"
  },
  "secondary_emotions": [...],
  "sentiment_overall": "positive|neutral|negative",
  "mixed_emotion": {
    "is_mixed": "boolean",
    "dominant_group": "positive|negative",
    "positive_ratio": "float",
    "negative_ratio": "float",
    "mixed_ratio": "float"
  },
  "service_signals": {
    "need_empathy": "boolean",
    "need_routine_recommend": "boolean",
    "need_health_check": "boolean",
    "need_voice_analysis": "boolean",
    "risk_level": "normal|watch|alert|critical"
  },
  "recommended_response_style": ["string"],
  "recommended_routine_tags": ["string"],
  "report_tags": ["string"]
}
```

### 2. Vector DB 초기화
**경로**: `POST /emotion/api/init` 또는 `POST /api/init`  
**인증**: 불필요  
**설명**: 감정 분석용 Vector DB 초기화  

**응답**:
```json
{
  "status": "success",
  "message": "Vector DB initialized"
}
```

---

## 루틴 추천 (Routine Recommendation)

### 1. 감정 기반 루틴 추천
**경로**: `POST /api/engine/routine-from-emotion`  
**인증**: 불필요  
**설명**: 감정 분석 결과를 기반으로 루틴 추천 (RAG + LLM)  

**요청 Body**:
```json
{
  /* EmotionAnalysisResult 전체 객체 */
  "city": "Seoul",     // 선택: 날씨 반영
  "country": "KR"      // 기본값: KR
}
```

**응답**:
```json
[
  {
    "routine_id": "string",
    "title": "string",
    "description": "string",
    "category": "EMOTION_*|BODY_*|TIME_*",
    "tags": ["string"],
    "reason": "string",
    "ui_message": "string",
    "priority": "integer"
  }
]
```

---

## 날씨 (Weather)

### 1. 현재 날씨 조회
**경로**: `GET /api/service/weather/current`  
**인증**: 불필요  

**Query Parameters**:
- `city` (required, string): 도시 이름
- `country` (optional, string): 국가 코드 (기본값: KR)

**응답**:
```json
{
  "city": "string",
  "country": "string",
  "temperature_c": "float",
  "condition": "clear|cloudy|rain|snow|...",
  "is_rainy": "boolean",
  "updated_at": "datetime"
}
```

---

## 일일 감정 체크 (Daily Mood Check)

### 1. 이미지 선택지 생성
**경로**: `POST /api/service/daily-mood-check/select-images`  
**인증**: 필요 (Bearer Token)  
**설명**: 오늘의 감정을 나타내는 3개 이미지 선택지 생성  

**응답**:
```json
{
  "date": "YYYY-MM-DD",
  "images": [
    {
      "id": "integer",
      "filename": "string",
      "sentiment": "positive|neutral|negative",
      "description": "string"
    }
  ]
}
```

### 2. 이미지 선택 저장
**경로**: `POST /api/service/daily-mood-check/submit`  
**인증**: 필요 (Bearer Token)  

**요청 Body**:
```json
{
  "image_id": "integer",
  "selected_date": "YYYY-MM-DD"
}
```

**응답**:
```json
{
  "status": "success",
  "emotion_result": { /* EmotionAnalysisResult */ },
  "agent_response": "string"
}
```

### 3. 선택 이력 조회
**경로**: `GET /api/service/daily-mood-check/history`  
**인증**: 필요 (Bearer Token)  

**Query Parameters**:
- `days` (optional, integer): 조회 일수 (기본값: 7)

**응답**:
```json
{
  "history": [
    {
      "date": "YYYY-MM-DD",
      "image_id": "integer",
      "filename": "string",
      "sentiment": "positive|neutral|negative",
      "description": "string",
      "emotion_result": {}
    }
  ]
}
```

---

## 대시보드 (Dashboard)

### 1. 감정 이력 조회
**경로**: `GET /api/dashboard/emotion-history`  
**인증**: 필요 (Bearer Token)  

**Query Parameters**:
- `days` (optional, integer): 조회 기간 (기본값: 7)

**응답**:
```json
{
  "data": [
    {
      "created_at": "datetime",
      "sentiment_overall": "positive|neutral|negative",
      "primary_emotion": {},
      "service_signals": {},
      "check_root": "conversation|daily_mood_check"
    }
  ]
}
```

---

## 사용자 페이즈 (User Phase)

### 1. 건강 데이터 업로드
**경로**: `POST /api/user-phase/health-logs`  
**인증**: 필요 (Bearer Token)  

**요청 Body**:
```json
{
  "log_date": "YYYY-MM-DD",
  "sleep_start_time": "datetime",
  "sleep_end_time": "datetime",
  "step_count": "integer",
  "source_type": "manual|apple_health|google_fit"
}
```

**응답**:
```json
{
  "status": "success",
  "log_id": "integer"
}
```

### 2. 패턴 분석
**경로**: `POST /api/user-phase/analyze-pattern`  
**인증**: 필요 (Bearer Token)  

**응답**:
```json
{
  "weekday_wake_time": "HH:MM:SS",
  "weekday_sleep_time": "HH:MM:SS",
  "weekend_wake_time": "HH:MM:SS",
  "weekend_sleep_time": "HH:MM:SS",
  "data_completeness": "float(0-1)"
}
```

---

## 관계 훈련 (Relation Training)

### 1. 시나리오 목록 조회
**경로**: `GET /api/service/relation-training/scenarios`  
**인증**: 불필요  

**Query Parameters**:
- `category` (optional, string): TRAINING|DRAMA

**응답**:
```json
{
  "scenarios": [
    {
      "id": "integer",
      "title": "string",
      "target_type": "parent|friend|partner",
      "category": "TRAINING|DRAMA"
    }
  ]
}
```

### 2. 시나리오 시작
**경로**: `GET /api/service/relation-training/scenarios/{scenario_id}/start`  
**인증**: 필요 (Bearer Token)  

**응답**:
```json
{
  "scenario_id": "integer",
  "current_node": {
    "id": "integer",
    "step_level": "integer",
    "situation_text": "string",
    "options": [
      {
        "id": "integer",
        "option_code": "A|B|C",
        "option_text": "string"
      }
    ]
  }
}
```

### 3. 선택지 제출
**경로**: `POST /api/service/relation-training/scenarios/{scenario_id}/choose`  
**인증**: 필요 (Bearer Token)  

**요청 Body**:
```json
{
  "option_id": "integer"
}
```

**응답**:
```json
{
  "next_node": { /* 다음 노드 정보 */ },
  "result": { /* 결과 (종료 시) */ }
}
```

---

## 루틴 설문 (Routine Survey)

### 1. 설문 조회
**경로**: `GET /api/routine-survey`  
**인증**: 불필요  

**응답**:
```json
{
  "survey_id": "integer",
  "questions": [
    {
      "id": "integer",
      "text": "string",
      "type": "single_choice|multiple_choice"
    }
  ]
}
```

### 2. 설문 제출
**경로**: `POST /api/routine-survey/submit`  
**인증**: 필요 (Bearer Token)  

**요청 Body**:
```json
{
  "survey_id": "integer",
  "answers": [
    {
      "question_id": "integer",
      "answer": "string"
    }
  ]
}
```

**응답**:
```json
{
  "status": "success",
  "response_id": "integer"
}
```

---

## 음성 인식 (STT)

### 1. STT WebSocket
**경로**: `WS /stt/stream`  
**인증**: 불필요  
**설명**: 실시간 음성 인식 스트리밍  

**수신 메시지**:
- `{"status": "connecting"}` - 초기화 중
- `{"status": "ready"}` - 준비 완료
- `{"text": "인식된 텍스트", "quality": "success|medium|low_quality|no_speech", "speaker_id": "user-A"}` - STT 결과

**송신 메시지**:
- 음성 데이터 (bytes): `Float32Array` (512 샘플)
- 명령: `{"text": "reset"}` - VAD 리셋

### 2. Agent + STT WebSocket
**경로**: `WS /agent/stream`  
**인증**: 불필요  
**설명**: STT + AI 에이전트 통합 WebSocket  

**수신 메시지**:
- `{"type": "status", "status": "connecting|ready|processing"}` - 상태
- `{"type": "stt_result", "text": "...", "quality": "...", "speaker_id": "..."}` - STT 결과
- `{"type": "agent_response", "data": {...}}` - AI 응답

**송신 메시지**:
- 음성 데이터 (bytes)
- 세션 ID 설정: `{"session_id": "string"}`

---

## 음성 합성 (TTS)

### 1. 텍스트 음성 변환
**경로**: `POST /api/tts`  
**인증**: 불필요  

**요청 Body**:
```json
{
  "text": "string",
  "speed": "float",           // 선택
  "tone": "senior_calm",      // 기본값
  "engine": "melo"            // 기본값
}
```

**응답**: WAV 파일 (audio/wav)

---

## 디버그/정리 (Debug/Cleanup)

### 1. 대화 내역 완전 삭제
**경로**: `DELETE /api/agent/cleanup/conversations`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 유저의 모든 대화 완전 삭제 (Hard Delete)  

**응답**:
```json
{
  "status": "success",
  "message": "Deleted X conversation records",
  "user_id": "integer"
}
```

### 2. 전역 메모리 완전 삭제
**경로**: `DELETE /api/agent/cleanup/global-memories`  
**인증**: 필요 (Bearer Token)  

**응답**:
```json
{
  "status": "success",
  "message": "Deleted X global memory records",
  "user_id": "integer"
}
```

### 3. 대화 + RAG 데이터 삭제
**경로**: `DELETE /api/debug/cleanup/history`  
**인증**: 필요 (Bearer Token)  

**응답**:
```json
{
  "status": "success",
  "message": "Deleted X conversation records and all RAG data for user Y"
}
```

### 4. 메모리 데이터 삭제
**경로**: `DELETE /api/debug/cleanup/memories`  
**인증**: 필요 (Bearer Token)  

**응답**:
```json
{
  "status": "success",
  "message": "Deleted X session memories and Y global memories for user Z"
}
```

---

## 기타 (Miscellaneous)

### 1. 헬스 체크
**경로**: `GET /health`  
**인증**: 불필요  

**응답**:
```json
{
  "status": "ok"
}
```

### 2. Root 정보
**경로**: `GET /`  
**인증**: 불필요  

**응답**:
```json
{
  "message": "Team Project API",
  "version": "1.0.0",
  "docs": "/docs",
  "modules": {
    "emotion_analysis": "/emotion/api",
    "stt": "/stt/stream"
  }
}
```

---

## 인증 헤더 형식

JWT 인증이 필요한 엔드포인트는 다음 헤더 포함:
```
Authorization: Bearer {access_token}
```

## 에러 응답 형식

모든 에러는 다음 형식을 따릅니다:
```json
{
  "detail": "Error message description"
}
```

HTTP 상태 코드:
- `200`: 성공
- `400`: 잘못된 요청
- `401`: 인증 실패
- `403`: 권한 없음
- `404`: 리소스 없음
- `500`: 서버 오류
