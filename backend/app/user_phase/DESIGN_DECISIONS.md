# User Phase Service 설계 결정 사항

## 개요

이 문서는 User Phase Service 개발 과정에서의 고민, 논의, 그리고 최종 결정 사항을 정리한 것입니다.

---

## 1. 서비스 위치 및 구조 결정

### 고민 사항
- **Engine vs Service**: `backend/engine/`에 둘지, `backend/app/`에 둘지?
- **서비스 이름**: "user_pattern" vs "user_phase"

### 결정
- **위치**: `backend/app/user_phase/` (Service로 구현)
- **이유**: 
  - 비즈니스 로직 서비스이므로 `app/` 폴더가 적합
  - Engine은 AI/ML 모델용, Service는 사용자 데이터 관리용
- **이름**: "user_phase" (현재 상태 중심)
- **이유**: "패턴 분석"보다는 "현재 Phase 판별"이 핵심 기능

### 구조
```
backend/app/user_phase/
├── __init__.py
├── models.py      # Pydantic 모델
├── service.py     # 비즈니스 로직
└── routes.py      # API 엔드포인트
```

---

## 2. 데이터베이스 설계 결정

### 2.1. 테이블 구조

#### 고민: 단일 테이블 vs OS별 테이블 분리

**옵션 1: OS별 테이블 분리**
```python
TB_APPLE_HEALTH_LOGS
TB_ANDROID_HEALTH_LOGS
```

**옵션 2: 통합 테이블 (선택)**
```python
TB_HEALTH_LOGS (SOURCE_TYPE으로 구분)
```

**결정: 옵션 2 (통합 테이블)**
- **이유**:
  - Phase 계산 시 두 테이블 JOIN 불필요
  - 사용자가 기기 변경 시 데이터 분산 방지
  - 확장성 (Fitbit, Samsung Health 등 추가 용이)
  - 코드 중복 방지

---

### 2.2. 데이터 저장 방식

#### 고민: 핵심 데이터만 vs 원본 데이터 전체

**옵션 1: 핵심 데이터만**
```python
SLEEP_END_TIME
STEP_COUNT
# Phase 계산에 필요한 최소 데이터만
```

**옵션 2: 핵심 + 원본 (선택)**
```python
SLEEP_END_TIME  # 빠른 조회용
STEP_COUNT
RAW_DATA (JSON)  # 원본 데이터 전체
```

**결정: 옵션 2 (하이브리드)**
- **이유**:
  - Phase 계산은 빠르게 (인덱싱된 컬럼 사용)
  - 나중에 다른 기능 개발 가능 (수면 질 분석, 심박수 모니터링 등)
  - 데이터 손실 없음

---

### 2.3. 갱년기 특화 데이터

#### 고민: 어떤 건강 데이터를 수집할까?

**타겟**: 갱년기 여성

**고려 사항**:
- Apple HealthKit vs Android Health Connect 공통 데이터만
- 체온 데이터: iOS만 지원 → 제외 (Android 차별 방지)

**결정: 공통 데이터만 사용**
```python
# 수면
SLEEP_DURATION_HOURS
SLEEP_START_TIME, SLEEP_END_TIME

# 심혈관
HEART_RATE_AVG
HEART_RATE_RESTING
HEART_RATE_VARIABILITY (HRV)

# 활동량
STEP_COUNT
ACTIVE_MINUTES
EXERCISE_MINUTES
CALORIES_BURNED
DISTANCE_KM
```

**제외한 데이터**:
- `BODY_TEMPERATURE`: Android Health Connect 미지원
- **이유**: iOS/Android 공평성 유지

---

### 2.4. NULL 처리

#### 고민: 모든 필드를 필수로 할까?

**결정: 대부분 Optional (nullable=True)**
- **이유**:
  - 사용자가 건강 앱을 사용하지 않을 수 있음
  - 일부 데이터만 있어도 Phase 계산 가능
  - 점진적 데이터 수집 가능

**필수 필드**:
- `USER_ID`, `LOG_DATE`, `SOURCE_TYPE`, `CREATED_AT`

**Optional 필드**:
- 모든 건강 데이터 (수면, 심박수, 활동량 등)

---

## 3. Phase 계산 로직 결정

### 3.1. Fallback 전략

#### 고민: 어떻게 Fallback을 구성할까?

**초기 계획**:
1. 실제 데이터
2. User Setting
3. 시스템 기본값 (07:00)

**문제점**:
- 시스템 기본값은 사용자마다 다를 수 있음
- 모든 사용자가 설정을 입력해야 함

**최종 결정: 2단계 Fallback (패턴 기반)**
1. **패턴 분석 결과** (최우선)
   - `TB_USER_PATTERN_SETTINGS` 조회
   - 오늘이 평일인지 주말인지 구분
   - 월요일에 계산된 평일/주말 평균 기상 시간으로 Phase 계산
   - `data_source`: "pattern_analysis" (패턴 분석 완료 시) 또는 "user_setting" (수동 설정만 있을 시)
2. **에러 처리** (설정 없음)
   - HTTPException 반환
   - "온보딩 필요 또는 건강 데이터 동기화 허용" 메시지

**이유**:
- 패턴 평균값 기반으로 일관된 Phase 계산 (알림 발송에 적합)
- 평일/주말 구분으로 더 정확한 Phase 계산
- 실시간 데이터는 나중에 추가 가능 (테스트 후 결정)
- 사용자 수동 설정은 건강 데이터 비동의 시 Fallback으로 사용

---

### 3.2. 패턴 분석 방식

#### 고민: 언제 패턴을 분석할까?

**옵션 1: 매일 자동**
- 매일 자정에 자동 분석

**옵션 2: 주 1회 (선택)**
- 월요일마다 또는 7일마다

**옵션 3: 수동 트리거**
- 사용자가 요청할 때만

**결정: 주 1회 자동 실행 (월요일) + 수동 트리거**
- **자동 실행 조건**:
  - 월요일에만 자동 실행
  - 지난 7일(월~일) 데이터 동기화 후 패턴 분석
  - `/sync` 호출 시 자동 체크
- **수동 실행**: `POST /analyze` 엔드포인트 제공

**이유**:
- 월요일에 지난 주 패턴을 한 번에 분석 (효율적)
- 사용자가 원할 때 즉시 분석 가능
- 자동화로 사용자 편의성 향상

---

### 3.3. 평일/주말 구분

#### 고민: 평일/주말을 구분해야 할까?

**초기 계획**: 단순히 하나의 기본값만

**문제점**:
- 평일 07:00 기상, 주말 10:00 기상 → 패턴이 다름
- 알림 발송 시 부정확할 수 있음

**결정: 평일/주말 구분**
```python
WEEKDAY_WAKE_TIME  # 월~금 평균
WEEKEND_WAKE_TIME  # 토~일 평균
```

**이유**:
- 실제 사용 패턴 반영
- 더 정확한 Phase 계산
- 갱년기 여성의 경우 주말 늦잠이 흔함

---

## 4. 알림 기능 관련 결정

### 고민: 알림을 어떻게 구현할까?

**문제점**:
- 알림은 사용자가 앱을 열기 전에 발송
- 그때는 오늘 건강 데이터가 없을 수 있음
- 평일/주말 패턴이 다를 수 있음

**초기 고민**:
- 전날 데이터로 오늘 알림 발송?
- User Setting 기반으로 알림 발송?

**최종 결정: 패턴 기반 Phase 계산 (알림 대응 가능)**
- **이유**:
  - 알림은 앱 실행 전에 발송되므로 오늘 실시간 데이터 사용 불가
  - 월요일에 계산된 평일/주말 평균 패턴으로 Phase 계산
  - 패턴 기반이므로 알림 발송 시점에도 정확한 Phase 예측 가능
  - 사용자가 앱을 열 때도 동일한 패턴으로 일관된 Phase 제공

**향후 계획**:
- 실시간 데이터 활용 여부는 테스트 후 결정
- 알림 기능 추가 시 패턴 기반 Phase로 발송 가능

---

## 5. 데이터 동기화 전략 결정

### 5.1. 동기화 시점

#### 고민: 언제 데이터를 동기화할까?

**옵션 1: 앱 실행 시마다**
- 사용자가 앱을 열 때마다 오늘 데이터 동기화

**옵션 2: 백그라운드 자동**
- HealthKit Background Delivery
- Health Connect Background Sync

**옵션 3: 하이브리드**
- 앱 실행 시 + 백그라운드

**결정: 옵션 1 (앱 실행 시)**
- **이유**:
  - 구현 간단
  - 배터리 효율적
  - 사용자가 제어 가능
  - Flutter 앱 개발 시 구현

**향후 계획**:
- Flutter 앱에서 HealthKit/Health Connect 연동
- 앱 실행 시 자동 동기화
- 백그라운드 동기화는 선택사항

---

### 5.2. 동기화 범위

#### 고민: 얼마나 많은 데이터를 동기화할까?

**옵션 1: 오늘만**
- Phase 계산에 필요한 최소 데이터

**옵션 2: 최근 7일**
- 패턴 분석용

**옵션 3: 전체 히스토리**
- 모든 과거 데이터

**결정: 오늘만 (기본) + 주간 동기화 (월요일)**
- **평일(화~일)**: 앱 실행 시 오늘 데이터만
- **월요일**: 지난 7일(월~일) 데이터 한 번에 동기화
- **이유**:
  - Phase 계산은 오늘 데이터만 필요
  - 패턴 분석은 7일 데이터 필요
  - 월요일에 한 번에 가져와서 분석 (효율적)

---

## 6. 테스트 전략 결정

### 고민: 어떻게 테스트할까?

**문제점**:
- Health Connect 데이터가 없음 (오늘 처음 사용)
- Flutter 앱 아직 없음
- 실제 데이터 수집 테스트 불가

**결정: 단계별 접근**
1. **지금**: 백엔드 API 로직 검증 (수동 데이터)
2. **나중에**: Flutter 앱 + 실제 건강 데이터

**테스트 데이터**:
- `source_type: "manual"`로 수동 입력
- Swagger UI에서 API 동작 확인
- Phase 계산 로직 검증

**진짜 테스트**:
- Flutter 앱 개발 후
- HealthKit/Health Connect 연동 후
- 실제 건강 데이터로 테스트

---

## 7. API 설계 결정

### 7.1. 엔드포인트 구조

**최종 엔드포인트**:
```
POST /api/service/user-phase/sync       # 동기화 + Phase 반환 (월요일: 7일 동기화)
GET  /api/service/user-phase/current    # Phase 조회
GET  /api/service/user-phase/settings   # 설정 조회
PUT  /api/service/user-phase/settings   # 설정 업데이트
POST /api/service/user-phase/analyze    # 패턴 분석 (수동 트리거)
GET  /api/service/user-phase/pattern    # 패턴 조회
```

**설계 원칙**:
- RESTful API 설계
- 명확한 엔드포인트 이름
- 인증 필수 (JWT)
- 일관된 응답 형식
- **월요일 자동 처리**: `/sync` 호출 시 월요일이면 지난 7일 데이터 동기화 및 패턴 분석

---

### 7.2. Upsert 동작

**결정: 같은 날짜면 업데이트**
- **이유**:
  - 사용자가 하루에 여러 번 동기화 가능
  - 최신 데이터로 업데이트
  - 중복 데이터 방지

**구현**:
```python
existing_log = db.query(HealthLog).filter(
    HealthLog.USER_ID == user_id,
    HealthLog.LOG_DATE == log_date
).first()

if existing_log:
    # Update
else:
    # Insert
```

---

## 8. 최종 아키텍처

### 데이터 흐름

```
1. Flutter 앱 실행
   ↓
2. HealthKit/Health Connect에서 데이터 가져오기
   - 평일(화~일): 오늘 데이터만
   - 월요일: 지난 7일(월~일) 데이터
   ↓
3. POST /sync → 서버로 전송 (날짜별로 각각)
   ↓
4. TB_HEALTH_LOGS에 저장 (upsert)
   ↓
5. 월요일이면 주간 패턴 분석 자동 실행
   ↓
6. TB_USER_PATTERN_SETTINGS 업데이트 (평일/주말 평균)
   ↓
7. GET /current → Phase 조회
   ↓
8. 패턴 분석 결과 기준으로 Phase 계산
   ↓
9. 응답 반환 (current_phase, hours_since_wake 등)
```

### Phase 계산 우선순위

```
패턴 분석 결과 (TB_USER_PATTERN_SETTINGS) - 최우선
  - 평일: 평일 평균 기상 시간
  - 주말: 주말 평균 기상 시간
  ↓ (없으면)
에러 (설정 필요 - 온보딩 또는 건강 데이터 동기화 허용)
```

---

## 9. 주요 트레이드오프

### 9.1. 실시간 데이터 vs 패턴 평균

**선택**: 패턴 평균 우선 (실시간은 나중에)
- 월요일 계산된 평일/주말 평균으로 Phase 계산
- 알림 발송에 적합 (앱 실행 전에도 Phase 예측 가능)
- 실시간 데이터 활용은 테스트 후 결정
- 일관된 Phase 제공으로 사용자 경험 향상

### 9.2. 확장성 vs 단순함

**선택**: 확장성 고려
- RAW_DATA JSON 필드 추가
- 나중에 다른 기능 개발 가능
- 지금 당장 사용 안 해도 구조 준비

### 9.3. 공평성 vs 기능

**선택**: 공평성 우선
- 체온 데이터 제외 (Android 미지원)
- iOS/Android 동일한 데이터 구조
- 기능 제한하더라도 공평성 유지

---

## 10. 향후 개선 사항

### 단기 (Flutter 앱 개발)
- [ ] HealthKit 연동
- [ ] Health Connect 연동
- [ ] 월요일 자동 7일 데이터 동기화
- [ ] 온보딩 화면 구현 (건강 데이터 동의 또는 수동 입력)

### 중기 (기능 확장)
- [ ] 실시간 데이터 활용 여부 결정 (테스트 후)
- [ ] 알림 기능 추가 (패턴 기반 Phase로 발송)
- [ ] 수면 질 분석
- [ ] 심혈관 건강 모니터링
- [ ] 활동량 목표 설정

### 장기 (고급 기능)
- [ ] AI 기반 패턴 예측
- [ ] 건강 인사이트 제공
- [ ] 루틴 추천과 통합 강화
- [ ] 웨어러블 기기 추가 지원

---

## 11. 핵심 설계 원칙

1. **실시간 데이터 우선**: 오늘 실제 데이터가 있으면 항상 사용
2. **Fallback 명확**: 단계별 Fallback 전략으로 안정성 확보
3. **확장 가능**: RAW_DATA로 나중에 기능 추가 용이
4. **공평성**: iOS/Android 동일한 데이터 구조
5. **사용자 중심**: 갱년기 여성의 건강 모니터링에 특화

---

## 결론

User Phase Service는 **실제 건강 데이터를 기반으로 정확한 Phase를 계산**하고, **주간 패턴 분석으로 개인화된 서비스**를 제공하는 것을 목표로 설계되었습니다.

주요 결정 사항:
- ✅ 통합 테이블 구조 (확장성)
- ✅ 평일/주말 구분 (정확성)
- ✅ 3단계 Fallback (안정성)
- ✅ 공통 데이터만 사용 (공평성)
- ✅ 하이브리드 패턴 분석 (자동화 + 수동)

이러한 설계 결정을 통해 **확장 가능하고 정확하며 사용자 친화적인** 서비스를 구현할 수 있었습니다.

