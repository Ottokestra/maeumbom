# 주간 이벤트 감정 데이터 추가 마이그레이션 가이드

## 개요

`TB_WEEKLY_TARGET_EVENTS` 테이블에 주간 감정 분석 데이터를 추가하는 마이그레이션입니다.

## 변경 사항

### 데이터베이스 스키마

`TB_WEEKLY_TARGET_EVENTS` 테이블에 3개의 컬럼이 추가되었습니다:

| 컬럼명 | 타입 | 설명 | Nullable |
|--------|------|------|----------|
| `EMOTION_DISTRIBUTION` | JSON | 감정 비율 분포 (예: `{"안정": 35, "기쁨": 25, "사랑": 20, "분노": 12, "걱정/우울": 8}`) | Yes |
| `PRIMARY_EMOTION` | String(50) | 주요 감정 (예: "안정", "기쁨") | Yes |
| `SENTIMENT_OVERALL` | String(20) | 전체 감정 (positive/negative/neutral) | Yes |

### 데이터 흐름

```
TB_ROUTINE_RECOMMENDATIONS (일일 감정 데이터)
    ↓
주간 집계 (aggregate_weekly_emotions)
    ↓
TB_WEEKLY_TARGET_EVENTS (주간 감정 데이터)
```

## 배포 단계

### 1. 코드 업데이트

```bash
cd /path/to/bomproj
git pull origin main  # 또는 해당 브랜치
```

### 2. 데이터베이스 마이그레이션

#### 방법 A: SQLAlchemy 자동 생성 (권장)

```bash
cd backend

# Python 가상환경 활성화
source venv/bin/activate  # Linux/Mac
# 또는
.\venv\Scripts\activate  # Windows

# 데이터베이스 스키마 업데이트
python -c "from app.db.database import Base, engine; Base.metadata.create_all(bind=engine)"
```

#### 방법 B: 수동 SQL 실행

SQLite를 사용하는 경우:

```sql
-- TB_WEEKLY_TARGET_EVENTS 테이블에 컬럼 추가
ALTER TABLE TB_WEEKLY_TARGET_EVENTS ADD COLUMN EMOTION_DISTRIBUTION TEXT;
ALTER TABLE TB_WEEKLY_TARGET_EVENTS ADD COLUMN PRIMARY_EMOTION VARCHAR(50);
ALTER TABLE TB_WEEKLY_TARGET_EVENTS ADD COLUMN SENTIMENT_OVERALL VARCHAR(20);
```

PostgreSQL을 사용하는 경우:

```sql
-- TB_WEEKLY_TARGET_EVENTS 테이블에 컬럼 추가
ALTER TABLE "TB_WEEKLY_TARGET_EVENTS" ADD COLUMN "EMOTION_DISTRIBUTION" JSONB;
ALTER TABLE "TB_WEEKLY_TARGET_EVENTS" ADD COLUMN "PRIMARY_EMOTION" VARCHAR(50);
ALTER TABLE "TB_WEEKLY_TARGET_EVENTS" ADD COLUMN "SENTIMENT_OVERALL" VARCHAR(20);
```

### 3. 기존 데이터 마이그레이션

기존 주간 이벤트에 감정 데이터를 추가합니다:

```bash
cd backend

# Dry run (실제 저장하지 않고 확인만)
python scripts/add_emotion_to_weekly_events.py --dry-run

# 실제 실행
python scripts/add_emotion_to_weekly_events.py

# 특정 사용자만 업데이트
python scripts/add_emotion_to_weekly_events.py --user-id 1
```

### 4. 서버 재시작

#### Docker 환경

```bash
# Docker 컨테이너 재시작
docker-compose restart backend

# 또는 전체 재빌드
docker-compose down
docker-compose up -d --build
```

#### 일반 환경

```bash
# 서비스 재시작 (systemd 사용 시)
sudo systemctl restart bomproj-backend

# 또는 PM2 사용 시
pm2 restart bomproj-backend
```

### 5. 검증

API를 호출하여 감정 데이터가 정상적으로 반환되는지 확인:

```bash
# 주간 이벤트 조회
curl -X GET "http://localhost:8000/api/target-events/weekly" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

응답 예시:

```json
{
  "weekly_events": [
    {
      "id": 1,
      "user_id": 1,
      "week_start": "2024-12-09",
      "week_end": "2024-12-15",
      "target_type": "SELF",
      "events_summary": [...],
      "total_events": 5,
      "tags": ["#나", "#일상"],
      "emotion_distribution": {
        "안정": 35,
        "기쁨": 25,
        "사랑": 20,
        "분노": 12,
        "걱정/우울": 8
      },
      "primary_emotion": "안정",
      "sentiment_overall": "positive",
      "created_at": "2024-12-15T10:00:00Z",
      "updated_at": "2024-12-15T10:00:00Z"
    }
  ],
  "total_count": 1
}
```

## 롤백 방법

문제가 발생한 경우 롤백:

### 1. 코드 롤백

```bash
git checkout <이전_커밋_해시>
```

### 2. 데이터베이스 롤백

```sql
-- 추가된 컬럼 제거
ALTER TABLE TB_WEEKLY_TARGET_EVENTS DROP COLUMN EMOTION_DISTRIBUTION;
ALTER TABLE TB_WEEKLY_TARGET_EVENTS DROP COLUMN PRIMARY_EMOTION;
ALTER TABLE TB_WEEKLY_TARGET_EVENTS DROP COLUMN SENTIMENT_OVERALL;
```

### 3. 서버 재시작

```bash
docker-compose restart backend
```

## 주의사항

1. **백업**: 마이그레이션 전에 반드시 데이터베이스 백업을 수행하세요.
   ```bash
   # SQLite 백업
   cp backend/database.db backend/database.db.backup
   
   # PostgreSQL 백업
   pg_dump -U username dbname > backup.sql
   ```

2. **다운타임**: 마이그레이션 중 짧은 다운타임이 발생할 수 있습니다.

3. **감정 데이터 소스**: `TB_ROUTINE_RECOMMENDATIONS` 테이블에 감정 데이터가 없으면 주간 이벤트에도 감정 데이터가 추가되지 않습니다.

4. **성능**: 대량의 데이터가 있는 경우 마이그레이션 스크립트 실행에 시간이 소요될 수 있습니다.

## 문제 해결

### 문제: 감정 데이터가 null로 표시됨

**원인**: 해당 주간에 `TB_ROUTINE_RECOMMENDATIONS` 데이터가 없음

**해결**:
- 일일 감정 분석이 실행되었는지 확인
- 루틴 추천 데이터가 생성되었는지 확인

### 문제: 마이그레이션 스크립트 실행 오류

**원인**: 데이터베이스 연결 문제 또는 권한 부족

**해결**:
```bash
# 데이터베이스 연결 확인
python -c "from app.db.database import SessionLocal; db = SessionLocal(); print('OK')"

# 권한 확인
ls -la backend/database.db  # SQLite의 경우
```

## 향후 작업

새로운 주간 이벤트는 자동으로 감정 데이터가 포함됩니다:

```bash
# 주간 요약 생성 시 자동으로 감정 데이터 포함
python backend/scripts/generate_weekly_summaries.py --days 7
```

## 문의

문제가 발생하면 개발팀에 문의하세요.

