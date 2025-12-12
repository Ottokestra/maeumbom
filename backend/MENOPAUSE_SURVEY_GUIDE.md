# Menopause Survey API - 사용 가이드

## 개요
갱년기 자가테스트 설문 API는 성별(FEMALE/MALE)별로 10개씩 총 20개의 설문 문항을 제공합니다.

## 주요 엔드포인트

### 1. 설문 문항 조회 (GET)
```http
GET /api/menopause/questions?gender=FEMALE
```

**Query Parameters:**
- `gender` (필수): `FEMALE` 또는 `MALE`
- `is_active` (선택, 기본값: true): 활성화된 문항만 조회

**응답 예시:**
```json
[
  {
    "id": 1,
    "gender": "FEMALE",
    "code": "F1",
    "order_no": 1,
    "question_text": "일의 집중력이나 기억력이 예전 같지 않다고 느낀다.",
    "risk_when_yes": true,
    "positive_label": "예",
    "negative_label": "아니오",
    "character_key": "PEACH_WORRY",
    "is_active": true,
    "is_deleted": false,
    "created_at": "2025-12-11T10:00:00Z",
    "updated_at": "2025-12-11T10:00:00Z",
    "created_by": "seed-defaults",
    "updated_by": "seed-defaults"
  }
]
```

### 2. 기본 문항 시딩 (POST)
```http
POST /api/menopause/questions/seed-defaults
```

**설명:**
- 서버 시작 시 자동으로 실행됩니다
- 수동으로 호출 시, 이미 존재하는 문항은 스킵하고 없는 문항만 추가합니다

**응답 예시:**
```json
{
  "created_count": 20,
  "skipped_count": 0
}
```

### 3. 설문 제출 (POST)
```http
POST /api/menopause-survey/submit
```

**Request Body:**
```json
{
  "gender": "FEMALE",
  "answers": [
    {
      "question_id": 1,
      "answer_value": 3
    },
    {
      "question_id": 2,
      "answer_value": 0
    }
  ]
}
```

**응답 예시:**
```json
{
  "id": 1,
  "total_score": 15,
  "risk_level": "MID",
  "comment": "증상이 느껴집니다. 생활 습관 개선과 상담이 도움이 될 수 있습니다.",
  "created_at": "2025-12-11T10:00:00Z"
}
```

## 테스트 순서

### 1. 서버 시작 확인
서버가 시작되면 자동으로 기본 문항이 DB에 로드됩니다:
```
[INFO] Menopause survey router loaded successfully.
[INFO] Menopause survey: 20개 기본 문항 자동 import됨 (FEMALE: 10개, MALE: 10개)
```

또는 이미 데이터가 있는 경우:
```
[INFO] Menopause survey: 20개 문항이 이미 DB에 있습니다.
```

### 2. 문항 조회 테스트

#### curl 사용:
```bash
# FEMALE 문항 조회
curl -X GET "http://localhost:8000/api/menopause/questions?gender=FEMALE"

# MALE 문항 조회
curl -X GET "http://localhost:8000/api/menopause/questions?gender=MALE"
```

#### Swagger UI 사용:
1. 브라우저에서 `http://localhost:8000/docs` 접속
2. `GET /api/menopause/questions` 엔드포인트 찾기
3. "Try it out" 클릭
4. gender 파라미터에 `FEMALE` 또는 `MALE` 입력
5. "Execute" 클릭

### 3. 수동 시딩 (필요 시)
```bash
curl -X POST "http://localhost:8000/api/menopause/questions/seed-defaults"
```

## 문항 구성

### FEMALE 문항 (F1~F10)
1. 일의 집중력이나 기억력이 예전 같지 않다고 느낀다.
2. 아무 이유 없이 짜증이 늘고 감정 기복이 심해졌다.
3. 잠을 잘 이루지 못하거나 수면에 문제가 있다.
4. 얼굴이 달아오르거나 갑작스러운 열감(홍조)을 자주 느낀다.
5. 가슴 두근거림, 식은땀, 이유 없는 불안감을 느끼는 편이다.
6. 관절통, 근육통 등 몸 여기저기가 자주 쑤시거나 아프다.
7. 성욕이 감소했거나 성관계가 예전보다 불편하게 느껴진다.
8. 체중 증가나 체형 변화(뱃살 증가 등)가 눈에 띈다.
9. 예전보다 우울하고 의욕이 떨어진 느낌이 자주 든다.
10. 일상생활이 버겁게 느껴지고 작은 일에도 쉽게 지친다.

### MALE 문항 (M1~M10)
1. 예전보다 쉽게 피로해지고 회복이 더딘 편이다.
2. 근력이나 체력이 눈에 띄게 떨어졌다고 느낀다.
3. 성욕이나 성 기능이 예전보다 감소했다.
4. 짜증이나 분노가 늘고 사소한 일에도 예민해진다.
5. 웬일인지 의욕이 없고 무기력한 기분이 자주 든다.
6. 집중력 저하나 건망증이 심해진 것 같다.
7. 밤에 자주 깨거나 깊은 잠을 자기 어렵다.
8. 심장 두근거림, 식은땀, 발열 같은 증상을 경험한다.
9. 복부 비만, 체중 증가 등 체형 변화가 눈에 띄게 느껴진다.
10. 삶에 대한 자신감이나 의욕이 예전보다 줄었다.

## 위험도 계산 로직

### 점수 계산
- 각 문항: "예" = 3점, "아니오" = 0점
- 총점 = 모든 문항 점수의 합

### 위험도 분류
- **LOW** (0~9점): 증상이 경미합니다. 규칙적인 생활을 유지하세요.
- **MID** (10~20점): 증상이 느껴집니다. 생활 습관 개선과 상담이 도움이 될 수 있습니다.
- **HIGH** (21점 이상): 증상이 심합니다. 전문의와의 상담을 적극 권장합니다.

## 데이터베이스 테이블

### TB_MENOPAUSE_SURVEY_QUESTIONS
설문 문항을 저장하는 테이블입니다.

**주의사항:**
- 기존 오타 테이블 `TB_MENOPAUSE_SURVEY_QEUSTION`에서 데이터를 이전해야 하는 경우,
  `app/db/models.py` 파일의 227-238번 라인에 있는 SQL 주석을 참고하세요.

### TB_MENOPAUSE_SURVEY_RESULT
설문 결과를 저장하는 테이블입니다.

### TB_MENOPAUSE_SURVEY_ANSWER
각 문항별 응답을 저장하는 테이블입니다.

## 문제 해결

### 빈 배열([]) 반환 시
1. 서버 로그 확인:
   ```
   [MenopauseSurvey] No questions found for gender=FEMALE
   ```
2. 수동 시딩 실행:
   ```bash
   curl -X POST "http://localhost:8000/api/menopause/questions/seed-defaults"
   ```
3. 다시 조회:
   ```bash
   curl -X GET "http://localhost:8000/api/menopause/questions?gender=FEMALE"
   ```

### 서버 재시작 후에도 데이터 없음
- DB 연결 확인
- 테이블 생성 확인: `TB_MENOPAUSE_SURVEY_QUESTIONS` 테이블이 존재하는지 확인
- 서버 로그에서 에러 메시지 확인

## Swagger/OpenAPI 문서
서버 실행 후 `http://localhost:8000/docs`에서 모든 엔드포인트를 확인하고 테스트할 수 있습니다.
