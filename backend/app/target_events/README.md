# 대상별 이벤트 (Target Events - 마음서랍)

## 개요

사용자가 챗봇과 대화한 내용(`TB_CONVERSATIONS`)에서 주요 대상(남편/자녀/친구/직장동료)과의 이벤트, 약속, 중요 기억을 LLM으로 자동 분석하여 일간/주간 단위로 저장하고, 프론트엔드에서 태그 형태로 필터링/표시할 수 있는 시스템입니다.

## 주요 기능

### 1. 일일 대화 분석
- 특정 날짜의 모든 대화를 LLM(GPT-4o-mini)으로 분석
- **하루에 1개의 통합 이벤트**로 요약 저장
- 대상별(HUSBAND/CHILD/FRIEND/COLLEAGUE/SELF) 이벤트 추출
- 이벤트 타입(alarm/event/memory) 자동 분류
- 시간 정보, 중요도, 태그 자동 생성
- `TB_DAILY_TARGET_EVENTS` 테이블에 저장

### 2. 주간 이벤트 요약
- 월~일 주간 단위로 일간 이벤트 요약
- 대상별로 그룹화하여 주간 요약 생성
- `TB_WEEKLY_TARGET_EVENTS` 테이블에 저장

### 3. 이벤트 타입 분류
- **alarm**: 알람/알림 요청 (무조건 TARGET_TYPE=SELF)
- **event**: 약속/일정 (구체적인 날짜/시간이 있는 약속, 만남 등)
- **memory**: 일반 대화 기억 (위 두 가지가 아닌 일반적인 대화 내용)

### 4. 대상 타입 (TARGET_TYPE)
- **HUSBAND**: 남편 관련
- **CHILD**: 자녀 관련 (아들/딸 통합)
- **FRIEND**: 친구 관련
- **COLLEAGUE**: 직장동료 관련
- **SELF**: 봄이와 대화, 알람 등 (자기 자신)

### 5. 태그 시스템
- **대상 태그**: #남편, #자녀, #친구, #직장동료, #나
- **이벤트 유형**: #약속, #픽업, #만남, #식사, #통화예정, #기념일, #알림요청, #중요대화
- **시간 태그**: #오늘, #내일, #이번주, #다음주, #이번달, #과거
- **중요도 태그**: #매우중요, #중요, #보통
- **감정 태그**: #긍정적, #부정적, #걱정, #기대 (선택적)

### 6. 필터링 및 조회
- 이벤트 타입 필터링 (alarm/event/memory)
- 태그 기반 필터링
- 날짜 범위 필터링
- 대상 유형 필터링
- 인기 태그 조회

## 파일 구조

```
backend/app/target_events/
├── __init__.py           # 모듈 초기화
├── constants.py          # 태그 상수 정의
├── analyzer.py           # LLM 분석 엔진
├── service.py            # 비즈니스 로직
├── routes.py             # API 엔드포인트
├── schemas.py            # Pydantic 스키마
└── README.md             # 이 문서

backend/scripts/
└── migrate_target_events.py  # 마이그레이션 스크립트
```

## 데이터베이스 모델

### TB_DAILY_TARGET_EVENTS
일간 대상별 이벤트 저장

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| ID | Integer | Primary Key |
| USER_ID | Integer | 사용자 ID |
| EVENT_DATE | Date | 이벤트 날짜 (분석 날짜로 저장) |
| EVENT_TYPE | String | 이벤트 타입 (alarm/event/memory) |
| TARGET_TYPE | String | 대상 유형 (HUSBAND/CHILD/FRIEND/COLLEAGUE/SELF) |
| EVENT_SUMMARY | Text | 이벤트 요약 (하루 전체 대화 통합 요약) |
| EVENT_TIME | DateTime | 이벤트 시간 (nullable) |
| IMPORTANCE | Integer | 중요도 (1-5) |
| IS_FUTURE_EVENT | Boolean | 미래 이벤트 여부 |
| TAGS | JSON | 태그 배열 |
| RAW_CONVERSATION_IDS | JSON | 원본 대화 ID 배열 |

**특징**:
- 하루에 사용자당 **1개의 이벤트만** 저장됨
- 알람 타입은 무조건 `TARGET_TYPE=SELF`
- `EVENT_DATE`는 분석한 날짜로 저장 (LLM이 계산한 날짜가 아님)

### TB_WEEKLY_TARGET_EVENTS
주간 대상별 이벤트 요약

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| ID | Integer | Primary Key |
| USER_ID | Integer | 사용자 ID |
| WEEK_START | Date | 주 시작일 (월요일) |
| WEEK_END | Date | 주 종료일 (일요일) |
| TARGET_TYPE | String | 대상 유형 (HUSBAND/CHILD/FRIEND/COLLEAGUE/SELF) |
| EVENTS_SUMMARY | JSON | 주간 이벤트 요약 배열 |
| TOTAL_EVENTS | Integer | 총 이벤트 수 |
| TAGS | JSON | 통합 태그 배열 |
| EMOTION_DISTRIBUTION | JSON | 주간 감정 비율 분포 (예: `{"안정": 35, "기쁨": 25, ...}`) |
| PRIMARY_EMOTION | String | 주요 감정 |
| SENTIMENT_OVERALL | String | 전체 감정 (positive/negative/neutral) |

**감정 데이터**:
- `EMOTION_DISTRIBUTION`: 해당 주간의 감정 비율을 백분율로 표시 (상위 5개 감정)
- `PRIMARY_EMOTION`: 가장 높은 비율의 감정
- `SENTIMENT_OVERALL`: 전체적인 감정 경향
- 감정 데이터는 `TB_ROUTINE_RECOMMENDATIONS` 테이블의 일일 감정 데이터를 집계하여 생성됨

## API 엔드포인트

### 분석 실행

#### POST `/api/target-events/analyze-daily`
특정 날짜의 대화 분석 실행

**요청**:
```json
{
  "target_date": "2024-12-13"
}
```

**응답**:
```json
{
  "analyzed_date": "2024-12-13",
  "events_count": 3,
  "events": [...]
}
```

#### POST `/api/target-events/analyze-weekly`
특정 주간의 이벤트 요약 실행

**요청**:
```json
{
  "week_start": "2024-12-09"
}
```

### 조회

#### GET `/api/target-events/daily`
일간 이벤트 목록 조회 (이벤트 타입 및 태그 필터링 지원)

**Query Parameters**:
- `event_type` (optional): 이벤트 타입 (alarm/event/memory)
- `tags` (optional): 쉼표로 구분된 태그 (예: `#아들,#픽업`)
- `start_date` (optional): 시작 날짜 (YYYY-MM-DD)
- `end_date` (optional): 종료 날짜 (YYYY-MM-DD)
- `target_type` (optional): 대상 유형 (HUSBAND/CHILD/FRIEND/COLLEAGUE/SELF)

#### GET `/api/target-events/weekly`
주간 이벤트 목록 조회

#### GET `/api/target-events/tags/popular`
자주 사용되는 태그 목록 조회

## 사용 방법

### 1. 데이터베이스 마이그레이션

새로운 테이블을 생성하기 위해 데이터베이스 마이그레이션을 실행합니다:

```bash
# Alembic을 사용하는 경우
alembic revision --autogenerate -m "Add target events tables"
alembic upgrade head

# 또는 init_db() 호출 시 자동 생성
```

### 2. 기존 데이터 마이그레이션

기존 대화 데이터를 분석하여 이벤트를 추출합니다:

```bash
# 최근 30일 데이터 마이그레이션
python backend/scripts/migrate_target_events.py --days 30

# 특정 날짜 마이그레이션
python backend/scripts/migrate_target_events.py --date 2024-12-13

# 특정 기간 마이그레이션
python backend/scripts/migrate_target_events.py --start-date 2024-12-01 --end-date 2024-12-13

# 특정 사용자만 마이그레이션
python backend/scripts/migrate_target_events.py --user-id 1 --days 30

# Dry run (실제 저장하지 않고 분석만)
python backend/scripts/migrate_target_events.py --days 7 --dry-run
```

### 3. API 호출 예시

#### 일일 분석 실행
```bash
curl -X POST "http://localhost:8000/api/target-events/analyze-daily" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_date": "2024-12-13"}'
```

#### 이벤트 타입 및 태그로 필터링하여 조회
```bash
# 알람만 조회
curl -X GET "http://localhost:8000/api/target-events/daily?event_type=alarm" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 일정만 조회
curl -X GET "http://localhost:8000/api/target-events/daily?event_type=event" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 태그로 필터링
curl -X GET "http://localhost:8000/api/target-events/daily?tags=%23자녀,%23픽업&start_date=2024-12-01&end_date=2024-12-31" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 알람 + 특정 대상
curl -X GET "http://localhost:8000/api/target-events/daily?event_type=alarm&target_type=SELF" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### 인기 태그 조회
```bash
curl -X GET "http://localhost:8000/api/target-events/tags/popular?limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 실행 방식 및 향후 계획

### 현재: 수동 스크립트 실행

현재는 배치 스크립트를 수동으로 실행하여 대화를 분석합니다:

**일간 분석:**
```bash
# 최근 40일치 분석
python backend/scripts/migrate_target_events.py --days 40

# 특정 기간 분석
python backend/scripts/migrate_target_events.py --start-date 2025-11-06 --end-date 2025-12-13
```

**주간 요약:**
```bash
# 최근 40일치 주간 요약
python backend/scripts/generate_weekly_summaries.py --days 40

# 특정 기간 주간 요약
python backend/scripts/generate_weekly_summaries.py --start-date 2025-11-06 --end-date 2025-12-13
```

### 향후 계획: 자동화 (스케줄러)

추후 다음과 같이 자동화할 예정입니다:

- **일간 분석**: 매일 자정에 전날 대화 자동 분석
- **주간 요약**: 매주 월요일에 지난주 요약 자동 생성
- **구현 방법**: APScheduler 또는 Celery Beat 사용

**예상 구조:**
```python
# 매일 자정 실행
@scheduler.scheduled_job('cron', hour=0, minute=0)
def daily_analysis_job():
    yesterday = date.today() - timedelta(days=1)
    # 모든 사용자의 전날 대화 분석
    
# 매주 월요일 자정 실행
@scheduler.scheduled_job('cron', day_of_week='mon', hour=0, minute=0)
def weekly_summary_job():
    # 모든 사용자의 지난주 요약 생성
```

**장점:**
- 사용자가 신경 쓸 필요 없음
- 매일 최신 데이터 유지
- 안정적이고 예측 가능

## LLM 분석 로직

### 일일 분석 프롬프트
- **하루의 모든 대화를 반드시 1개의 이벤트로 통합 요약**
- 이벤트 타입 분류: alarm > event > memory (우선순위)
- 대상 타입 분류:
  - 알람 요청 → 무조건 SELF
  - 봄이와만 대화 → SELF
  - 남편 언급 → HUSBAND
  - 아들/딸 언급 → CHILD (구분하지 않음)
  - 친구 언급 → FRIEND
  - 직장동료 언급 → COLLEAGUE
- 시간 정보 파싱
- 중요도 평가 (1-5점)
- 태그 자동 생성

### 주간 요약 프롬프트
- 일간 이벤트를 날짜별로 요약
- 대상별로 그룹화
- 빈도 높은 태그 추출

## 감정 데이터 집계

### 데이터 소스
- `TB_ROUTINE_RECOMMENDATIONS` 테이블의 `EMOTION_SUMMARY` 컬럼 사용
- 일일 감정 분석 결과를 주간 단위로 집계

### EMOTION_SUMMARY 구조
```json
{
  "primary_emotion": {
    "code": "joy",
    "name_ko": "기쁨",
    "intensity": 2,
    "confidence": 0.95
  },
  "sentiment_overall": "positive",
  "secondary_emotions": [
    {"code": "excitement", "name_ko": "흥분", "intensity": 1},
    {"code": "relief", "name_ko": "안심", "intensity": 1}
  ]
}
```

### 집계 로직
1. **Primary Emotion**: `primary_emotion.code`와 `intensity` 추출
2. **Secondary Emotions**: `secondary_emotions` 배열의 각 감정 `code`와 `intensity` 추출
3. **Intensity 합산**: 모든 감정의 intensity를 합산하여 주간 점수 계산
4. **백분율 변환**: 상위 5개 감정을 백분율로 변환
5. **한글 매핑**: 감정 코드를 한글 이름으로 변환

### 감정 코드 매핑

| 코드 | 한글 | 코드 | 한글 |
|------|------|------|------|
| joy | 기쁨 | anger | 분노 |
| calm | 안정 | sadness | 슬픔 |
| love | 사랑 | fear | 두려움 |
| excitement | 흥분 | anxiety | 불안 |
| confidence | 자신감 | worry | 걱정 |
| relief | 안심 | depression | 우울 |
| interest | 흥미 | boredom | 무기력 |
| surprise | 놀람 | confusion | 혼란 |
| disgust | 혐오 | contempt | 경멸 |
| - | - | discontent | 불만 |

### 결과 예시
```json
{
  "emotion_distribution": {
    "기쁨": 35,
    "안정": 25,
    "사랑": 20,
    "분노": 12,
    "걱정": 8
  },
  "primary_emotion": "기쁨",
  "sentiment_overall": "positive"
}
```

## 환경 변수

```bash
# OpenAI API Key (필수)
OPENAI_API_KEY=your_openai_api_key
```

## 주의사항

1. **LLM 비용**: GPT-4o-mini를 사용하므로 API 비용이 발생합니다.
2. **분석 시간**: 대화량이 많을 경우 분석에 시간이 소요될 수 있습니다.
3. **중복 분석**: 같은 날짜를 다시 분석하면 기존 이벤트가 삭제되고 새로 생성됩니다.
4. **하루 1개 제한**: 하루에 사용자당 1개의 이벤트만 저장됩니다 (여러 대상과 대화해도 통합 요약).
5. **알람 자동 분류**: 알람 타입은 무조건 `TARGET_TYPE=SELF`로 저장됩니다.
6. **EVENT_DATE**: 분석한 날짜로 저장되며, LLM이 계산한 날짜가 아닙니다.
7. **태그 필터링**: SQLite에서는 JSON 필터링이 제한적이므로 Python에서 후처리합니다.

## 향후 개선 사항

1. **배치 스케줄링**: 매일 자동으로 전날 대화 분석
2. **알림 기능**: 미래 이벤트에 대한 알림 발송
3. **태그 커스터마이징**: 사용자가 직접 태그 추가/수정
4. **통계 대시보드**: 대상별 이벤트 통계 시각화
5. **캐싱**: 자주 조회되는 데이터 캐싱

## 문의

문제가 발생하거나 개선 사항이 있으면 팀에 문의하세요.

