# API 엔드포인트 문서 (API Endpoints Documentation)

## 목차 (Table of Contents)
- [인증 (Authentication)](#인증-authentication)
- [온보딩 설문 (Onboarding Survey)](#온보딩-설문-onboarding-survey)
- [AI 에이전트 (Agent)](#ai-에이전트-agent)
- [감정 분석 (Emotion Analysis)](#감정-분석-emotion-analysis)
- [루틴 추천 (Routine Recommendation)](#루틴-추천-routine-recommendation)
- [날씨 (Weather)](#날씨-weather)
- [일일 감정 체크 (Daily Mood Check)](#일일-감정-체크-daily-mood-check)
- [대시보드 (Dashboard)](#대시보드-dashboard)
- [사용자 페이즈 (User Phase)](#사용자-페이즈-user-phase)
- [관계 훈련 (Relation Training)](#관계-훈련-relation-training)
- [루틴 설문 (Routine Survey)](#루틴-설문-routine-survey)
- [갱년기 설문 (Menopause Survey)](#갱년기-설문-menopause-survey)
- [음성 인식 (STT)](#음성-인식-stt)
- [음성 합성 (TTS)](#음성-합성-tts)
- [디버그/정리 (Debug/Cleanup)](#디버그정리-debugcleanup)

---

## 인증 (Authentication)

### 1. Google OAuth 로그인
**경로**: `POST /auth/google`  
**인증**: 불필요  
**설명**: Google OAuth를 통한 로그인 (Authorization Code 방식)  

**요청 Body**:
```json
{
  "auth_code": "string",      // Google Authorization Code
  "redirect_uri": "string"    // OAuth Redirect URI
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
    "nickname": "string",
    "provider": "google",
    "created_at": "datetime"
  }
}
```

### 2. Kakao OAuth 로그인
**경로**: `POST /auth/kakao`  
**인증**: 불필요  
**설명**: Kakao OAuth를 통한 로그인 (Authorization Code 방식)  

**요청 Body**:
```json
{
  "auth_code": "string",      // Kakao Authorization Code
  "redirect_uri": "string"    // OAuth Redirect URI
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
    "nickname": "string",
    "provider": "kakao",
    "created_at": "datetime"
  }
}
```

### 3. Naver OAuth 로그인
**경로**: `POST /auth/naver`  
**인증**: 불필요  
**설명**: Naver OAuth를 통한 로그인 (Authorization Code 방식)  

**요청 Body**:
```json
{
  "auth_code": "string",      // Naver Authorization Code
  "state": "string"           // CSRF 방지용 State 값
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
    "nickname": "string",
    "provider": "naver",
    "created_at": "datetime"
  }
}
```

### 4. 토큰 갱신
**경로**: `POST /auth/refresh`  
**인증**: 불필요  
**설명**: Refresh Token으로 Access Token 갱신 (RTR 전략)  

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
  "refresh_token": "string",
  "token_type": "bearer"
}
```

### 5. 로그아웃
**경로**: `POST /auth/logout`  
**인증**: 필요 (Bearer Token)  
**설명**: 로그아웃 및 Refresh Token 무효화  

**응답**:
```json
{
  "message": "Logged out successfully"
}
```

### 6. 현재 사용자 정보 조회
**경로**: `GET /auth/me`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 로그인한 사용자 정보 조회  

**응답**:
```json
{
  "id": "integer",
  "email": "string",
  "nickname": "string",
  "provider": "google|kakao|naver",
  "created_at": "datetime"
}
```

### 7. OAuth 설정 조회
**경로**: `GET /auth/config`  
**인증**: 불필요  
**설명**: 프론트엔드용 OAuth Client ID 조회  

**응답**:
```json
{
  "google_client_id": "string",
  "kakao_client_id": "string",
  "naver_client_id": "string"
}
```

### 8. 헬스 체크
**경로**: `GET /auth/health`  
**인증**: 불필요  
**설명**: 인증 서비스 상태 확인  

**응답**:
```json
{
  "status": "ok",
  "service": "authentication"
}
```

### 9. Google OAuth 콜백
**경로**: `GET /auth/callback/google`  
**인증**: 불필요  
**설명**: Google OAuth 콜백 처리 및 앱 스킴으로 리다이렉트  

**Query Parameters**:
- `code` (string): Authorization Code
- `state` (optional, string): State 값

**응답**: 앱 스킴으로 리다이렉트 (`com.maeumbom.app://auth/callback`)

### 10. Kakao OAuth 콜백
**경로**: `GET /auth/callback/kakao`  
**인증**: 불필요  
**설명**: Kakao OAuth 콜백 처리 및 앱 스킴으로 리다이렉트  

**Query Parameters**:
- `code` (string): Authorization Code

**응답**: 앱 스킴으로 리다이렉트 (`com.maeumbom.app://auth/callback`)

### 11. Naver OAuth 콜백
**경로**: `GET /auth/callback/naver`  
**인증**: 불필요  
**설명**: Naver OAuth 콜백 처리 및 앱 스킴으로 리다이렉트  

**Query Parameters**:
- `code` (string): Authorization Code
- `state` (string): State 값

**응답**: HTML 페이지로 앱 스킴 리다이렉트 (`com.maeumbom.app://auth/callback`)

---

## 온보딩 설문 (Onboarding Survey)

### 1. 설문 제출/수정
**경로**: `POST /api/onboarding-survey/submit`  
**인증**: 필요 (Bearer Token)  
**설명**: 온보딩 설문 제출 또는 수정 (Upsert 방식)  

**요청 Body**:
```json
{
  "nickname": "봄이",
  "age_group": "50대",
  "gender": "여성",
  "marital_status": "기혼",
  "children_yn": "있음",
  "living_with": ["배우자와", "자녀와"],
  "personality_type": "외향적",
  "activity_style": "활동적인게 좋아요",
  "stress_relief": ["산책을 해요", "누군가와 대화를 나눠요", "취미 활동을 해요"],
  "hobbies": ["산책", "음악감상", "독서"],
  "atmosphere": []
}
```

**필드 설명**:
- `nickname`: 닉네임 (Q1)
- `age_group`: 연령대 (Q2) - '40대', '50대', '60대', '70대 이상'
- `gender`: 성별 (Q3) - '여성', '남성'
- `marital_status`: 결혼 여부 (Q4) - '미혼', '기혼', '이혼/사별', '말하고 싶지 않음'
- `children_yn`: 자녀 유무 (Q5) - '있음', '없음'
- `living_with`: 동거인 (Q6, 다중선택) - ["혼자", "배우자와", "자녀와", "부모님과", "가족과 함께", "기타"]
- `personality_type`: 성향 (Q7) - '내향적', '외향적', '상황에따라'
- `activity_style`: 활동 스타일 (Q8) - '조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'
- `stress_relief`: 스트레스 해소법 (Q9, 다중선택) - ["혼자 조용히 해결해요", "누군가와 대화를 나눠요", "산책을 해요", "운동을 해요", "취미 활동을 해요", "그냥 잊고 넘어가요", "바로 감정이 격해져요", "기타"]
- `hobbies`: 취미 (Q10, 다중선택) - ["등산", "산책", "음악감상", "독서", "영화/드라마", "요리", "정원/식물", "반려동물", "여행", "정리정돈", "공예/DIY", "기타"]
- `atmosphere`: 선호 분위기 (Q11, 다중선택, optional) - ["잔잔한 분위기", "밝고 명랑한 분위기", "감성적인 스타일", "차분함", "활발함", "따뜻하고 부드러운 느낌"] (현재 프론트엔드 미구현, 빈 배열로 전송)

**응답**:
```json
{
  "id": 1,
  "user_id": 123,
  "nickname": "봄이",
  "age_group": "50대",
  "gender": "여성",
  "marital_status": "기혼",
  "children_yn": "있음",
  "living_with": ["배우자와", "자녀와"],
  "personality_type": "외향적",
  "activity_style": "활동적인게 좋아요",
  "stress_relief": ["산책을 해요", "누군가와 대화를 나눠요", "취미 활동을 해요"],
  "hobbies": ["산책", "음악감상", "독서"],
  "atmosphere": [],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### 2. 내 프로필 조회
**경로**: `GET /api/onboarding-survey/me`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 로그인한 사용자의 온보딩 설문 프로필 조회  

**응답**:
```json
{
  "id": 1,
  "user_id": 123,
  "nickname": "봄이",
  "age_group": "50대",
  "gender": "여성",
  "marital_status": "기혼",
  "children_yn": "있음",
  "living_with": ["배우자와", "자녀와"],
  "personality_type": "외향적",
  "activity_style": "활동적인게 좋아요",
  "stress_relief": ["산책을 해요", "누군가와 대화를 나눠요", "취미 활동을 해요"],
  "hobbies": ["산책", "음악감상", "독서"],
  "atmosphere": [],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**에러 응답** (404):
```json
{
  "detail": "Profile not found. Please complete the onboarding survey."
}
```

### 3. 프로필 완료 여부 확인
**경로**: `GET /api/onboarding-survey/status`  
**인증**: 필요 (Bearer Token)  
**설명**: 사용자가 온보딩 설문을 완료했는지 확인  

**응답** (완료된 경우):
```json
{
  "has_profile": true,
  "profile": {
    "id": 1,
    "user_id": 123,
    "nickname": "봄이",
    "age_group": "50대",
    "gender": "여성",
    "marital_status": "기혼",
    "children_yn": "있음",
    "living_with": ["배우자와", "자녀와"],
    "personality_type": "외향적",
    "activity_style": "활동적인게 좋아요",
    "stress_relief": ["산책을 해요", "누군가와 대화를 나눠요", "취미 활동을 해요"],
    "hobbies": ["산책", "음악감상", "독서"],
    "atmosphere": [],
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

**응답** (미완료된 경우):
```json
{
  "has_profile": false,
  "profile": null
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

### 1. 일일 체크 상태 확인
**경로**: `GET /api/service/daily-mood-check/status`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 로그인한 사용자의 일일 체크 상태 확인  

**응답**:
```json
{
  "is_checked_today": "boolean",
  "last_check_date": "YYYY-MM-DD",
  "selected_image": {
    "id": "integer",
    "filename": "string",
    "sentiment": "positive|neutral|negative",
    "description": "string"
  }
}
```

### 2. 이미지 목록 조회
**경로**: `GET /api/service/daily-mood-check/images`  
**인증**: 필요 (Bearer Token)  
**설명**: 오늘의 랜덤 이미지 목록 반환 (부정/중립/긍정 각 1개씩, 이미 선택한 경우 저장된 이미지 반환)  

**응답**:
```json
{
  "images": [
    {
      "id": "integer",
      "filename": "string",
      "sentiment": "positive|neutral|negative",
      "description": "string",
      "url": "string"
    }
  ]
}
```

### 3. 이미지 선택 및 감정 분석
**경로**: `POST /api/service/daily-mood-check/select`  
**인증**: 필요 (Bearer Token)  
**설명**: 이미지 선택 및 감정 분석 트리거  

**요청 Body**:
```json
{
  "image_id": "integer",
  "filename": "string",           // 선택사항
  "sentiment": "string",          // 선택사항
  "displayed_images": []          // 선택사항: 프론트엔드에서 표시한 이미지 목록
}
```

**응답**:
```json
{
  "success": "boolean",
  "selected_image": {
    "id": "integer",
    "filename": "string",
    "sentiment": "positive|neutral|negative",
    "description": "string",
    "url": "string"
  },
  "emotion_result": { /* EmotionAnalysisResult */ },
  "message": "string",
  "is_update": "boolean"          // true: 오늘 이미 선택했던 것을 변경, false: 첫 선택
}
```

### 4. 이미지 파일 서빙
**경로**: `GET /api/service/daily-mood-check/images/{sentiment}/{filename}`  
**인증**: 불필요  
**설명**: 이미지 파일 직접 서빙  

**Path Parameters**:
- `sentiment` (string): 감정 분류 (negative, neutral, positive)
- `filename` (string): 이미지 파일명

**응답**: 이미지 파일 (image/jpeg, image/png, image/gif, image/webp)

### 5. 선택 기록 삭제
**경로**: `DELETE /api/service/daily-mood-check/cleanup/selections`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 사용자의 모든 기분 체크 기록 삭제  

**응답**:
```json
{
  "success": "boolean",
  "deleted_count": "integer",
  "message": "string"
}
```

### 6. 감정 분석 기록 삭제 (일일 체크)
**경로**: `DELETE /api/service/daily-mood-check/cleanup/emotion-analysis`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 사용자의 일일 감정 체크 감정 분석 기록 삭제  

**응답**:
```json
{
  "success": "boolean",
  "deleted_count": "integer",
  "message": "string"
}
```

### 7. 감정 분석 기록 삭제 (대화)
**경로**: `DELETE /api/service/daily-mood-check/cleanup/conversation-emotion-analysis`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 사용자의 대화 감정 분석 기록 삭제  

**응답**:
```json
{
  "success": "boolean",
  "deleted_count": "integer",
  "message": "string"
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

### 1. 건강 데이터 동기화
**경로**: `POST /api/service/user-phase/sync`  
**인증**: 필요 (Bearer Token)  
**설명**: 건강 데이터를 DB에 저장하고 Phase 계산
- **자동 동기화** (`source_type: "apple_health"` 또는 `"google_fit"`): `TB_HEALTH_LOGS`에 항상 추가 저장 (같은 날짜여도 새 레코드)
- **수동 입력** (`source_type: "manual"`): `TB_MANUAL_HEALTH_LOGS`에 사용자당 하나의 레코드만 업데이트

**요청 Body**:
```json
{
  "log_date": "YYYY-MM-DD",
  "sleep_start_time": "datetime",
  "sleep_end_time": "datetime",
  "step_count": "integer",
  "sleep_duration_hours": "float",
  "heart_rate_avg": "integer",
  "heart_rate_resting": "integer",
  "heart_rate_variability": "float",
  "active_minutes": "integer",
  "exercise_minutes": "integer",
  "calories_burned": "integer",
  "distance_km": "float",
  "source_type": "manual|apple_health|google_fit",
  "raw_data": {}
}
```

**응답**:
```json
{
  "current_phase": "morning|day|evening|sleep_prep",
  "hours_since_wake": "float",
  "hours_to_sleep": "float",
  "data_source": "pattern_analysis|user_setting",
  "message": "string",
  "health_data": {
    "sleep_duration_hours": "float",
    "heart_rate_avg": "integer",
    "heart_rate_resting": "integer",
    "heart_rate_variability": "float",
    "step_count": "integer",
    "active_minutes": "integer"
  }
}
```

### 2. 현재 Phase 조회
**경로**: `GET /api/service/user-phase/current`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 Phase 조회 (패턴 분석 결과 우선, 없으면 사용자 설정, 없으면 에러)  

**응답**:
```json
{
  "current_phase": "morning|day|evening|sleep_prep",
  "hours_since_wake": "float",
  "hours_to_sleep": "float",
  "data_source": "pattern_analysis|user_setting",
  "message": "string",
  "health_data": {
    "sleep_duration_hours": "float",
    "heart_rate_avg": "integer",
    "heart_rate_resting": "integer",
    "heart_rate_variability": "float",
    "step_count": "integer",
    "active_minutes": "integer"
  }
}
```

### 3. 사용자 설정 조회
**경로**: `GET /api/service/user-phase/settings`  
**인증**: 필요 (Bearer Token)  
**설명**: 사용자 수면 패턴 설정 조회  

**응답**:
```json
{
  "weekday_wake_time": "HH:MM",
  "weekday_sleep_time": "HH:MM",
  "weekend_wake_time": "HH:MM",
  "weekend_sleep_time": "HH:MM",
  "is_night_worker": "boolean",
  "last_analysis_date": "YYYY-MM-DD",
  "data_completeness": "float(0-1)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### 4. 사용자 설정 업데이트
**경로**: `PUT /api/service/user-phase/settings`  
**인증**: 필요 (Bearer Token)  
**설명**: 사용자 수면 패턴 설정 업데이트 (온보딩 또는 수동 설정)  

**요청 Body**:
```json
{
  "weekday_wake_time": "HH:MM",
  "weekday_sleep_time": "HH:MM",
  "weekend_wake_time": "HH:MM",
  "weekend_sleep_time": "HH:MM",
  "is_night_worker": "boolean"
}
```

**응답**:
```json
{
  "weekday_wake_time": "HH:MM",
  "weekday_sleep_time": "HH:MM",
  "weekend_wake_time": "HH:MM",
  "weekend_sleep_time": "HH:MM",
  "is_night_worker": "boolean",
  "last_analysis_date": "YYYY-MM-DD",
  "data_completeness": "float(0-1)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### 5. 주간 패턴 분석 (수동 트리거)
**경로**: `POST /api/service/user-phase/analyze`  
**인증**: 필요 (Bearer Token)  
**설명**: 지난 7일 건강 데이터를 분석하여 평일/주말 패턴 계산 (TB_HEALTH_LOGS 데이터만 사용)  

**응답**:
```json
{
  "weekday": {
    "avg_wake_time": "HH:MM",
    "avg_sleep_time": "HH:MM",
    "avg_sleep_duration": "float"
  },
  "weekend": {
    "avg_wake_time": "HH:MM",
    "avg_sleep_time": "HH:MM",
    "avg_sleep_duration": "float"
  },
  "last_analysis_date": "YYYY-MM-DD",
  "data_completeness": "float(0-1)",
  "analysis_period_days": "integer",
  "insight": "string"
}
```

**참고**: `weekend` 필드는 주말 데이터가 있을 때만 포함됩니다. 데이터가 없으면 `null`입니다.

### 6. 패턴 분석 결과 조회
**경로**: `GET /api/service/user-phase/pattern`  
**인증**: 필요 (Bearer Token)  
**설명**: 저장된 패턴 분석 결과 조회  

**응답**:
```json
{
  "weekday": {
    "avg_wake_time": "HH:MM",
    "avg_sleep_time": "HH:MM",
    "avg_sleep_duration": "float"
  },
  "weekend": {
    "avg_wake_time": "HH:MM",
    "avg_sleep_time": "HH:MM",
    "avg_sleep_duration": "float"
  },
  "last_analysis_date": "YYYY-MM-DD",
  "data_completeness": "float(0-1)",
  "analysis_period_days": "integer",
  "insight": "string"
}
```

**참고**: `weekend` 필드는 주말 데이터가 있을 때만 포함됩니다. 데이터가 없으면 `null`입니다.

---

## 관계 훈련 (Relation Training)

### 1. 시나리오 목록 조회
**경로**: `GET /api/service/relation-training/scenarios`  
**인증**: 필요 (Bearer Token)  
**설명**: 시나리오 목록 조회 (공용 시나리오 + 사용자별 시나리오)  

**Query Parameters**:
- `category` (optional, string): TRAINING|DRAMA

**응답**:
```json
{
  "scenarios": [
    {
      "id": "integer",
      "title": "string",
      "target_type": "parent|friend|partner|husband|wife",
      "category": "TRAINING|DRAMA",
      "is_user_created": "boolean",
      "user_id": "integer"
    }
  ],
  "total": "integer"
}
```

### 2. 시나리오 시작
**경로**: `GET /api/service/relation-training/scenarios/{scenario_id}/start`  
**인증**: 필요 (Bearer Token)  
**설명**: 시나리오 시작 - 첫 번째 노드 반환  

**응답**:
```json
{
  "scenario_id": "integer",
  "current_node": {
    "id": "integer",
    "step_level": "integer",
    "situation_text": "string",
    "image_url": "string",
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

### 3. 시나리오 진행
**경로**: `POST /api/service/relation-training/progress`  
**인증**: 필요 (Bearer Token)  
**설명**: 사용자가 선택지를 선택하면 다음 노드 또는 최종 결과 반환  

**요청 Body**:
```json
{
  "scenario_id": "integer",
  "current_node_id": "integer",
  "selected_option_code": "A|B|C",
  "current_path": "string"          // 예: "AAB"
}
```

**응답**:
```json
{
  "is_finished": "boolean",
  "next_node": {                    // is_finished=false일 때
    "id": "integer",
    "step_level": "integer",
    "situation_text": "string",
    "image_url": "string",
    "options": [
      {
        "id": "integer",
        "option_code": "A|B|C",
        "option_text": "string"
      }
    ]
  },
  "result": {                       // is_finished=true일 때
    "path": "string",
    "result_text": "string",
    "result_image_url": "string",
    "statistics": {                 // DRAMA 카테고리만
      "total_plays": "integer",
      "path_distribution": {
        "AAAA": "integer",
        "AAAB": "integer"
      }
    }
  }
}
```

### 4. Deep Agent 시나리오 자동 생성
**경로**: `POST /api/service/relation-training/generate-scenario`  
**인증**: 필요 (Bearer Token)  
**설명**: GPT-4o-mini로 시나리오 생성 + FLUX.1-schnell로 이미지 17장 자동 생성  

**요청 Body**:
```json
{
  "target": "PARENT|FRIEND|PARTNER|HUSBAND|WIFE",
  "topic": "string"                 // 예: "남편이 밥투정을 합니다"
}
```

**응답**:
```json
{
  "scenario_id": "integer",
  "status": "success",
  "image_count": "integer",
  "folder_name": "string",
  "message": "string"
}
```

**Note**: 이미지 생성은 8~34분 소요, `USE_SKIP_IMAGES=true` 설정 시 이미지 생성 스킵

### 5. 공용 시나리오 이미지 조회
**경로**: `GET /api/service/relation-training/images/{scenario_name}/{filename}`  
**인증**: 불필요  
**설명**: 공용 시나리오 이미지 파일 제공  

**Path Parameters**:
- `scenario_name` (string): 시나리오 폴더명 (예: husband_three_meals)
- `filename` (string): 이미지 파일명 (예: start.png, result_AAAA.png)

**응답**: 이미지 파일 (image/png)

### 6. 사용자별 시나리오 이미지 조회
**경로**: `GET /api/service/relation-training/images/{user_id}/{scenario_name}/{filename}`  
**인증**: 불필요  
**설명**: Deep Agent로 생성된 사용자별 시나리오 이미지 제공  

**Path Parameters**:
- `user_id` (integer): 사용자 ID
- `scenario_name` (string): 시나리오 폴더명 (예: husband_20231215_143022)
- `filename` (string): 이미지 파일명

**응답**: 이미지 파일 (image/png)

### 7. 시나리오 삭제
**경로**: `DELETE /api/service/relation-training/scenarios/{scenario_id}`  
**인증**: 필요 (Bearer Token)  
**설명**: 시나리오 삭제 (본인 소유만 가능, 공용 시나리오 삭제 불가)  

**응답**:
```json
{
  "success": "boolean",
  "message": "string",
  "deleted_scenario_id": "integer"
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

## 갱년기 설문 (Menopause Survey)

### 1. 갱년기 설문 제출
**경로**: `POST /api/menopause-survey/submit`  
**인증**: 불필요 (MVP 버전)  
**설명**: 갱년기 증상 설문 제출 및 위험도 평가  

**요청 Body**:
```json
{
  "gender": "FEMALE|MALE",
  "answers": [
    {
      "question_id": "integer",
      "answer_value": "integer"     // 0-3 점수
    }
  ]
}
```

**응답**:
```json
{
  "id": "integer",
  "total_score": "integer",
  "risk_level": "LOW|MID|HIGH",
  "comment": "string"
}
```

**위험도 기준**:
- LOW (0-9점): 비교적 안정적
- MID (10-19점): 갱년기 관련 신호 보임
- HIGH (20점 이상): 전문의 상담 권장

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

### 2. 세션 메모리 완전 삭제
**경로**: `DELETE /api/agent/cleanup/session-memories`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 유저의 모든 세션 메모리 완전 삭제  

**응답**:
```json
{
  "status": "success",
  "message": "Deleted X session memory records",
  "user_id": "integer"
}
```

### 3. 전역 메모리 완전 삭제
**경로**: `DELETE /api/agent/cleanup/global-memories`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 유저의 모든 전역 메모리 완전 삭제  

**응답**:
```json
{
  "status": "success",
  "message": "Deleted X global memory records",
  "user_id": "integer"
}
```

### 4. 대화 기록 삭제 (디버그)
**경로**: `DELETE /api/debug/cleanup/history`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 유저의 모든 대화 기록 삭제  

**응답**:
```json
{
  "status": "success",
  "message": "Deleted X conversation records",
  "user_id": "integer"
}
```

### 5. 메모리 데이터 삭제 (디버그)
**경로**: `DELETE /api/debug/cleanup/memories`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 유저의 모든 전역 메모리 삭제  

**응답**:
```json
{
  "status": "success",
  "message": "Deleted X global memories",
  "user_id": "integer"
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

---

## API 경로 요약표

### 인증 (Authentication)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/auth/google` | ❌ | Google OAuth 로그인 |
| POST | `/auth/kakao` | ❌ | Kakao OAuth 로그인 |
| POST | `/auth/naver` | ❌ | Naver OAuth 로그인 |
| POST | `/auth/refresh` | ❌ | 토큰 갱신 |
| POST | `/auth/logout` | ✅ | 로그아웃 |
| GET | `/auth/me` | ✅ | 현재 사용자 정보 조회 |
| GET | `/auth/config` | ❌ | OAuth 설정 조회 |
| GET | `/auth/health` | ❌ | 헬스 체크 |
| GET | `/auth/callback/google` | ❌ | Google OAuth 콜백 |
| GET | `/auth/callback/kakao` | ❌ | Kakao OAuth 콜백 |
| GET | `/auth/callback/naver` | ❌ | Naver OAuth 콜백 |

### 온보딩 설문 (Onboarding Survey)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/onboarding-survey/submit` | ✅ | 설문 제출/수정 (Upsert) |
| GET | `/api/onboarding-survey/me` | ✅ | 내 프로필 조회 |
| GET | `/api/onboarding-survey/status` | ✅ | 프로필 완료 여부 확인 |

### AI 에이전트 (Agent)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/agent/v2/text` | ✅ | 텍스트 기반 대화 |
| GET | `/api/agent/v2/sessions` | ✅ | 세션 목록 조회 |
| GET | `/api/agent/v2/sessions/{session_id}` | ✅ | 세션 히스토리 조회 |
| DELETE | `/api/agent/v2/sessions/{session_id}` | ✅ | 세션 삭제 |
| WS | `/agent/stream` | ❌ | Agent + STT WebSocket |

### 감정 분석 (Emotion Analysis)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/emotion/api/analyze` | ❌ | 감정 분석 수행 |
| POST | `/api/analyze` | ❌ | 감정 분석 수행 (alias) |
| POST | `/emotion/api/init` | ❌ | Vector DB 초기화 |
| POST | `/api/init` | ❌ | Vector DB 초기화 (alias) |

### 루틴 추천 (Routine Recommendation)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/engine/routine-from-emotion` | ❌ | 감정 기반 루틴 추천 |
| POST | `/api/engine/routine-recommend-from-emotion` | ❌ | 감정 기반 루틴 추천 (alias) |

### 날씨 (Weather)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| GET | `/api/service/weather/current` | ❌ | 현재 날씨 조회 |

### 일일 감정 체크 (Daily Mood Check)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| GET | `/api/service/daily-mood-check/status` | ✅ | 일일 체크 상태 확인 |
| GET | `/api/service/daily-mood-check/images` | ✅ | 이미지 목록 조회 |
| POST | `/api/service/daily-mood-check/select` | ✅ | 이미지 선택 및 감정 분석 |
| GET | `/api/service/daily-mood-check/images/{sentiment}/{filename}` | ❌ | 이미지 파일 서빙 |
| DELETE | `/api/service/daily-mood-check/cleanup/selections` | ✅ | 선택 기록 삭제 |
| DELETE | `/api/service/daily-mood-check/cleanup/emotion-analysis` | ✅ | 감정 분석 기록 삭제 (일일 체크) |
| DELETE | `/api/service/daily-mood-check/cleanup/conversation-emotion-analysis` | ✅ | 감정 분석 기록 삭제 (대화) |

### 대시보드 (Dashboard)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| GET | `/api/dashboard/emotion-history` | ✅ | 감정 이력 조회 |

### 사용자 페이즈 (User Phase)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/service/user-phase/sync` | ✅ | 건강 데이터 동기화 |
| GET | `/api/service/user-phase/current` | ✅ | 현재 Phase 조회 |
| GET | `/api/service/user-phase/settings` | ✅ | 사용자 설정 조회 |
| PUT | `/api/service/user-phase/settings` | ✅ | 사용자 설정 업데이트 |
| POST | `/api/service/user-phase/analyze` | ✅ | 주간 패턴 분석 |
| GET | `/api/service/user-phase/pattern` | ✅ | 패턴 분석 결과 조회 |

### 관계 훈련 (Relation Training)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| GET | `/api/service/relation-training/scenarios` | ✅ | 시나리오 목록 조회 |
| GET | `/api/service/relation-training/scenarios/{scenario_id}/start` | ✅ | 시나리오 시작 |
| POST | `/api/service/relation-training/progress` | ✅ | 시나리오 진행 |
| POST | `/api/service/relation-training/generate-scenario` | ✅ | Deep Agent 시나리오 자동 생성 |
| GET | `/api/service/relation-training/images/{scenario_name}/{filename}` | ❌ | 공용 시나리오 이미지 조회 |
| GET | `/api/service/relation-training/images/{user_id}/{scenario_name}/{filename}` | ❌ | 사용자별 시나리오 이미지 조회 |
| DELETE | `/api/service/relation-training/scenarios/{scenario_id}` | ✅ | 시나리오 삭제 |

### 루틴 설문 (Routine Survey)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| GET | `/api/routine-survey` | ❌ | 설문 조회 |
| POST | `/api/routine-survey/submit` | ✅ | 설문 제출 |

### 갱년기 설문 (Menopause Survey)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/menopause-survey/submit` | ✅ | 갱년기 설문 제출 |
| GET | `/api/menopause-survey/questions` | ✅ | 갱년기 설문 질문 조회 |
### 음성 인식 (STT)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| WS | `/stt/stream` | ❌ | STT WebSocket |

### 음성 합성 (TTS)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/tts` | ❌ | 텍스트 음성 변환 |

### 디버그/정리 (Debug/Cleanup)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| DELETE | `/api/agent/cleanup/conversations` | ✅ | 대화 내역 완전 삭제 |
| DELETE | `/api/agent/cleanup/session-memories` | ✅ | 세션 메모리 완전 삭제 |
| DELETE | `/api/agent/cleanup/global-memories` | ✅ | 전역 메모리 완전 삭제 |
| DELETE | `/api/debug/cleanup/history` | ✅ | 대화 기록 삭제 (디버그) |
| DELETE | `/api/debug/cleanup/memories` | ✅ | 메모리 데이터 삭제 (디버그) |

### 기타 (Miscellaneous)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| GET | `/health` | ❌ | 헬스 체크 |
| GET | `/` | ❌ | Root 정보 |

---

**총 엔드포인트 수**: 63개  
**인증 필요**: 36개 | **인증 불필요**: 27개
