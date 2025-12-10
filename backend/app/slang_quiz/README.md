# 신조어 퀴즈 게임 API

갱년기 여성(5060 세대)을 위한 한국 신조어 학습 퀴즈 게임 API

## 📋 목차

- [개요](#개요)
- [기능](#기능)
- [설치 및 설정](#설치-및-설정)
- [API 엔드포인트](#api-엔드포인트)
- [게임 플로우](#게임-플로우)
- [데이터 구조](#데이터-구조)
- [초기 문제 생성](#초기-문제-생성)

## 개요

**신조어 퀴즈 게임**은 5060 여성 사용자가 자녀 세대와의 소통을 위해 한국 신조어를 재미있게 학습할 수 있도록 돕는 서비스입니다.

### 주요 특징

- ✅ **문제 풀(Pool) 방식**: 미리 생성된 문제로 즉시 응답 (0.1초)
- ✅ **사용자 맞춤 선택**: 안 푼 문제 우선 제공
- ✅ **2가지 퀴즈 타입**:
  - `word_to_meaning`: 단어 → 뜻 (교육 중심)
  - `meaning_to_word`: 뜻 → 단어 (두뇌 훈련, 말장난 오답)
- ✅ **3가지 난이도**: 초급, 중급, 고급
- ✅ **시간 기반 점수 계산**: 빠를수록 높은 점수
- ✅ **보상 카드**: 자녀 응원 메시지 (긍정적 맥락)

## 기능

### 게임 구조

- **1 게임 = 5문제**
- **1 문제 = 40초 제한**
- **총 게임 시간**: 약 3~4분

### 점수 체계

```
기본 점수: 100점
보너스 점수: 시간에 따라 선형 감소

- 10초 이내: 150점 (100 + 50)
- 20초: 140점 (100 + 40)
- 30초: 130점 (100 + 30)
- 40초: 120점 (100 + 20)
- 40초 초과: 100점
- 오답: 0점
```

### 난이도별 단어 선정 기준

- **초급**: 5060 세대도 한 번쯤 들어봤을 법한 대중적 신조어
  - 예: "킹받네", "ㅇㅈ", "TMI", "꾸안꾸"
- **중급**: 젊은 세대가 자주 사용하는 신조어
  - 예: "갓생", "억텐", "프불", "갑분싸"
- **고급**: 최신 트렌드 또는 특정 커뮤니티 신조어
  - 예: "제곧내", "머선129", "웅앵웅", "존버"

## 설치 및 설정

### 1. 환경 설정

```bash
cd backend
pip install -r requirements.txt
```

### 2. 환경 변수 설정

`.env` 파일에 OpenAI API Key 추가:

```
OPENAI_API_KEY=your_openai_api_key_here
```

### 3. DB 테이블 생성

```bash
python -c "from app.db.database import init_db; init_db()"
```

### 4. 초기 문제 생성

```bash
python -m app.slang_quiz.scripts.generate_initial_questions
```

이 스크립트는 **180개의 문제**를 생성합니다:
- 3 레벨 × 2 타입 × 30개 = 180개
- DB (`TB_SLANG_QUIZ_QUESTIONS`)와 JSON 파일 (`data/` 폴더)에 동시 저장

## API 엔드포인트

### 인증

모든 엔드포인트는 JWT 인증이 필요합니다 (Authorization: Bearer {token}).

### 엔드포인트 목록

#### 1. 게임 시작

```http
POST /api/service/slang-quiz/start-game
```

**Request:**
```json
{
  "level": "beginner",
  "quiz_type": "word_to_meaning"
}
```

**Response:**
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
    "time_limit": 40
  }
}
```

#### 2. 문제 조회

```http
GET /api/service/slang-quiz/games/{game_id}/questions/{question_number}
```

**Response:**
```json
{
  "question_number": 2,
  "word": "갓생",
  "question": "자녀가 '갓생'이라고 했다면 무슨 뜻일까요?",
  "options": ["신처럼 사는 삶", "게으른 삶", "바쁜 삶", "평범한 삶"],
  "time_limit": 40
}
```

#### 3. 답안 제출

```http
POST /api/service/slang-quiz/games/{game_id}/submit-answer
```

**Request:**
```json
{
  "question_number": 1,
  "user_answer_index": 1,
  "response_time_seconds": 15
}
```

**Response:**
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

#### 4. 게임 종료

```http
POST /api/service/slang-quiz/games/{game_id}/end
```

**Response:**
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

#### 5. 게임 히스토리

```http
GET /api/service/slang-quiz/history?limit=20&offset=0
```

**Response:**
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

#### 6. 통계 조회

```http
GET /api/service/slang-quiz/statistics
```

**Response:**
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

#### 7. 게임 삭제

```http
DELETE /api/service/slang-quiz/games/{game_id}
```

**Response:**
```json
{
  "success": true,
  "message": "Game 123 deleted successfully",
  "game_id": 123
}
```

#### 8. 관리자용 문제 생성 (나중에 사용)

```http
POST /api/service/slang-quiz/admin/questions/generate?level=beginner&quiz_type=word_to_meaning&count=10
```

## 게임 플로우

```
1. 게임 시작 (POST /start-game)
   ↓
2. 첫 번째 문제 표시
   ↓
3. 답안 제출 (POST /submit-answer)
   ↓
4. 결과 및 보상 카드 표시
   ↓
5. 다음 문제 조회 (GET /questions/{question_number})
   ↓
6. 3~5 반복 (총 5문제)
   ↓
7. 게임 종료 (POST /end)
   ↓
8. 최종 결과 및 통계 표시
```

## 데이터 구조

### DB 테이블

#### TB_SLANG_QUIZ_QUESTIONS (문제 풀)
- 미리 생성된 문제 저장
- 레벨, 타입별로 인덱싱
- 사용 횟수 추적 (`USAGE_COUNT`)

#### TB_SLANG_QUIZ_GAMES (게임 세션)
- 게임별 통계 저장
- 완료 여부, 총 점수, 정답 개수

#### TB_SLANG_QUIZ_ANSWERS (문제별 답안)
- 각 문제에 대한 사용자 답안
- 정답 여부, 소요 시간, 획득 점수

### JSON 백업

```
backend/app/slang_quiz/data/
├── beginner/
│   ├── word_to_meaning/
│   │   ├── question_001.json
│   │   └── ... (30개)
│   └── meaning_to_word/
│       └── ... (30개)
├── intermediate/
└── advanced/
```

## 초기 문제 생성

### 스크립트 실행

```bash
python -m app.slang_quiz.scripts.generate_initial_questions
```

### 생성 과정

1. OpenAI GPT-4o-mini를 사용하여 문제 생성
2. 레벨별, 타입별로 30개씩 생성
3. DB에 저장 (`TB_SLANG_QUIZ_QUESTIONS`)
4. JSON 파일로 백업 (`data/` 폴더)

### 프롬프트 전략

#### word_to_meaning (단어 → 뜻)
- 역할: 신조어 교육 전문가
- 문제: "자녀가 'OOO'라고 했다면 무슨 뜻일까요?"
- 보기: 정답 뜻 1개 + 그럴듯한 오답 뜻 3개

#### meaning_to_word (뜻 → 단어)
- 역할: 두뇌 훈련 및 언어 유희 전문가
- 문제: "다음 중 'OOO(뜻)'을 의미하는 단어는?"
- 보기: 정답 단어 1개 + **말장난 오답** 3개
  - 오답은 정답과 발음/글자가 비슷해서 헷갈리게 생성

### OpenAI 설정

- Model: `gpt-4o-mini`
- Temperature: `0.8` (창의성)
- Response Format: `{"type": "json_object"}`
- 재시도: 최대 3회

## 문제 선택 로직

사용자가 게임을 시작하면:

1. 사용자가 **이미 푼 문제 ID 조회**
2. **안 푼 문제 중에서 랜덤 5개 선택**
3. 안 푼 문제가 5개 미만이면 **전체에서 랜덤 선택**

이를 통해 사용자는 항상 새로운 문제를 우선적으로 접하게 됩니다.

## 보상 카드

정답을 맞추면 자녀 응원 메시지가 포함된 보상 카드를 제공합니다.

### 규칙

- 해당 신조어를 포함한 메시지 (30자 이내)
- 부정적 단어도 긍정적 맥락으로 포장
  - 예: "킹받는 일이 있어도 엄마는 네 편이야!"
- 배경 분위기: `warm`, `cheer`, `cool` 중 선택

## 테스트

### Swagger UI

서버 실행 후 http://localhost:8000/docs 접속

### 테스트 시나리오

1. **게임 시작**: POST `/start-game`
2. **문제 조회**: GET `/games/{game_id}/questions/2`
3. **답안 제출**: POST `/games/{game_id}/submit-answer`
4. **게임 종료**: POST `/games/{game_id}/end`
5. **히스토리 조회**: GET `/history`
6. **통계 조회**: GET `/statistics`
7. **게임 삭제**: DELETE `/games/{game_id}`

## 기술 스택

- **Backend**: Python 3.11, FastAPI
- **ORM**: SQLAlchemy
- **Validation**: Pydantic
- **AI**: OpenAI GPT-4o-mini
- **Database**: MySQL

## 폴더 구조

```
backend/app/slang_quiz/
├── __init__.py
├── routes.py           # API 엔드포인트 (8개)
├── service.py          # 비즈니스 로직
├── models.py           # Pydantic 모델
├── README.md           # 이 문서
├── data/               # JSON 백업
│   ├── beginner/
│   ├── intermediate/
│   └── advanced/
└── scripts/
    └── generate_initial_questions.py  # 초기 문제 생성
```

## 라이선스

이 프로젝트는 팀 프로젝트의 일부입니다.

