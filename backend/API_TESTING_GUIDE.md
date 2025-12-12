# API 테스트 가이드

## 목차
1. [서버 실행 방법](#1-서버-실행-방법)
2. [갱년기 설문 API 테스트](#2-갱년기-설문-api-테스트)
3. [주간 감정 리포트 API 테스트](#3-주간-감정-리포트-api-테스트)
4. [Swagger UI 사용법](#4-swagger-ui-사용법)

---

## 1. 서버 실행 방법

### 1-1. 가상환경 활성화 (선택사항)
```bash
cd C:\Users\Admin\dev\new-maeumbom\backend

# 가상환경이 있다면
.venv\Scripts\activate
```

### 1-2. 서버 실행
```bash
python main.py
```

### 1-3. 서버 실행 확인
서버가 정상적으로 시작되면 다음과 같은 메시지가 출력됩니다:
```
[INFO] Emotion analysis router loaded successfully.
[INFO] Menopause survey router loaded successfully.
[INFO] Weekly emotion report router loaded successfully.
[INFO] Authentication router loaded successfully.
...
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

### 1-4. 헬스 체크
브라우저나 curl로 확인:
```bash
curl http://localhost:8000/health
```

**응답 예시**:
```json
{
  "status": "ok",
  "message": "Server is running"
}
```

---

## 2. 갱년기 설문 API 테스트

### 2-1. 설문 문항 목록 조회 (인증 불필요)

#### 여성용 문항 조회
```bash
curl -X GET "http://localhost:8000/api/menopause/questions?gender=FEMALE"
```

**예상 응답**:
```json
{
  "items": [
    {
      "id": 1,
      "gender": "FEMALE",
      "code": "F1",
      "order_no": 1,
      "question_text": "안면홍조(얼굴이 화끈거리고 붉어지는 증상)가 있습니까?",
      "risk_when_yes": true,
      "positive_label": "예",
      "negative_label": "아니오",
      "character_key": "hot_flash",
      "is_active": true
    },
    ...
  ]
}
```

#### 남성용 문항 조회
```bash
curl -X GET "http://localhost:8000/api/menopause/questions?gender=MALE"
```

### 2-2. 특정 문항 조회
```bash
curl -X GET "http://localhost:8000/api/menopause/questions/1"
```

### 2-3. 설문 제출 (인증 불필요)

**요청**:
```bash
curl -X POST "http://localhost:8000/api/menopause-survey/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "gender": "FEMALE",
    "answers": [
      {"question_id": 1, "answer_value": 3},
      {"question_id": 2, "answer_value": 0},
      {"question_id": 3, "answer_value": 3}
    ]
  }'
```

**예상 응답**:
```json
{
  "result_id": 1,
  "gender": "FEMALE",
  "total_score": 6,
  "risk_level": "LOW",
  "risk_message": "갱년기 증상이 경미합니다.",
  "created_at": "2025-12-11T20:00:00+09:00"
}
```

### 2-4. 기본 문항 시드 생성 (개발/QA용)
```bash
curl -X POST "http://localhost:8000/api/menopause/questions/seed-defaults"
```

**예상 응답**:
```json
{
  "created_count": 20,
  "skipped_count": 0,
  "message": "20개 기본 문항이 생성되었습니다 (FEMALE: 10개, MALE: 10개)"
}
```

---

## 3. 주간 감정 리포트 API 테스트

### ⚠️ 중요: 인증 토큰 필요
주간 감정 리포트 API는 모두 **인증이 필요**합니다.

### 3-1. 로그인하여 토큰 획득

#### Google OAuth 로그인 (예시)
실제 환경에서는 프론트엔드를 통해 OAuth 인증을 진행해야 합니다.

**테스트용 간단 방법**:
1. Swagger UI 사용 (아래 섹션 참고)
2. 또는 기존에 발급받은 토큰 사용

### 3-2. 주간 감정 리포트 생성

**요청**:
```bash
curl -X POST "http://localhost:8000/api/v1/reports/emotion/weekly/generate?week_start=2025-12-09" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**예상 응답**:
```json
{
  "id": 1,
  "user_id": 123,
  "week_start": "2025-12-09",
  "week_end": "2025-12-15",
  "emotion_temperature": 38,
  "positive_score": 65,
  "negative_score": 25,
  "neutral_score": 10,
  "main_emotion": "happiness",
  "main_emotion_confidence": 0.85,
  "main_emotion_character_code": "CHAR_HAPPINESS",
  "badges": ["긍정", "활력"],
  "summary_text": "이번 주는 happiness 감정이 주를 이루었습니다. 전반적으로 안정적인 한 주였어요.",
  "created_at": "2025-12-11T20:00:00+09:00",
  "updated_at": "2025-12-11T20:00:00+09:00"
}
```

### 3-3. 주차로 리포트 조회

**요청**:
```bash
curl -X GET "http://localhost:8000/api/v1/reports/emotion/weekly?week_start=2025-12-09" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**예상 응답**: (생성 API와 동일)

**404 에러 (리포트 없음)**:
```json
{
  "detail": "Report not found for this week"
}
```

### 3-4. 리포트 ID로 조회

**요청**:
```bash
curl -X GET "http://localhost:8000/api/v1/reports/emotion/weekly/1" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 3-5. 최근 N주 리포트 목록 조회

**요청**:
```bash
curl -X GET "http://localhost:8000/api/v1/reports/emotion/weekly/list?limit=8" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**예상 응답**:
```json
{
  "items": [
    {
      "id": 3,
      "week_start": "2025-12-09",
      "week_end": "2025-12-15",
      "emotion_temperature": 38,
      "main_emotion": "happiness",
      "badges": ["긍정", "활력"]
    },
    {
      "id": 2,
      "week_start": "2025-12-02",
      "week_end": "2025-12-08",
      "emotion_temperature": 35,
      "main_emotion": "calm",
      "badges": ["불안多", "회복시도"]
    }
  ]
}
```

---

## 4. Swagger UI 사용법

Swagger UI는 API를 브라우저에서 직접 테스트할 수 있는 가장 쉬운 방법입니다.

### 4-1. Swagger UI 접속
```
http://localhost:8000/docs
```

### 4-2. 갱년기 설문 API 테스트

1. **"Menopause Survey"** 섹션 찾기
2. **GET /api/menopause/questions** 클릭
3. **"Try it out"** 버튼 클릭
4. **gender** 파라미터에 `FEMALE` 또는 `MALE` 입력
5. **"Execute"** 버튼 클릭
6. 아래 **"Responses"** 섹션에서 결과 확인

### 4-3. 주간 감정 리포트 API 테스트 (인증 필요)

#### Step 1: 인증 토큰 설정
1. Swagger UI 우측 상단의 **"Authorize"** 버튼 클릭
2. **"Bearer Token"** 입력란에 토큰 입력
   - 형식: `Bearer YOUR_ACCESS_TOKEN`
   - 또는 그냥 `YOUR_ACCESS_TOKEN` (자동으로 Bearer 추가됨)
3. **"Authorize"** 버튼 클릭
4. **"Close"** 버튼 클릭

#### Step 2: API 테스트
1. **"Weekly Emotion Report"** 섹션 찾기
2. **POST /api/v1/reports/emotion/weekly/generate** 클릭
3. **"Try it out"** 버튼 클릭
4. **week_start** 파라미터에 날짜 입력 (예: `2025-12-09`)
5. **"Execute"** 버튼 클릭
6. 응답 확인

#### Step 3: 다른 엔드포인트 테스트
- **GET /api/v1/reports/emotion/weekly**: 주차로 조회
- **GET /api/v1/reports/emotion/weekly/{report_id}**: ID로 조회
- **GET /api/v1/reports/emotion/weekly/list**: 목록 조회

---

## 5. 테스트 시나리오 (전체 플로우)

### 시나리오 1: 갱년기 설문 전체 플로우

```bash
# 1. 서버 실행
python main.py

# 2. 기본 문항 시드 생성 (최초 1회)
curl -X POST "http://localhost:8000/api/menopause/questions/seed-defaults"

# 3. 여성용 문항 조회
curl -X GET "http://localhost:8000/api/menopause/questions?gender=FEMALE"

# 4. 설문 제출
curl -X POST "http://localhost:8000/api/menopause-survey/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "gender": "FEMALE",
    "answers": [
      {"question_id": 1, "answer_value": 3},
      {"question_id": 2, "answer_value": 0},
      {"question_id": 3, "answer_value": 3},
      {"question_id": 4, "answer_value": 0},
      {"question_id": 5, "answer_value": 3},
      {"question_id": 6, "answer_value": 0},
      {"question_id": 7, "answer_value": 3},
      {"question_id": 8, "answer_value": 0},
      {"question_id": 9, "answer_value": 3},
      {"question_id": 10, "answer_value": 0}
    ]
  }'
```

### 시나리오 2: 주간 감정 리포트 전체 플로우

```bash
# 1. 서버 실행
python main.py

# 2. 로그인 (Swagger UI 또는 프론트엔드 사용)
# → 토큰 획득: YOUR_ACCESS_TOKEN

# 3. 이번 주 리포트 조회 (없으면 404)
curl -X GET "http://localhost:8000/api/v1/reports/emotion/weekly?week_start=2025-12-09" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 4. 리포트 생성
curl -X POST "http://localhost:8000/api/v1/reports/emotion/weekly/generate?week_start=2025-12-09" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 5. 생성된 리포트 다시 조회
curl -X GET "http://localhost:8000/api/v1/reports/emotion/weekly?week_start=2025-12-09" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 6. 최근 8주 리포트 목록 조회
curl -X GET "http://localhost:8000/api/v1/reports/emotion/weekly/list?limit=8" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 6. 문제 해결

### 문제 1: 서버가 시작되지 않음
**원인**: 포트 8000이 이미 사용 중
**해결**:
```bash
# 포트 사용 중인 프로세스 확인
netstat -ano | findstr :8000

# 프로세스 종료 (PID 확인 후)
taskkill /PID <PID> /F
```

### 문제 2: DB 연결 오류
**원인**: MySQL 서버가 실행되지 않음
**해결**:
1. MySQL 서버 시작
2. `.env` 파일에서 DB 연결 정보 확인

### 문제 3: 401 Unauthorized
**원인**: 인증 토큰이 없거나 만료됨
**해결**:
1. Swagger UI에서 다시 로그인
2. 새로운 토큰 획득
3. Authorization 헤더에 토큰 포함

### 문제 4: 404 Not Found (갱년기 설문)
**원인**: 기본 문항이 DB에 없음
**해결**:
```bash
curl -X POST "http://localhost:8000/api/menopause/questions/seed-defaults"
```

### 문제 5: 404 Not Found (주간 리포트)
**원인**: 해당 주차의 리포트가 아직 생성되지 않음
**해결**:
```bash
curl -X POST "http://localhost:8000/api/v1/reports/emotion/weekly/generate?week_start=2025-12-09" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 7. 추가 도구

### Postman 사용
1. Postman 다운로드: https://www.postman.com/downloads/
2. Collection 생성
3. 각 API 엔드포인트 추가
4. Environment 설정 (base_url, token 등)

### Thunder Client (VS Code Extension)
1. VS Code에서 Thunder Client 설치
2. New Request 생성
3. API 테스트

---

## 8. 참고 문서

- **API 전체 스펙**: `API_ENDPOINTS.md`
- **구현 상세**: `WEEKLY_EMOTION_REPORT_IMPLEMENTATION.md`
- **DB 가이드**: `DB_GUIDE.md`
- **개발자 가이드**: `DEVELOPER_GUIDE.md`
