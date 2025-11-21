# 일일 이미지 선택 감정 분석 기능

## 개요

사용자가 하루마다 처음 사용할 때 메인페이지에서 부정/중립/긍정 이미지 3개 중 하나를 선택하고, 선택한 이미지를 기반으로 감정 분석을 트리거하는 기능입니다.

## 주요 기능

1. **일일 체크 상태 확인**: 사용자가 오늘 이미지 선택을 했는지 확인
2. **랜덤 이미지 제공**: 각 감정별로 여러 이미지 중 하루에 랜덤으로 하나씩 선택하여 표시
3. **이미지 선택 처리**: 선택한 이미지 ID를 받아 감정 분석 트리거
4. **감정 분석 연동**: 기존 emotion-analysis 엔진과 연동하여 감정 분석 수행

## 폴더 구조

```
backend/service/daily_mood_check/
├── __init__.py
├── models.py              # Pydantic 모델 정의
├── service.py             # 비즈니스 로직
├── routes.py              # FastAPI 라우터
├── storage.py             # 사용자 일일 체크 상태 저장
├── README.md              # 이 문서
└── images/                # 이미지 파일 저장 폴더
    ├── negative/          # 부정 감정 이미지들
    ├── neutral/           # 중립 감정 이미지들
    └── positive/          # 긍정 감정 이미지들
```

## 이미지 관리

### 이미지 파일 저장 방법

1. 각 감정별 폴더에 이미지 파일을 저장합니다:
   - `images/negative/`: 부정 감정 이미지들 (여러 개 가능)
   - `images/neutral/`: 중립 감정 이미지들 (여러 개 가능)
   - `images/positive/`: 긍정 감정 이미지들 (여러 개 가능)

2. 지원하는 이미지 형식:
   - `.jpg`, `.jpeg`
   - `.png`
   - `.gif`
   - `.webp`

3. 파일명은 자유롭게 지정 가능합니다 (예: `negative_1.jpg`, `mood_sad.png` 등)

### 랜덤 선택 로직

- 날짜 기반 시드를 사용하여 같은 날에는 같은 이미지가 선택됩니다
- 각 감정별 폴더에서 이미지 파일을 자동으로 스캔합니다
- 하루에 각 감정별로 하나씩 랜덤 선택하여 총 3개의 이미지를 제공합니다

## API 엔드포인트

### 1. 일일 체크 상태 확인

```
GET /api/service/daily-mood-check/status/{user_id}
```

**응답 예시:**
```json
{
  "user_id": 1,
  "completed": false,
  "last_check_date": null,
  "selected_image_id": null
}
```

### 2. 오늘의 이미지 목록 조회

```
GET /api/service/daily-mood-check/images
```

**응답 예시:**
```json
{
  "images": [
    {
      "id": 1,
      "sentiment": "negative",
      "filename": "negative_3.jpg",
      "description": "우울하고 힘든 기분이에요",
      "url": "/api/service/daily-mood-check/images/negative/negative_3.jpg"
    },
    {
      "id": 2,
      "sentiment": "neutral",
      "filename": "neutral_1.jpg",
      "description": "그냥 평범한 하루예요",
      "url": "/api/service/daily-mood-check/images/neutral/neutral_1.jpg"
    },
    {
      "id": 3,
      "sentiment": "positive",
      "filename": "positive_2.jpg",
      "description": "기분이 좋고 행복해요",
      "url": "/api/service/daily-mood-check/images/positive/positive_2.jpg"
    }
  ]
}
```

### 3. 이미지 선택 및 감정 분석

```
POST /api/service/daily-mood-check/select
```

**요청 본문:**
```json
{
  "user_id": 1,
  "image_id": 2
}
```

**응답 예시:**
```json
{
  "success": true,
  "selected_image": {
    "id": 2,
    "sentiment": "neutral",
    "filename": "neutral_1.jpg",
    "description": "그냥 평범한 하루예요",
    "url": "/api/service/daily-mood-check/images/neutral/neutral_1.jpg"
  },
  "emotion_result": {
    "text": "그냥 평범한 하루예요",
    "sentiment_overall": "neutral",
    "primary_emotion": {
      "code": "relief",
      "name_ko": "안심",
      "intensity": 1
    },
    ...
  },
  "message": "이미지 선택이 완료되었습니다."
}
```

### 4. 이미지 파일 직접 접근

```
GET /api/service/daily-mood-check/images/{sentiment}/{filename}
```

예: `/api/service/daily-mood-check/images/negative/negative_1.jpg`

## 사용 방법

### 1. 이미지 파일 준비

각 감정별 폴더에 이미지 파일을 저장합니다:

```bash
backend/service/daily_mood_check/images/
├── negative/
│   ├── negative_1.jpg
│   ├── negative_2.jpg
│   └── negative_3.jpg
├── neutral/
│   ├── neutral_1.jpg
│   └── neutral_2.jpg
└── positive/
    ├── positive_1.jpg
    ├── positive_2.jpg
    └── positive_3.jpg
```

### 2. 서버 시작

`backend/main.py`에 라우터가 자동으로 포함되어 있습니다.

### 3. 프론트엔드 연동

1. 앱 시작 시 `/api/service/daily-mood-check/status/{user_id}` 호출하여 오늘 체크 여부 확인
2. 체크하지 않았다면 `/api/service/daily-mood-check/images` 호출하여 이미지 목록 가져오기
3. 사용자가 이미지 선택 시 `/api/service/daily-mood-check/select` 호출
4. 응답으로 받은 `emotion_result`를 활용하여 감정 분석 결과 표시

## 데이터 저장

- 사용자의 일일 체크 상태는 `daily_checks.json` 파일에 저장됩니다
- 파일 위치: `backend/service/daily_mood_check/daily_checks.json`
- 각 사용자별로 마지막 체크 날짜와 선택한 이미지 ID가 저장됩니다

## 감정 분석 연동

- 선택한 이미지의 `description` 텍스트를 기존 emotion-analysis 엔진에 전달합니다
- 감정 분석 결과는 17개 감정 군집 기반으로 반환됩니다
- `sentiment_overall` 필드로 부정/중립/긍정을 확인할 수 있습니다

## 주의사항

1. 이미지 파일이 없는 경우 기본 설명만 반환됩니다
2. 같은 날에는 같은 이미지가 선택됩니다 (날짜 기반 시드 사용)
3. 하루에 한 번만 체크할 수 있습니다
4. 이미지 파일은 자동으로 스캔되므로 파일을 추가하면 자동으로 인식됩니다

## 향후 개선 사항

- 이미지별 개별 설명 설정 기능
- 이미지 메타데이터 설정 파일 지원
- 데이터베이스 연동 옵션
- 이미지 캐싱 최적화

