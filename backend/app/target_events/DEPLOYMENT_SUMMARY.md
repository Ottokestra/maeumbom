# 주간 이벤트 감정 데이터 통합 - 배포 요약

## 변경 사항 요약

### 1. 데이터베이스 스키마 변경
- **테이블**: `TB_WEEKLY_TARGET_EVENTS`
- **추가된 컬럼**:
  - `EMOTION_DISTRIBUTION` (JSON): 감정 비율 분포
  - `PRIMARY_EMOTION` (String): 주요 감정
  - `SENTIMENT_OVERALL` (String): 전체 감정

### 2. 수정된 파일
- `backend/app/db/models.py`: WeeklyTargetEvent 모델에 감정 컬럼 추가
- `backend/app/target_events/service.py`: 
  - `aggregate_weekly_emotions()` 함수 추가 (감정 집계 로직)
  - `analyze_weekly_events()` 함수 수정 (감정 데이터 통합)
- `backend/app/target_events/schemas.py`: WeeklyEventResponse에 감정 필드 추가
- `backend/app/target_events/README.md`: 문서 업데이트

### 3. 새로 추가된 파일
- `backend/scripts/add_emotion_to_weekly_events.py`: 기존 데이터 마이그레이션 스크립트
- `backend/MIGRATION_GUIDE_EMOTION.md`: 상세 마이그레이션 가이드
- `backend/DEPLOYMENT_SUMMARY.md`: 이 파일

## 팀원분께 전달 사항

### 빠른 배포 가이드

```bash
# 1. 코드 업데이트
cd /path/to/bomproj
git pull

# 2. Docker 환경 재시작 (스키마 자동 생성)
docker-compose down
docker-compose up -d --build

# 3. 기존 데이터에 감정 추가 (선택사항)
docker-compose exec backend python scripts/add_emotion_to_weekly_events.py

# 4. 확인
curl -X GET "http://localhost:8000/api/target-events/weekly" -H "Authorization: Bearer YOUR_TOKEN"
```

### 주요 특징

1. **자동 감정 집계**: 주간 이벤트 생성 시 자동으로 `TB_ROUTINE_RECOMMENDATIONS`에서 감정 데이터를 가져와 집계
2. **비율 계산**: 7일간의 감정 데이터를 합산하여 백분율로 변환
3. **상위 5개 감정**: 가장 높은 비율의 5개 감정만 표시 (나머지는 "기타"로 통합)
4. **한글 매핑**: 감정 코드(joy, calm 등)를 한글 이름(기쁨, 안정 등)으로 자동 변환

### API 응답 예시

```json
{
  "emotion_distribution": {
    "안정": 35,
    "기쁨": 25,
    "사랑": 20,
    "분노": 12,
    "걱정/우울": 8
  },
  "primary_emotion": "안정",
  "sentiment_overall": "positive"
}
```

### 데이터 흐름

```
일일 대화 분석
    ↓
TB_ROUTINE_RECOMMENDATIONS (EMOTION_SUMMARY)
    ↓
주간 집계 (aggregate_weekly_emotions)
    ↓
TB_WEEKLY_TARGET_EVENTS (EMOTION_DISTRIBUTION)
    ↓
프론트엔드 차트
```

## 주의사항

1. **NULL 값**: 감정 데이터가 없는 주간 이벤트는 감정 필드가 `null`입니다.
2. **하위 호환성**: 기존 API는 그대로 작동하며, 감정 필드는 추가로 제공됩니다.
3. **성능**: 감정 집계는 주간 이벤트 생성 시 한 번만 수행되므로 성능 영향 최소화.

## 롤백 방법

문제 발생 시:

```bash
# 1. 이전 버전으로 롤백
git checkout <이전_커밋>

# 2. Docker 재시작
docker-compose down
docker-compose up -d --build

# 3. 컬럼 제거 (필요시)
docker-compose exec db psql -U username -d dbname -c "
ALTER TABLE TB_WEEKLY_TARGET_EVENTS DROP COLUMN EMOTION_DISTRIBUTION;
ALTER TABLE TB_WEEKLY_TARGET_EVENTS DROP COLUMN PRIMARY_EMOTION;
ALTER TABLE TB_WEEKLY_TARGET_EVENTS DROP COLUMN SENTIMENT_OVERALL;
"
```

## 상세 문서

더 자세한 내용은 `backend/MIGRATION_GUIDE_EMOTION.md`를 참조하세요.

## 테스트 완료 항목

- ✅ 데이터베이스 모델 변경
- ✅ 감정 집계 로직 구현
- ✅ 주간 이벤트 생성 시 감정 데이터 통합
- ✅ API 스키마 업데이트
- ✅ 린트 오류 없음
- ✅ 마이그레이션 스크립트 작성
- ✅ 배포 가이드 작성

## 다음 단계

1. 팀원분께 이 파일과 `MIGRATION_GUIDE_EMOTION.md` 전달
2. 도커 서버에서 배포 실행
3. API 테스트로 감정 데이터 확인
4. 프론트엔드에서 차트 구현

---

작성일: 2024-12-15
작성자: AI Assistant

