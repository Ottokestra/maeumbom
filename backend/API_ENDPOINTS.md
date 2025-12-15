# API 엔드포인트 문서 (API Endpoints Documentation)

## 목차 (Table of Contents)
- [인증 (Authentication)](#인증-authentication)
- [온보딩 설문 (Onboarding Survey)](#온보딩-설문-onboarding-survey)
- [AI 에이전트 (Agent)](#ai-에이전트-agent)
- [감정 분석 (Emotion Analysis)](#감정-분석-emotion-analysis)
- [추천 (Recommendations)](#추천-recommendations)
- [루틴 추천 (Routine Recommendation)](#루틴-추천-routine-recommendation)
- [날씨 (Weather)](#날씨-weather)
- [일일 감정 체크 (Daily Mood Check)](#일일-감정-체크-daily-mood-check)
- [대시보드 (Dashboard)](#대시보드-dashboard)
- [사용자 페이즈 (User Phase)](#사용자-페이즈-user-phase)
- [관계 훈련 (Relation Training)](#관계-훈련-relation-training)
- [루틴 설문 (Routine Survey)](#루틴-설문-routine-survey)
- [갱년기 설문 (Menopause Survey)](#갱년기-설문-menopause-survey)
- [신조어 퀴즈 (Slang Quiz)](#신조어-퀴즈-slang-quiz)
- [대상별 이벤트 (Target Events)](#대상별-이벤트-target-events---마음서랍)
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
  "stt_quality": "success|medium|low_quality|no_speech",  // 선택: STT 품질
  "tts_enabled": "boolean"           // 선택: TTS 활성화 여부 (기본값: false)
}
```

**응답**:
```json
{
  "reply_text": "string",
  "input_text": "string",
  "emotion_result": { /* EmotionAnalysisResult */ },
  "routine_result": [ /* RoutineRecommendationItem[] */ ],
  "tts_audio_url": "string",        // 선택: TTS 오디오 URL (tts_enabled=true일 때)
  "tts_status": "ready|timeout|error",  // 선택: TTS 상태
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

### 2. 세션 기반 감정 분석
**경로**: `POST /emotion/api/analyze-session`  
**인증**: 필요 (Bearer Token)  
**설명**: 세션의 모든 사용자 메시지를 결합하여 감정 분석 (17개 감정 군집)  

**요청 Body**:
```json
{
  "session_id": "string"
}
```

**응답**:
```json
{
  "text": "string",
  "language": "ko",
  "raw_distribution": [...],
  "primary_emotion": {...},
  "secondary_emotions": [...],
  "sentiment_overall": "positive|neutral|negative",
  "mixed_emotion": {...},
  "service_signals": {...},
  "recommended_response_style": ["string"],
  "recommended_routine_tags": ["string"],
  "report_tags": ["string"],
  "analysis_id": "integer",
  "message_count": "integer"
}
```

### 3. Vector DB 초기화
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

## 추천 (Recommendations)

### 1. 감정 기반 명언 추천
**경로**: `POST /api/v1/recommendations/quote`  
**인증**: 불필요  
**설명**: 현재 감정 상태에 맞는 명언 추천  

**요청 Body**:
```json
{
  "emotion_label": "string",
  "language": "ko"  // 선택, 기본값: ko
}
```

**응답**:
```json
{
  "quotes": ["string"]
}
```

### 2. 감정 기반 음악 추천
**경로**: `POST /api/v1/recommendations/music`  
**인증**: 불필요  
**설명**: 감정에 맞춘 음악 클립 추천  

**요청 Body**:
```json
{
  "emotion_label": "string",
  "duration": "integer"  // 선택, 음악 길이(초)
}
```

**응답**:
```json
{
  "audio_url": "string"
}
```

### 3. 감정 기반 이미지 생성
**경로**: `POST /api/v1/recommendations/image`  
**인증**: 불필요  
**설명**: 감정 또는 프롬프트 기반 위로 이미지 생성  

**요청 Body**:
```json
{
  "prompt": "string",
  "emotion_label": "string"  // 선택
}
```

**응답**:
```json
{
  "image_url": "string"
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

### 1. 현재 날씨 조회 (도시명)
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

### 2. 현재 날씨 조회 (위도/경도)
**경로**: `GET /api/service/weather/current/location`  
**인증**: 불필요  

**Query Parameters**:
- `lat` (required, float): 위도
- `lon` (required, float): 경도

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
- `limit` (optional, integer): 조회할 레코드 수 (기본값: 100)

**응답**:
```json
[
  {
    "created_at": "datetime",
    "sentiment_overall": "positive|neutral|negative",
    "primary_emotion": {},
    "service_signals": {},
    "check_root": "conversation|daily_mood_check"
  }
]
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
**설명**: Gemini 2.5 Flash로 시나리오 생성 + Gemini 2.5 Flash Image로 이미지 17장 자동 생성 (비동기 처리)  

**요청 Body (관계 개선 훈련)**:
```json
{
  "target": "HUSBAND|CHILD|FRIEND|COLLEAGUE",
  "topic": "string",                 // 예: "남편이 밥투정을 합니다"
  "category": "TRAINING"             // 기본값
}
```

**요청 Body (드라마)**:
```json
{
  "target": "AUTO|HUSBAND|CHILD|FRIEND|COLLEAGUE",  // AUTO: AI가 자동 선택
  "topic": "AUTO|string",                           // AUTO: AI가 자동 창작
  "category": "DRAMA",
  "genre": "MAKJANG|ROMANCE|FAMILY"  // 필수
}
```

**응답 (비동기 처리)**:
```json
{
  "scenario_id": 0,  // 생성 중이므로 0
  "status": "processing",
  "image_count": 0,
  "folder_name": "",
  "message": "시나리오 생성이 시작되었습니다. 잠시 후 목록을 새로고침해주세요."
}
```

**Note**: 
- 시나리오 생성은 백그라운드에서 비동기로 처리됩니다 (약 20-30초 소요)
- `USE_SKIP_IMAGES=true` 설정 시 이미지 생성 스킵
- 드라마 시나리오는 공용 시나리오로 생성됩니다 (USER_ID = NULL)
- 드라마 시나리오는 모든 사용자가 볼 수 있습니다

### 5. 공용 시나리오 이미지 조회
**경로**: `GET /api/service/relation-training/images/{scenario_name}/{filename}`  
**인증**: 불필요  
**설명**: 공용 시나리오 이미지 파일 제공  

**Path Parameters**:
- `scenario_name` (string): 시나리오 폴더명 (예: husband_three_meals)
- `filename` (string): 이미지 파일명 (예: start.png, result_AAAA.png)

**응답**: 이미지 파일 (image/png)

### 6. 사용자별/드라마 시나리오 이미지 조회
**경로**: `GET /api/service/relation-training/images/{user_id}/{scenario_name}/{filename}`  
**인증**: 불필요  
**설명**: Deep Agent로 생성된 사용자별 시나리오 또는 드라마 시나리오 이미지 제공  

**Path Parameters**:
- `user_id` (string): 사용자 ID (숫자) 또는 "public" (드라마 시나리오)
- `scenario_name` (string): 시나리오 폴더명 (예: husband_20231215_143022 또는 차가운_심장에_피어난_꽃_20251211_151150)
- `filename` (string): 이미지 파일명 (예: start.png, result_AAAA.png)

**응답**: 이미지 파일 (image/png)

**예시**:
- 사용자별: `/api/service/relation-training/images/123/husband_20231215_143022/start.png`
- 드라마: `/api/service/relation-training/images/public/차가운_심장에_피어난_꽃_20251211_151150/start.png`

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
**경로**: `GET /api/routine-survey/questions`  
**인증**: 불필요  

**Query Parameters**:
- `survey_id` (optional, integer): 설문 ID

**응답**:
```json
[
  {
    "id": "integer",
    "text": "string",
    "type": "single_choice|multiple_choice",
    "order": "integer"
  }
]
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
      "answer_value": "Y|N"
    }
  ]
}
```

**응답**:
```json
{
  "survey_id": "integer",
  "result_id": "integer",
  "total_score": "integer",
  "risk_level": "string",
  "comment": "string",
  "taken_at": "datetime"
}
```

### 3. 내 설문 결과 조회
**경로**: `GET /api/routine-survey/results/me`  
**인증**: 필요 (Bearer Token)  
**설명**: 현재 로그인한 사용자의 최신 설문 결과 조회  

**Query Parameters**:
- `survey_id` (optional, integer): 설문 ID

**응답**:
```json
{
  "survey_id": "integer",
  "result_id": "integer",
  "total_score": "integer",
  "risk_level": "string",
  "comment": "string",
  "taken_at": "datetime"
}
```

**에러 응답** (404):
```json
{
  "detail": "설문 결과가 없습니다."
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

응답 예시
{
  "gender": "FEMALE",
  "total_score": 18,
  "risk_level": "HIGH",
  "risk_label": "심한 갱년기 의심",
  "risk_description": "최근 4주 동안 신체적/정신적 증상이 일상에 영향을 줄 정도로 나타나고 있습니다.",
  "recommendations": [
    "충분한 휴식과 수면 시간을 우선적으로 확보해 주세요.",
    "증상이 지속되거나 악화될 경우 전문의 상담을 권장합니다.",
    "규칙적인 운동과 균형 잡힌 식단이 도움이 될 수 있습니다."
  ]
}

GET /api/menopause-survey/questions?gender=FEMALE

[
  {
    "id": 1,
    "gender": "FEMALE",
    "code": "F1",
    "order_no": 1,
    "question_text": "일의 집중력이나 기억력이 예전 같지 않다고 느낀다.",
    "risk_when_yes": true,
    "positive_label": "그렇다",
    "negative_label": "아니다",
    "created_at": "2025-12-10T09:00:00",
    "updated_at": "2025-12-10T09:00:00"
  },
  {
    "id": 2,
    "gender": "FEMALE",
    "code": "F2",
    "order_no": 2,
    "question_text": "아무 이유 없이 짜증이 늘고 감정 기복이 심해졌다.",
    "risk_when_yes": true,
    "positive_label": "그렇다",
    "negative_label": "아니다",
    "created_at": "2025-12-10T09:00:00",
    "updated_at": "2025-12-10T09:00:00"
  }
]

### 2. 설문 문항 목록 조회
**경로**: `GET /api/menopause/questions`  
**인증**: 불필요  

**Query Parameters**:
- `gender` (optional, string): 성별 필터 (FEMALE 또는 MALE)
- `is_active` (optional, boolean): 활성화 여부 필터

**응답**:
```json
[
  {
    "id": "integer",
    "gender": "FEMALE|MALE",
    "code": "string",
    "order_no": "integer",
    "question_text": "string",
    "risk_when_yes": "boolean",
    "positive_label": "string",
    "negative_label": "string",
    "character_key": "string",
    "is_active": "boolean",
    "is_deleted": "boolean",
    "created_at": "datetime",
    "updated_at": "datetime"
  }
]
```

### 3. 설문 문항 단건 조회
**경로**: `GET /api/menopause/questions/{question_id}`  
**인증**: 불필요  

**응답**:
```json
{
  "id": "integer",
  "gender": "FEMALE|MALE",
  "code": "string",
  "order_no": "integer",
  "question_text": "string",
  "risk_when_yes": "boolean",
  "positive_label": "string",
  "negative_label": "string",
  "character_key": "string",
  "is_active": "boolean",
  "is_deleted": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

응답 예시
{
  "id": 1,
  "gender": "FEMALE",
  "code": "F1",
  "order_no": 1,
  "question_text": "일의 집중력이나 기억력이 예전 같지 않다고 느낀다.",
  "risk_when_yes": true,
  "positive_label": "그렇다",
  "negative_label": "아니다",
  "created_at": "2025-12-10T09:00:00",
  "updated_at": "2025-12-10T09:00:00"
}

### 4. 설문 문항 생성
**경로**: `POST /api/menopause/questions`  
**인증**: 불필요  

**요청 Body**:
```json
{
  "gender": "FEMALE|MALE",
  "code": "string",
  "order_no": "integer",
  "question_text": "string",
  "risk_when_yes": "boolean",
  "positive_label": "string",
  "negative_label": "string",
  "character_key": "string"
}
```

**응답**:
```json
{
  "id": "integer",
  "gender": "FEMALE|MALE",
  "code": "string",
  "order_no": "integer",
  "question_text": "string",
  "risk_when_yes": "boolean",
  "positive_label": "string",
  "negative_label": "string",
  "character_key": "string",
  "is_active": "boolean",
  "is_deleted": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### 5. 설문 문항 수정
**경로**: `PATCH /api/menopause/questions/{question_id}`  
**인증**: 불필요  

**요청 Body**:
```json
{
  "gender": "FEMALE|MALE",
  "code": "string",
  "order_no": "integer",
  "question_text": "string",
  "risk_when_yes": "boolean",
  "positive_label": "string",
  "negative_label": "string",
  "character_key": "string",
  "is_active": "boolean"
}
```

**응답**:
```json
{
  "id": "integer",
  "gender": "FEMALE|MALE",
  "code": "string",
  "order_no": "integer",
  "question_text": "string",
  "risk_when_yes": "boolean",
  "positive_label": "string",
  "negative_label": "string",
  "character_key": "string",
  "is_active": "boolean",
  "is_deleted": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

{
  "order_no": 3,
  "question_text": "최근 4주 동안 이유 없이 짜증이 늘고 감정 기복이 심해졌다."
}

응답 예시
{
  "id": 2,
  "gender": "FEMALE",
  "code": "F2",
  "order_no": 3,
  "question_text": "최근 4주 동안 이유 없이 짜증이 늘고 감정 기복이 심해졌다.",
  "risk_when_yes": true,
  "positive_label": "그렇다",
  "negative_label": "아니다",
  "created_at": "2025-12-10T09:00:00",
  "updated_at": "2025-12-10T09:20:00"
}

### 6. 설문 문항 삭제
**경로**: `DELETE /api/menopause/questions/{question_id}`  
**인증**: 불필요  
**설명**: 설문 문항 소프트 삭제  

**응답**:
```json
{
  "id": "integer",
  "gender": "FEMALE|MALE",
  "code": "string",
  "order_no": "integer",
  "question_text": "string",
  "risk_when_yes": "boolean",
  "positive_label": "string",
  "negative_label": "string",
  "character_key": "string",
  "is_active": "boolean",
  "is_deleted": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### 7. 기본 설문 문항 생성
**경로**: `POST /api/menopause/questions/seed-defaults`  
**인증**: 불필요  
**설명**: 기본 남/녀 설문 문항 10개씩을 한번에 생성 (존재하지 않는 코드만 추가)  

**응답**:
```json
[
  {
    "id": "integer",
    "gender": "FEMALE|MALE",
    "code": "string",
    "order_no": "integer",
    "question_text": "string",
    "risk_when_yes": "boolean",
    "positive_label": "string",
    "negative_label": "string",
    "character_key": "string",
    "is_active": "boolean",
    "is_deleted": "boolean",
    "created_at": "datetime",
    "updated_at": "datetime"
  }
]
```

## 주간 감정 리포트 (Weekly Emotion Report)

### 1. 주간 리포트 생성/재생성
**경로**: `POST /api/v1/reports/emotion/weekly/generate`  
**인증**: 필요 (Bearer Token)  
**설명**: 특정 주간에 대한 주간 감정 리포트를 새로 생성하거나 갱신  

**Query Parameters**:
- `weekStart` (required, string): 주 시작일 (YYYY-MM-DD)
- `weekEnd` (optional, string): 주 종료일 (YYYY-MM-DD), 기본값: weekStart + 6일

**응답**:
```json
{
  "id": 123,
  "user_id": 1,
  "week_start": "2025-12-08",
  "week_end": "2025-12-14",
  "emotion_temperature": 73,
  "positive_score": 42,
  "negative_score": 18,
  "neutral_score": 10,
  "main_emotion": "불안",
  "main_emotion_confidence": 0.82,
  "main_emotion_character_code": "ANXIOUS_RABBIT",
  "badges": ["불안多", "지침", "회복시도"],
  "summary_text": "이번 주에는 걱정과 피로가 자주 등장했어요. 스스로를 돌보려는 시도도 보였습니다.",
  "created_at": "2025-12-14T23:50:00Z",
  "updated_at": "2025-12-14T23:50:00Z"
}
```

### 2. 주간 리포트 상세 조회 (reportId 기준)
**경로**: `GET /api/v1/reports/emotion/weekly/{reportId}`  
**인증**: 필요 (Bearer Token)  
**설명**: 리포트 ID를 기준으로 상세 조회  

**Path Parameters**:
- `reportId` (integer): 주간 감정 리포트 ID

**응답**:
```json
{
  "id": 123,
  "user_id": 1,
  "week_start": "2025-12-08",
  "week_end": "2025-12-14",
  "emotion_temperature": 73,
  "positive_score": 42,
  "negative_score": 18,
  "neutral_score": 10,
  "main_emotion": "불안",
  "main_emotion_confidence": 0.82,
  "main_emotion_character_code": "ANXIOUS_RABBIT",
  "badges": ["불안多", "지침", "회복시도"],
  "summary_text": "이번 주에는 걱정과 피로가 자주 등장했어요. 스스로를 돌보려는 시도도 보였습니다.",
  "created_at": "2025-12-14T23:50:00Z",
  "updated_at": "2025-12-14T23:50:00Z"
}
```

### 3. 주간 리포트 조회 (주간 기준)
**경로**: `GET /api/v1/reports/emotion/weekly`  
**인증**: 필요 (Bearer Token)  
**설명**: 특정 주간(weekStart~weekEnd)의 리포트 1건 조회  

**Query Parameters**:
- `weekStart` (required, string): 주 시작일 (YYYY-MM-DD)
- `weekEnd` (optional, string): 주 종료일 (YYYY-MM-DD), 기본값: weekStart + 6일

**예시**:
```
GET /api/v1/reports/emotion/weekly?weekStart=2025-12-08
```

**응답**:
```json
{
  "id": 123,
  "user_id": 1,
  "week_start": "2025-12-08",
  "week_end": "2025-12-14",
  "emotion_temperature": 73,
  "positive_score": 42,
  "negative_score": 18,
  "neutral_score": 10,
  "main_emotion": "불안",
  "main_emotion_confidence": 0.82,
  "main_emotion_character_code": "ANXIOUS_RABBIT",
  "badges": ["불안多", "지침", "회복시도"],
  "summary_text": "이번 주에는 걱정과 피로가 자주 등장했어요. 스스로를 돌보려는 시도도 보였습니다.",
  "created_at": "2025-12-14T23:50:00Z",
  "updated_at": "2025-12-14T23:50:00Z"
}
```

### 4. 주간 리포트 목록 조회 (최근 N주)
**경로**: `GET /api/v1/reports/emotion/weekly/list`  
**인증**: 필요 (Bearer Token)  
**설명**: 최근 N주 주간 감정 리포트 요약 목록 조회 (FE 타임라인용)  

**Query Parameters**:
- `limit` (optional, integer): 조회할 주간 개수 (기본값: 8, 최대: 100)

**예시**:
```
GET /api/v1/reports/emotion/weekly/list?limit=8
```

**응답**:
```json
{
  "items": [
    {
      "id": 123,
      "week_start": "2025-12-08",
      "week_end": "2025-12-14",
      "emotion_temperature": 73,
      "main_emotion": "불안",
      "badges": ["불안多", "지침"]
    },
    {
      "id": 122,
      "week_start": "2025-12-01",
      "week_end": "2025-12-07",
      "emotion_temperature": 61,
      "main_emotion": "피로",
      "badges": ["지침", "회복시도"]
    }
  ]
}

---

## 신조어 퀴즈 (Slang Quiz)

### 1. 게임 시작
**경로**: `POST /api/service/slang-quiz/start-game`  
**인증**: 필요 (JWT)  
**설명**: 신조어 퀴즈 게임 시작 (5문제)  

**요청 Body**:
```json
{
  "level": "beginner|intermediate|advanced",
  "quiz_type": "word_to_meaning|meaning_to_word"
}
```

**응답**:
```json
{
  "game_id": 123,
  "total_questions": 5,
  "current_question": 1,
  "question": {
    "question_number": 1,
    "word": "킹받네",
    "question": "자녀가 '킹받네'라고 했다면 무슨 뜻일까요?",
    "options": ["기분이 좋다", "화가 난다", "배가 고프다", "졸리다"],
    "time_limit": 20
  }
}
```

### 2. 문제 조회
**경로**: `GET /api/service/slang-quiz/games/{game_id}/questions/{question_number}`  
**인증**: 필요 (JWT)  
**설명**: 특정 문제 조회  

**응답**:
```json
{
  "question_number": 2,
  "word": "갓생",
  "question": "자녀가 '갓생'이라고 했다면 무슨 뜻일까요?",
  "options": ["신처럼 사는 삶", "게으른 삶", "바쁜 삶", "평범한 삶"],
  "time_limit": 20
}
```

### 3. 답안 제출
**경로**: `POST /api/service/slang-quiz/games/{game_id}/submit-answer`  
**인증**: 필요 (JWT)  
**설명**: 답안 제출 및 점수 계산  

**요청 Body**:
```json
{
  "question_number": 1,
  "user_answer_index": 1,
  "response_time_seconds": 15
}
```

**응답**:
```json
{
  "is_correct": true,
  "correct_answer_index": 1,
  "earned_score": 135,
  "explanation": "'킹받네'는 '열받네'를 강조한 표현이에요...",
  "reward_card": {
    "message": "킹받는 일이 있어도 엄마는 네 편이야!",
    "background_mood": "warm"
  }
}
```

**점수 계산**:
- 기본 점수: 100점
- 보너스: 10초 이내 50점, 이후 1초당 -1점 (최대 20초)
- 오답: 0점

### 4. 게임 종료
**경로**: `POST /api/service/slang-quiz/games/{game_id}/end`  
**인증**: 필요 (JWT)  
**설명**: 게임 종료 및 결과 조회  

**응답**:
```json
{
  "game_id": 123,
  "total_questions": 5,
  "correct_count": 4,
  "total_score": 550,
  "total_time_seconds": 180,
  "questions_summary": [
    {
      "question_number": 1,
      "word": "킹받네",
      "is_correct": true,
      "earned_score": 150
    }
  ]
}
```

### 5. 게임 히스토리
**경로**: `GET /api/service/slang-quiz/history`  
**인증**: 필요 (JWT)  
**설명**: 사용자의 게임 히스토리 조회  

**Query Parameters**:
- `limit` (default: 20): 조회할 게임 수
- `offset` (default: 0): 페이지네이션 오프셋

**응답**:
```json
{
  "total": 10,
  "games": [
    {
      "game_id": 123,
      "level": "beginner",
      "quiz_type": "word_to_meaning",
      "total_questions": 5,
      "correct_count": 4,
      "total_score": 550,
      "is_completed": true,
      "created_at": "2025-12-10T10:00:00"
    }
  ]
}
```

### 6. 통계 조회
**경로**: `GET /api/service/slang-quiz/statistics`  
**인증**: 필요 (JWT)  
**설명**: 사용자의 퀴즈 통계 조회  

**응답**:
```json
{
  "statistics": {
    "total_games": 10,
    "total_questions": 50,
    "correct_answers": 40,
    "accuracy_rate": 0.8,
    "total_score": 5500,
    "average_score": 550.0,
    "best_score": 700,
    "beginner_accuracy": 0.85,
    "intermediate_accuracy": 0.75,
    "advanced_accuracy": 0.65,
    "word_to_meaning_accuracy": 0.82,
    "meaning_to_word_accuracy": 0.78
  }
}
```

### 7. 게임 삭제
**경로**: `DELETE /api/service/slang-quiz/games/{game_id}`  
**인증**: 필요 (JWT)  
**설명**: 게임 히스토리 삭제 (Soft Delete)  

**응답**:
```json
{
  "success": true,
  "message": "Game 123 deleted successfully",
  "game_id": 123
}
```

### 8. 관리자용 문제 생성
**경로**: `POST /api/service/slang-quiz/admin/questions/generate`  
**인증**: 필요 (JWT)  
**설명**: 관리자용 문제 생성 (나중에 사용)  

**Query Parameters**:
- `level`: 난이도 (beginner/intermediate/advanced)
- `quiz_type`: 퀴즈 타입 (word_to_meaning/meaning_to_word)
- `count`: 생성할 문제 수 (1-50)

**응답**:
```json
{
  "success": true,
  "message": "Generated 10 questions",
  "count": 10,
  "level": "beginner",
  "quiz_type": "word_to_meaning"
}
```

### 9. 헬스 체크
**경로**: `GET /api/service/slang-quiz/health`  
**인증**: 불필요  
**설명**: 서비스 상태 확인  

**응답**:
```json
{
  "status": "ok",
  "service": "slang-quiz"
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
- `{"type": "tts_ready", "audio_url": "/tts-outputs/{filename}", "session_id": "string"}` - TTS 오디오 생성 완료
- `{"type": "tts_error", "error": "timeout|generation_failed", "message": "string"}` - TTS 오류
- `{"type": "config_ack", "tts_enabled": "boolean"}` - 설정 확인 응답
- `{"type": "interrupted", "message": "string", "deleted_messages": "integer"}` - 인터럽트 처리 완료

**송신 메시지**:
- 음성 데이터 (bytes): `Int16Array` (512 샘플)
- 세션 ID 설정: `{"session_id": "string"}`
- TTS 설정: `{"type": "config", "tts_enabled": "boolean"}`
- 인터럽트 신호: `{"type": "interrupt", "reason": "string"}`

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

### 2. TTS 오디오 파일 서빙
**경로**: `GET /tts-outputs/{filename}`  
**인증**: 불필요  
**설명**: 생성된 TTS 오디오 파일 직접 서빙  

**Path Parameters**:
- `filename` (string): 오디오 파일명 (예: `044a57e116b04843a286c9304ebba6e1.wav`)

**응답**: WAV 파일 (audio/wav)

**참고**: 이 엔드포인트는 `/api/agent/v2/text` 또는 `/agent/stream`에서 `tts_enabled=true`로 요청 시 생성된 오디오 파일을 제공합니다.

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
| POST | `/emotion/api/analyze-session` | ✅ | 세션 기반 감정 분석 |
| POST | `/api/analyze` | ❌ | 감정 분석 수행 (alias) |
| POST | `/emotion/api/init` | ❌ | Vector DB 초기화 |
| POST | `/api/init` | ❌ | Vector DB 초기화 (alias) |

### 추천 (Recommendations)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/v1/recommendations/quote` | ❌ | 감정 기반 명언 추천 |
| POST | `/api/v1/recommendations/music` | ❌ | 감정 기반 음악 추천 |
| POST | `/api/v1/recommendations/image` | ❌ | 감정 기반 이미지 생성 |

### 루틴 추천 (Routine Recommendation)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/engine/routine-from-emotion` | ❌ | 감정 기반 루틴 추천 |
| POST | `/api/engine/routine-recommend-from-emotion` | ❌ | 감정 기반 루틴 추천 (alias) |

### 날씨 (Weather)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| GET | `/api/service/weather/current` | ❌ | 현재 날씨 조회 (도시명) |
| GET | `/api/service/weather/current/location` | ❌ | 현재 날씨 조회 (위도/경도) |

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
| GET | `/api/routine-survey/questions` | ❌ | 설문 조회 |
| POST | `/api/routine-survey/submit` | ✅ | 설문 제출 |
| GET | `/api/routine-survey/results/me` | ✅ | 내 설문 결과 조회 |

### 갱년기 설문 (Menopause Survey)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/menopause-survey/submit` | ❌ | 갱년기 설문 제출 및 위험도 평가 |
| GET | `/api/menopause-survey/questions` | ❌ | 설문 문항 목록 조회 (gender 별) |
| GET | `/api/menopause-survey/questions/{question_id}` | ❌ | 설문 문항 단건 조회 |
| POST | `/api/menopause-survey/questions` | ❌ | 설문 문항 생성 |
| PATCH | `/api/menopause-survey/questions/{question_id}` | ❌ | 설문 문항 수정 |
| DELETE | `/api/menopause-survey/questions/{question_id}` | ❌ | 설문 문항 삭제 |
| POST | `/api/menopause-survey/questions/seed-defaults` | ❌ | 기본 설문 문항 시드 생성 (개발/QA용) |

### 신조어 퀴즈 (Slang Quiz)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/service/slang-quiz/start-game` | ✅ | 게임 시작 |
| GET | `/api/service/slang-quiz/games/{game_id}/questions/{question_number}` | ✅ | 문제 조회 |
| POST | `/api/service/slang-quiz/games/{game_id}/submit-answer` | ✅ | 답안 제출 |
| POST | `/api/service/slang-quiz/games/{game_id}/end` | ✅ | 게임 종료 |
| GET | `/api/service/slang-quiz/history` | ✅ | 게임 히스토리 |
| GET | `/api/service/slang-quiz/statistics` | ✅ | 통계 조회 |
| DELETE | `/api/service/slang-quiz/games/{game_id}` | ✅ | 게임 삭제 |
| POST | `/api/service/slang-quiz/admin/questions/generate` | ✅ | 관리자용 문제 생성 |
| GET | `/api/service/slang-quiz/health` | ❌ | 헬스 체크 |

### 음성 인식 (STT)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| WS | `/stt/stream` | ❌ | STT WebSocket |

### 음성 합성 (TTS)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/tts` | ❌ | 텍스트 음성 변환 |
| GET | `/tts-outputs/{filename}` | ❌ | TTS 오디오 파일 서빙 |

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


### 주간 감정 리포트 (Weekly Emotion Report)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/v1/reports/emotion/weekly/generate` | ✅ | 주간 감정 리포트 생성/갱신 |
| GET  | `/api/v1/reports/emotion/weekly/{reportId}` | ✅ | reportId 기준 리포트 상세 + 대화 하이라이트 조회 |
| GET  | `/api/v1/reports/emotion/weekly` | ✅ | userId + weekStart(+weekEnd) 기준 리포트 조회 |
| GET  | `/api/v1/reports/emotion/weekly/list` | ✅ | 최근 N주 리포트 요약 목록 조회 |

### 대상별 이벤트 (Target Events - 마음서랍)

| HTTP 메서드 | 경로 | 인증 필요 | 설명 |
|------------|------|----------|------|
| POST | `/api/target-events/analyze-daily` | ✅ | 특정 날짜의 대화 분석 실행 |
| POST | `/api/target-events/analyze-weekly` | ✅ | 특정 주간의 이벤트 요약 실행 |
| GET  | `/api/target-events/daily` | ✅ | 일간 이벤트 목록 조회 (태그 필터링 지원) |
| GET  | `/api/target-events/weekly` | ✅ | 주간 이벤트 목록 조회 (태그 필터링 지원) |
| GET  | `/api/target-events/tags/popular` | ✅ | 자주 사용되는 태그 목록 조회 |
| GET  | `/api/target-events/health` | ❌ | 헬스 체크 |

#### 1. 일일 대화 분석
**경로**: `POST /api/target-events/analyze-daily`  
**인증**: 필요 (Bearer Token)  
**설명**: 특정 날짜의 대화를 LLM으로 분석하여 대상별 이벤트 추출  

**요청 Body**:
```json
{
  "target_date": "2024-12-13"
}
```

**응답**:
```json
{
  "analyzed_date": "2024-12-13",
  "events_count": 1,
  "events": [
    {
      "id": 1,
      "user_id": 1,
      "event_date": "2024-12-13",
      "event_type": "event",
      "target_type": "CHILD",
      "event_summary": "봄이와 건강 상담, 아들 학교 픽업 약속",
      "event_time": "2024-12-13T18:00:00",
      "importance": 4,
      "is_future_event": false,
      "tags": ["#자녀", "#픽업", "#오늘", "#중요"],
      "created_at": "2024-12-13T10:00:00",
      "updated_at": "2024-12-13T10:00:00"
    }
  ]
}
```

#### 2. 주간 이벤트 요약
**경로**: `POST /api/target-events/analyze-weekly`  
**인증**: 필요 (Bearer Token)  
**설명**: 특정 주간(월~일)의 일간 이벤트를 대상별로 요약  

**요청 Body**:
```json
{
  "week_start": "2024-12-09"
}
```

**응답**:
```json
{
  "week_start": "2024-12-09",
  "week_end": "2024-12-15",
  "summaries_count": 2,
  "summaries": [
    {
      "id": 1,
      "user_id": 1,
      "week_start": "2024-12-09",
      "week_end": "2024-12-15",
      "target_type": "HUSBAND",
      "events_summary": [
        {
          "date": "2024-12-11",
          "summary": "남편과 저녁 약속"
        },
        {
          "date": "2024-12-13",
          "summary": "남편 생일 준비"
        }
      ],
      "total_events": 2,
      "tags": ["#남편", "#약속", "#기념일"],
      "created_at": "2024-12-15T20:00:00",
      "updated_at": "2024-12-15T20:00:00"
    }
  ]
}
```

#### 3. 일간 이벤트 목록 조회
**경로**: `GET /api/target-events/daily`  
**인증**: 필요 (Bearer Token)  
**설명**: 일간 이벤트 목록 조회 (이벤트 타입 및 태그 필터링 지원)  

**Query Parameters**:
- `event_type` (optional): 이벤트 타입 (alarm/event/memory)
- `tags` (optional): 쉼표로 구분된 태그 (예: `#아들,#픽업`)
- `start_date` (optional): 시작 날짜 (YYYY-MM-DD)
- `end_date` (optional): 종료 날짜 (YYYY-MM-DD)
- `target_type` (optional): 대상 유형 (HUSBAND/CHILD/FRIEND/COLLEAGUE/SELF)

**응답**:
```json
{
  "daily_events": [
    {
      "id": 1,
      "user_id": 1,
      "event_date": "2024-12-13",
      "event_type": "event",
      "target_type": "CHILD",
      "event_summary": "봄이와 건강 상담, 아들 학교 픽업 약속",
      "event_time": "2024-12-13T18:00:00",
      "importance": 4,
      "is_future_event": false,
      "tags": ["#자녀", "#픽업", "#오늘", "#중요"],
      "created_at": "2024-12-13T10:00:00",
      "updated_at": "2024-12-13T10:00:00"
    }
  ],
  "total_count": 1,
  "available_tags": {
    "target": ["#남편", "#자녀", "#친구"],
    "event_type": ["#약속", "#픽업", "#만남"],
    "time": ["#오늘", "#이번주"],
    "importance": ["#중요", "#보통"],
    "other": [],
    "all": ["#자녀", "#픽업", "#약속", "#남편"]
  }
}
```

#### 4. 주간 이벤트 목록 조회
**경로**: `GET /api/target-events/weekly`  
**인증**: 필요 (Bearer Token)  
**설명**: 주간 이벤트 목록 조회 (태그 필터링 지원)  

**Query Parameters**:
- `tags` (optional): 쉼표로 구분된 태그
- `start_date` (optional): 시작 날짜 (YYYY-MM-DD)
- `end_date` (optional): 종료 날짜 (YYYY-MM-DD)
- `target_type` (optional): 대상 유형 (HUSBAND/CHILD/FRIEND/COLLEAGUE/SELF)

**응답**:
```json
{
  "weekly_events": [
    {
      "id": 1,
      "user_id": 1,
      "week_start": "2024-12-09",
      "week_end": "2024-12-15",
      "target_type": "HUSBAND",
      "events_summary": [...],
      "total_events": 2,
      "tags": ["#남편", "#약속"],
      "emotion_distribution": {
        "기쁨": 35,
        "안정": 25,
        "사랑": 20,
        "분노": 12,
        "걱정": 8
      },
      "primary_emotion": "기쁨",
      "sentiment_overall": "positive",
      "created_at": "2024-12-15T20:00:00",
      "updated_at": "2024-12-15T20:00:00"
    }
  ],
  "total_count": 1
}
```

#### 5. 인기 태그 조회
**경로**: `GET /api/target-events/tags/popular`  
**인증**: 필요 (Bearer Token)  
**설명**: 최근 30일간 자주 사용된 태그 목록 조회  

**Query Parameters**:
- `limit` (optional, default=20): 카테고리별 최대 태그 수

**응답**:
```json
{
  "target": ["#남편", "#자녀", "#친구"],
  "event_type": ["#약속", "#픽업", "#만남"],
  "time": ["#오늘", "#이번주"],
  "importance": ["#중요", "#보통"],
  "other": [],
  "all": ["#남편", "#약속", "#자녀", "#픽업"]
}
```

### 이벤트 타입 (Event Type)

이벤트는 다음 3가지 타입으로 분류됩니다:

- **alarm**: 알람/알림 요청 (사용자가 "알려줘", "리마인드해줘" 등 명시적 요청)
  - **주의**: 알람 타입은 무조건 `TARGET_TYPE=SELF`로 저장됩니다
- **event**: 약속/일정 (구체적인 날짜/시간이 있는 약속, 만남 등) - 기본값
- **memory**: 일반 대화 기억 (위 두 가지가 아닌 일반적인 대화 내용)

### 대상 타입 (Target Type)

대상은 다음 5가지 타입으로 분류됩니다 (TB_SCENARIOS와 동일):

- **HUSBAND**: 남편 관련
- **CHILD**: 자녀 관련 (아들/딸 통합)
- **FRIEND**: 친구 관련
- **COLLEAGUE**: 직장동료 관련
- **SELF**: 봄이와 대화, 알람 등 (자기 자신)

**특징**:
- 하루에 사용자당 **1개의 이벤트만** 저장됨 (여러 대상과 대화해도 통합 요약)
- 알람 타입은 무조건 `SELF`로 설정됨
- `EVENT_DATE`는 분석한 날짜로 저장됨 (LLM이 계산한 날짜가 아님)

**사용 예시**:
```bash
# 알람만 조회
GET /api/target-events/daily?event_type=alarm

# 일정만 조회
GET /api/target-events/daily?event_type=event

# 일반 기억만 조회
GET /api/target-events/daily?event_type=memory

# 알람 + SELF (알람은 항상 SELF)
GET /api/target-events/daily?event_type=alarm&target_type=SELF

# 자녀 관련 이벤트만 조회
GET /api/target-events/daily?target_type=CHILD
```

---

**총 엔드포인트 수**: 91개  
**인증 필요**: 51개 | **인증 불필요**: 40개
