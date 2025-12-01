# User Phase Service API 명세서

## 개요

User Phase Service는 사용자의 건강 데이터(Apple HealthKit / Android Health Connect)를 수집하여 현재 활동 Phase를 계산하고, 주간 패턴 분석을 통해 평일/주말 패턴을 자동 학습하는 서비스입니다.

**Base URL**: `/api/service/user-phase`  
**인증**: 모든 API는 JWT 토큰 인증 필요 (`Authorization: Bearer {token}`)

**데이터 동기화 전략**:
- **평일(화~일)**: 앱 실행 시 오늘 데이터만 동기화
- **월요일**: 지난 7일(월~일) 데이터를 한 번에 동기화하고 패턴 분석 자동 실행

---

## Phase 정의

| Phase | 설명 | 조건 |
|-------|------|------|
| **morning** | 기상 후 0~3시간 | 기상 후 3시간 이내 |
| **day** | 기상 후 3~10시간 | 기상 후 3~10시간 |
| **evening** | 저녁 시간 | 기상 후 10시간 이상 OR 취침 전 2.5~3.5시간 |
| **sleep_prep** | 취침 준비 | 취침 전 0~2.5시간 |

---

## API 명세서

| HTTP 메서드 | 경로 | 설명 | 주요 파라미터 | 응답 형식 |
|------------|------|------|--------------|----------|
| POST | `/sync` | 건강 데이터 동기화 및 즉시 Phase 분석 | `log_date` (필수), `sleep_end_time`, `step_count`, `source_type` (필수) 등 | `UserPhaseResponse` |
| GET | `/current` | 현재 Phase 조회 | 없음 | `UserPhaseResponse` |
| GET | `/settings` | 사용자 설정 조회 | 없음 | `UserPatternSettingResponse` |
| PUT | `/settings` | 사용자 설정 업데이트 | `weekday_wake_time`, `weekday_sleep_time`, `weekend_wake_time`, `weekend_sleep_time` (모두 필수) | `UserPatternSettingResponse` |
| POST | `/analyze` | 주간 패턴 분석 (수동 트리거) | 없음 | `UserPatternResponse` |
| GET | `/pattern` | 패턴 분석 결과 조회 | 없음 | `UserPatternResponse` |

---

## API 상세

### POST /sync

건강 데이터를 동기화하고 즉시 Phase 분석 결과를 반환합니다.

**Request Body 예시:**
```json
{
  "log_date": "2025-11-27",
  "sleep_end_time": "2025-11-27T07:00:00Z",
  "step_count": 8500,
  "heart_rate_avg": 72,
  "source_type": "apple_health"
}
```

**Response 예시:**
```json
{
  "current_phase": "day",
  "hours_since_wake": 5.5,
  "hours_to_sleep": 6.5,
  "data_source": "real_data",
  "message": "기상 후 5시간 30분 경과",
  "health_data": {
    "sleep_duration_hours": 7.5,
    "heart_rate_avg": 72,
    "step_count": 8500
  }
}
```

**동작:**
- 같은 날짜 데이터가 있으면 업데이트 (upsert)
- **월요일**: 지난 7일(월~일) 데이터를 동기화하고 패턴 분석 자동 실행
- **평일(화~일)**: 오늘 데이터만 동기화
- Phase 계산은 패턴 분석 결과(평일/주말 평균)를 기준으로 수행

---

### GET /current

현재 사용자의 Phase를 조회합니다.

**Fallback 전략:**
1. 패턴 분석 결과 (평일/주말 평균) - 최우선
2. 사용자 수동 설정 (건강 데이터 비동의 시)
3. 에러 반환 (설정 필요)

**Phase 계산 방식:**
- 월요일에 계산된 평일/주말 평균 기상 시간을 기준으로 Phase 계산
- 오늘이 평일이면 평일 평균 사용, 주말이면 주말 평균 사용

**Response 예시:**
```json
{
  "current_phase": "day",
  "hours_since_wake": 5.5,
  "hours_to_sleep": 6.5,
  "data_source": "pattern_analysis",
  "message": "평일 패턴 기준 기상 후 5시간 30분 경과",
  "health_data": {
    "step_count": 8500,
    "heart_rate_avg": 72
  }
}
```

---

### PUT /settings

사용자 패턴 설정을 업데이트합니다. 
- **용도**: 건강 데이터 동기화 비동의 시 수동 입력
- **시점**: 온보딩 시 또는 설정 페이지에서

**Request Body 예시:**
```json
{
  "weekday_wake_time": "07:00",
  "weekday_sleep_time": "23:00",
  "weekend_wake_time": "09:00",
  "weekend_sleep_time": "01:00",
  "is_night_worker": false
}
```

---

### POST /analyze

지난 7일 건강 데이터를 분석하여 평일/주말 패턴을 계산합니다.

**Response 예시:**
```json
{
  "weekday": {
    "avg_wake_time": "07:15",
    "avg_sleep_time": "23:30"
  },
  "weekend": {
    "avg_wake_time": "09:30",
    "avg_sleep_time": "01:00"
  },
  "last_analysis_date": "2025-11-27",
  "data_completeness": 0.86,
  "analysis_period_days": 7,
  "insight": "평일보다 주말에 2시간 15분 늦게 일어나시네요"
}
```

**자동 실행 조건:**
- 마지막 분석 후 7일 경과
- 월요일이고 이번 주 분석 안 함
- `/sync` 호출 시 자동 체크

---

## 데이터베이스 스키마

### TB_HEALTH_LOGS

일별 건강 데이터를 저장하는 테이블입니다.

| 컬럼명 | 타입 | NULL 허용 | 기본값 | 설명 | 제약조건/인덱스 |
|--------|------|----------|--------|------|----------------|
| `ID` | INTEGER | ❌ | AUTO_INCREMENT | Primary Key | PRIMARY KEY, INDEX |
| `USER_ID` | INTEGER | ❌ | - | Foreign Key → TB_USERS.ID | FOREIGN KEY, INDEX |
| `LOG_DATE` | DATE | ❌ | - | 건강 데이터 날짜 (YYYY-MM-DD) | INDEX |
| `SLEEP_START_TIME` | DATETIME | ✅ | NULL | 취침 시간 (timezone aware) | - |
| `SLEEP_END_TIME` | DATETIME | ✅ | NULL | 기상 시간 (timezone aware) - Phase 계산용 | - |
| `STEP_COUNT` | INTEGER | ✅ | NULL | 걸음 수 | - |
| `SLEEP_DURATION_HOURS` | FLOAT | ✅ | NULL | 수면 시간 (시간) | - |
| `HEART_RATE_AVG` | INTEGER | ✅ | NULL | 평균 심박수 | - |
| `HEART_RATE_RESTING` | INTEGER | ✅ | NULL | 안정 시 심박수 | - |
| `HEART_RATE_VARIABILITY` | FLOAT | ✅ | NULL | 심박 변이도 (HRV) | - |
| `ACTIVE_MINUTES` | INTEGER | ✅ | NULL | 활동 시간 (분) | - |
| `EXERCISE_MINUTES` | INTEGER | ✅ | NULL | 운동 시간 (분) | - |
| `CALORIES_BURNED` | INTEGER | ✅ | NULL | 소모 칼로리 | - |
| `DISTANCE_KM` | FLOAT | ✅ | NULL | 이동 거리 (km) | - |
| `SOURCE_TYPE` | VARCHAR(50) | ❌ | - | 데이터 출처 ("manual", "apple_health", "google_fit") | - |
| `RAW_DATA` | JSON | ✅ | NULL | 원본 데이터 (확장용) | - |
| `CREATED_AT` | DATETIME | ❌ | CURRENT_TIMESTAMP | 생성 시간 (timezone aware) | - |

**인덱스:**
- 복합 인덱스: `idx_user_date` (`USER_ID`, `LOG_DATE`)

**제약조건:**
- `USER_ID` + `LOG_DATE` 조합은 유니크하지 않음 (같은 날짜 여러 번 동기화 가능)
- Upsert 로직으로 같은 날짜면 업데이트

---

### TB_USER_PATTERN_SETTINGS

주간 패턴 분석 결과를 저장하는 테이블입니다.

| 컬럼명 | 타입 | NULL 허용 | 기본값 | 설명 | 제약조건/인덱스 |
|--------|------|----------|--------|------|----------------|
| `ID` | INTEGER | ❌ | AUTO_INCREMENT | Primary Key | PRIMARY KEY, INDEX |
| `USER_ID` | INTEGER | ❌ | - | Foreign Key → TB_USERS.ID | FOREIGN KEY, UNIQUE, INDEX |
| `WEEKDAY_WAKE_TIME` | TIME | ❌ | - | 평일 평균 기상 시간 (HH:MM:SS) | - |
| `WEEKDAY_SLEEP_TIME` | TIME | ❌ | - | 평일 평균 취침 시간 (HH:MM:SS) | - |
| `WEEKEND_WAKE_TIME` | TIME | ❌ | - | 주말 평균 기상 시간 (HH:MM:SS) | - |
| `WEEKEND_SLEEP_TIME` | TIME | ❌ | - | 주말 평균 취침 시간 (HH:MM:SS) | - |
| `LAST_ANALYSIS_DATE` | DATE | ✅ | NULL | 마지막 패턴 분석 날짜 | - |
| `DATA_COMPLETENESS` | FLOAT | ✅ | NULL | 데이터 완성도 (0.0~1.0) | - |
| `IS_NIGHT_WORKER` | BOOLEAN | ❌ | FALSE | 야간 근무 여부 | - |
| `CREATED_AT` | DATETIME | ❌ | CURRENT_TIMESTAMP | 생성 시간 (timezone aware) | - |
| `UPDATED_AT` | DATETIME | ❌ | CURRENT_TIMESTAMP | 수정 시간 (timezone aware) | - |

**제약조건:**
- `USER_ID`는 UNIQUE (사용자당 1개 설정만 존재)
- 온보딩 시 초기값 설정, 이후 주간 분석으로 자동 업데이트

---

## 사용 예시

### 시나리오 1: 첫 사용자 온보딩

```http
PUT /api/service/user-phase/settings
{
  "weekday_wake_time": "07:00",
  "weekday_sleep_time": "23:00",
  "weekend_wake_time": "09:00",
  "weekend_sleep_time": "01:00"
}

GET /api/service/user-phase/current
→ Response: {
    "current_phase": "day",
    "data_source": "pattern_analysis",
    ...
  }
```

### 시나리오 2: 건강 데이터 동기화

```http
POST /api/service/user-phase/sync
{
  "log_date": "2025-11-27",
  "sleep_end_time": "2025-11-27T07:00:00Z",
  "step_count": 8500,
  "source_type": "apple_health"
}

→ Response: {
    "current_phase": "day",
    "data_source": "real_data",
    ...
  }
```

---

## 에러 처리

| 상태 코드 | 설명 | 예시 |
|----------|------|------|
| 400 | Bad Request | 사용자 설정이 필요합니다 |
| 404 | Not Found | 사용자 설정이 없습니다 |
| 500 | Internal Server Error | 건강 데이터 동기화 실패 |

---

## 참고 문서

- **설계 결정 사항**: `DESIGN_DECISIONS.md`
- **DB 가이드**: `backend/DB_GUIDE.md`
- **개발 가이드**: `backend/DEVELOPER_GUIDE.md`
