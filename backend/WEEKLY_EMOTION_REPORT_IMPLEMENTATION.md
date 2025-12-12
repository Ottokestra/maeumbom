# 주간 감정 리포트 구현 완료 보고서

## 구현 개요
마이페이지에서 주간 감정 리포트를 조회할 수 있도록 DB 테이블, 서비스 로직, API 엔드포인트를 구현했습니다.

## 구현 내용

### 1. 데이터베이스 모델 (✅ 완료)

**파일**: `app/emotion_report/models_weekly.py`

**테이블**: `TB_WEEKLY_EMOTION_REPORTS`

**주요 필드**:
- `ID`: Primary Key
- `USER_ID`: 사용자 FK (TB_USERS.ID)
- `WEEK_START`: 주 시작일 (Date)
- `WEEK_END`: 주 종료일 (Date)
- `EMOTION_TEMPERATURE`: 감정 온도 (Integer, 0-100)
- `POSITIVE_SCORE`: 긍정 점수 (Integer, 0-100)
- `NEGATIVE_SCORE`: 부정 점수 (Integer, 0-100)
- `NEUTRAL_SCORE`: 중립 점수 (Integer, 0-100)
- `MAIN_EMOTION`: 주요 감정 (String)
- `MAIN_EMOTION_CONFIDENCE`: 주요 감정 신뢰도 (Float, 0.0-1.0)
- `MAIN_EMOTION_CHARACTER_CODE`: 캐릭터 코드 (String)
- `BADGES`: 뱃지 목록 (Text, JSON 문자열)
- `SUMMARY_TEXT`: 요약 텍스트 (Text)
- `CREATED_AT`: 생성 시각 (DateTime)
- `UPDATED_AT`: 수정 시각 (DateTime)

**특징**:
- 기존 테이블은 건드리지 않음
- Base.metadata.create_all()로 자동 생성되도록 app/db/models.py에 import 추가
- badges는 Text 타입으로 JSON 문자열 저장, 서비스 계층에서 List[str]로 변환

### 2. Pydantic 스키마 (✅ 완료)

**파일**: `app/emotion_report/schemas_weekly.py`

**스키마 목록**:
1. `WeeklyEmotionReportBase`: 기본 필드
2. `WeeklyEmotionReportCreate`: 생성용 (user_id는 current_user에서 자동 설정)
3. `WeeklyEmotionReportRead`: 조회용 (전체 필드 포함)
4. `WeeklyEmotionReportListItem`: 리스트용 (간소화된 필드)
5. `WeeklyReportListResponse`: 리스트 응답 래퍼

**특징**:
- week_start/week_end는 date 타입 (datetime 아님)
- badges는 List[str] 타입으로 정의
- from_attributes=True로 SQLAlchemy 모델 자동 변환

### 3. 서비스 계층 (✅ 완료)

**파일**: `app/emotion_report/service_weekly.py`

**주요 함수**:

1. **upsert_weekly_report()**
   - 동일 user_id + week_start + week_end 조합 확인
   - 있으면 update, 없으면 insert
   - badges List[str] → JSON 문자열 변환

2. **get_weekly_report_by_id()**
   - user_id + report_id 기준 조회
   - 권한 보호: 다른 사용자 리포트 조회 불가

3. **get_weekly_report_by_week()**
   - user_id + week_start + week_end 기준 조회
   - week_end가 None이면 week_start + 6일로 계산

4. **list_weekly_reports()**
   - user_id 기준 최근 N주 리포트 조회
   - week_start DESC 정렬
   - limit 개수 반환 (기본 8개)

5. **convert_badges_to_list()**
   - DB의 JSON 문자열 → List[str] 변환 헬퍼 함수

**특징**:
- 모든 함수는 user_id를 필수 인자로 받아 데이터 격리
- badges 변환 로직 포함

### 4. API 라우터 (✅ 완료)

**파일**: `app/emotion_report/router_weekly.py`

**Prefix**: `/api/v1/reports/emotion/weekly`

**엔드포인트**:

#### [1] POST /api/v1/reports/emotion/weekly/generate
- **인증**: 필요 (Bearer Token)
- **Query Params**:
  - `week_start`: str (YYYY-MM-DD, 필수)
  - `week_end`: str (YYYY-MM-DD, 선택, 기본값: week_start + 6일)
- **동작**:
  - current_user.id 기준으로 감정 리포트 계산
  - upsert_weekly_report() 호출하여 DB 저장
  - 현재는 더미 데이터 사용 (TODO: 실제 감정 분석 로직 연동)
- **응답**: WeeklyEmotionReportRead

#### [2] GET /api/v1/reports/emotion/weekly/{report_id}
- **인증**: 필요 (Bearer Token)
- **Path Param**: `report_id` (int)
- **동작**:
  - current_user.id + report_id 기준 조회
  - 없으면 404 반환
- **응답**: WeeklyEmotionReportRead

#### [3] GET /api/v1/reports/emotion/weekly
- **인증**: 필요 (Bearer Token)
- **Query Params**:
  - `week_start`: str (YYYY-MM-DD, 필수)
  - `week_end`: str (YYYY-MM-DD, 선택)
- **동작**:
  - current_user.id 기준 주간 리포트 조회
  - 없으면 404 반환
- **응답**: WeeklyEmotionReportRead

#### [4] GET /api/v1/reports/emotion/weekly/list
- **인증**: 필요 (Bearer Token)
- **Query Params**:
  - `limit`: int (기본값: 8, 최대: 100)
- **동작**:
  - current_user.id 기준 최근 N주 리포트 조회
  - WeeklyEmotionReportListItem 리스트로 변환
- **응답**: { "items": [ WeeklyEmotionReportListItem, ... ] }

**특징**:
- 모든 엔드포인트에 get_current_user 의존성 적용
- 외부에서 userId 파라미터 받지 않음 (토큰 기준 본인 데이터만)
- 날짜 파싱 및 유효성 검사 포함
- badges JSON → List 변환 로직 포함

### 5. 라우터 등록 (✅ 완료)

**파일**: `main.py` (lines 247-258)

```python
try:
    from app.emotion_report.router_weekly import router as emotion_weekly_router
    app.include_router(emotion_weekly_router)
    print("[INFO] Weekly emotion report router loaded successfully.")
except Exception as e:
    import traceback
    print(f"[WARN] Weekly emotion report router load failed: {e}")
    traceback.print_exc()
```

### 6. 모델 Import (✅ 완료)

**파일**: `app/db/models.py` (마지막 줄)

```python
from app.emotion_report.models_weekly import WeeklyEmotionReport  # noqa: F401, E402
```

이를 통해 `init_db()` 호출 시 `Base.metadata.create_all()`로 테이블이 자동 생성됩니다.

## 마이페이지 연동 플로우

### 1. 이번 주 감정 리포트 보기
```
프론트엔드 → GET /api/v1/reports/emotion/weekly?weekStart=2025-12-09
  ↓
  404 (리포트 없음)
  ↓
프론트엔드 → "리포트 생성" 버튼 노출
```

### 2. 리포트 생성
```
프론트엔드 → POST /api/v1/reports/emotion/weekly/generate?week_start=2025-12-09
  ↓
백엔드 → 감정 데이터 계산 (현재는 더미, TODO: 실제 로직)
  ↓
백엔드 → DB에 저장 (upsert)
  ↓
프론트엔드 ← WeeklyEmotionReportRead 응답
```

### 3. 지난 N주 히스토리
```
프론트엔드 → GET /api/v1/reports/emotion/weekly/list?limit=8
  ↓
백엔드 → 최근 8주 리포트 조회
  ↓
프론트엔드 ← { "items": [...] }
  ↓
프론트엔드 → 주간별 카드/그래프 렌더링
```

## 테스트 시나리오

### 1. 서버 실행
```bash
cd C:\Users\Admin\dev\new-maeumbom\backend
python main.py
```

### 2. 리포트 생성 테스트
```bash
# 로그인하여 토큰 획득 (예시)
curl -X POST http://localhost:8000/api/v1/reports/emotion/weekly/generate?week_start=2025-12-09 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. 주간 리포트 조회
```bash
curl -X GET "http://localhost:8000/api/v1/reports/emotion/weekly?week_start=2025-12-09" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. 리스트 조회
```bash
curl -X GET "http://localhost:8000/api/v1/reports/emotion/weekly/list?limit=8" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. Swagger 문서 확인
```
http://localhost:8000/docs
→ "Weekly Emotion Report" 섹션 확인
```

## 주의사항

### ✅ 구현 완료
- DB 모델 정의 및 자동 생성 설정
- Pydantic 스키마 정의
- 서비스 계층 (CRUD + 변환 로직)
- API 라우터 (인증 포함)
- 라우터 등록
- badges JSON 변환 로직

### ⚠️ TODO (향후 작업)
1. **감정 리포트 계산 엔진 연동**
   - 현재는 `POST /generate` 엔드포인트에서 더미 데이터 사용
   - 실제 구현 시:
     - TB_EMOTION_ANALYSIS에서 해당 주간 데이터 조회
     - TB_CONVERSATIONS에서 대화 내용 조회
     - emotion_temperature, scores, main_emotion, badges, summary_text 계산
     - 기존 감정 분석 엔진 재사용

2. **뱃지 정의**
   - 뱃지 목록 및 조건 정의 필요
   - 예: ["불안多", "지침", "회복시도", "긍정", "활력", ...]

3. **캐릭터 코드 매핑**
   - main_emotion_character_code 값 정의
   - 프론트엔드 캐릭터 이미지와 매핑

## 파일 변경 사항

### 신규 파일
- ❌ (모두 기존 파일 수정)

### 수정 파일
1. `app/emotion_report/models_weekly.py` - 모델 재정의
2. `app/emotion_report/schemas_weekly.py` - 스키마 재작성
3. `app/emotion_report/service_weekly.py` - 서비스 재작성
4. `app/emotion_report/router_weekly.py` - 라우터 재작성
5. `app/db/models.py` - WeeklyEmotionReport import 추가

### 변경 없음
- `main.py` - 이미 라우터 등록되어 있음
- `app/db/database.py` - init_db() 로직 그대로 사용

## 데이터베이스 마이그레이션

### 자동 생성
서버 시작 시 `init_db()` 호출로 자동 생성됩니다:
```python
Base.metadata.create_all(bind=engine)
```

### 수동 확인 (선택)
```sql
-- 테이블 확인
SHOW TABLES LIKE 'TB_WEEKLY_EMOTION_REPORTS';

-- 스키마 확인
DESC TB_WEEKLY_EMOTION_REPORTS;
```

## 완료 체크리스트

- [x] 1-1: Base 모델 확인 및 import 경로 설정
- [x] 1-2: WeeklyEmotionReport 모델 정의 (TB_WEEKLY_EMOTION_REPORTS)
- [x] 2-1: 스키마 파일 작성
- [x] 2-2: Pydantic 모델 정의 (Base, Create, Read, ListItem, ListResponse)
- [x] 3-1: 서비스 파일 작성
- [x] 3-2: CRUD 함수 구현 (upsert, get_by_id, get_by_week, list)
- [x] 4-1: 라우터 파일 작성
- [x] 4-2: 인증 의존성 적용 (get_current_user)
- [x] 4-3: 4개 엔드포인트 구현 (generate, get by id, get by week, list)
- [x] 4-4: main.py 라우터 등록 확인
- [x] 5: 마이페이지 연동 플로우 정리
- [x] 6: 테스트 시나리오 작성

## 다음 단계

1. **서버 실행 및 테스트**
   ```bash
   cd C:\Users\Admin\dev\new-maeumbom\backend
   python main.py
   ```

2. **Swagger 문서 확인**
   - http://localhost:8000/docs
   - "Weekly Emotion Report" 섹션 확인

3. **실제 감정 리포트 계산 로직 구현**
   - `router_weekly.py`의 `generate_weekly_report()` 함수에서
   - TODO 주석 부분을 실제 로직으로 교체

4. **프론트엔드 연동**
   - Flutter 앱에서 API 호출 테스트
   - 마이페이지 UI 구현
