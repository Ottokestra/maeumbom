# 일일 이미지 선택 감정 분석 기능

## 개요

사용자가 하루마다 처음 사용할 때 메인페이지에서 부정/중립/긍정 이미지 3개 중 하나를 선택하고, 선택한 이미지를 기반으로 감정 분석을 트리거하는 기능입니다. 이미지 선택 시 해당 이미지의 설명 텍스트를 기반으로 emotion-analysis 엔진을 통해 상세한 감정 분석을 수행합니다.

## 주요 기능

1. **일일 체크 상태 확인**: 사용자가 오늘 이미지 선택을 했는지 확인
2. **랜덤 이미지 제공**: 각 감정별로 여러 이미지 중 하루에 랜덤으로 하나씩 선택하여 표시 (날짜 기반 시드 사용)
3. **이미지 선택 처리**: 선택한 이미지 ID를 받아 감정 분석 트리거
4. **감정 분석 연동**: 기존 emotion-analysis 엔진과 연동하여 17개 감정 군집 기반 분석 수행
5. **프론트엔드 UI**: React 컴포넌트를 통한 직관적인 이미지 선택 인터페이스

## 아키텍처 및 폴더 구조

### 백엔드 구조

```
backend/service/daily_mood_check/
├── __init__.py
├── models.py              # Pydantic 모델 정의 (ImageInfo, ImageSelectionRequest 등)
├── service.py             # 비즈니스 로직 (이미지 선택, 감정 분석 연동)
├── routes.py              # FastAPI 라우터 (4개 엔드포인트)
├── storage.py             # 사용자 일일 체크 상태 저장 (JSON 파일 기반)
├── daily_checks.json      # 사용자 체크 상태 저장 파일 (자동 생성)
├── README.md              # 이 문서
└── images/                # 이미지 파일 저장 폴더
    ├── negative/          # 부정 감정 이미지들 (6개)
    ├── neutral/            # 중립 감정 이미지들 (6개)
    └── positive/          # 긍정 감정 이미지들 (6개)
```

### 프론트엔드 구조

```
frontend/src/components/
├── DailyMoodCheck.jsx     # 메인 컴포넌트
├── DailyMoodCheck.css    # 스타일시트
└── EmotionResult.jsx      # 감정 분석 결과 표시 컴포넌트 (재사용)
```

## API 엔드포인트

### 1. 일일 체크 상태 확인

```
GET /api/service/daily-mood-check/status/{user_id}
```

**설명**: 사용자가 오늘 이미지 선택을 완료했는지 확인합니다.

**파라미터**:
- `user_id` (path): 사용자 ID (정수)

**응답 예시:**
```json
{
  "user_id": 1,
  "completed": false,
  "last_check_date": null,
  "selected_image_id": null
}
```

**완료된 경우:**
```json
{
  "user_id": 1,
  "completed": true,
  "last_check_date": "2025-01-21T14:30:00",
  "selected_image_id": 2
}
```

### 2. 오늘의 이미지 목록 조회

```
GET /api/service/daily-mood-check/images
```

**설명**: 오늘 날짜 기준으로 각 감정별(부정/중립/긍정) 랜덤 이미지 1개씩 총 3개를 반환합니다. 같은 날에는 항상 같은 이미지가 선택됩니다.

**응답 예시:**
```json
{
  "images": [
    {
      "id": 1,
      "sentiment": "negative",
      "filename": "negative3.png",
      "description": "우울하고 힘든 기분이에요",
      "url": "/api/service/daily-mood-check/images/negative/negative3.png"
    },
    {
      "id": 2,
      "sentiment": "neutral",
      "filename": "neutral1.png",
      "description": "그냥 평범한 하루예요",
      "url": "/api/service/daily-mood-check/images/neutral/neutral1.png"
    },
    {
      "id": 3,
      "sentiment": "positive",
      "filename": "positive2.jpg",
      "description": "기분이 좋고 행복해요",
      "url": "/api/service/daily-mood-check/images/positive/positive2.jpg"
    }
  ]
}
```

**주의사항**:
- 이미지가 없는 경우 `filename`과 `url`이 `null`일 수 있습니다
- 이미지 순서는 매일 랜덤으로 섞입니다

### 3. 이미지 선택 및 감정 분석

```
POST /api/service/daily-mood-check/select
```

**설명**: 사용자가 선택한 이미지를 기반으로 감정 분석을 수행하고, 일일 체크 상태를 저장합니다.

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
    "filename": "neutral1.png",
    "description": "그냥 평범한 하루예요",
    "url": "/api/service/daily-mood-check/images/neutral/neutral1.png"
  },
  "emotion_result": {
    "text": "그냥 평범한 하루예요",
    "sentiment_overall": "neutral",
    "primary_emotion": {
      "code": "relief",
      "name_ko": "안심",
      "intensity": 1
    },
    "emotions": [
      {
        "code": "relief",
        "name_ko": "안심",
        "intensity": 1
      }
    ],
    "explanation": "..."
  },
  "message": "이미지 선택이 완료되었습니다."
}
```

**에러 응답:**

이미 오늘 체크를 완료한 경우:
```json
{
  "detail": "오늘 이미 체크를 완료했습니다."
}
```
HTTP Status: 400

이미지 ID를 찾을 수 없는 경우:
```json
{
  "detail": "이미지 ID 5를 찾을 수 없습니다."
}
```
HTTP Status: 404

### 4. 이미지 파일 직접 접근

```
GET /api/service/daily-mood-check/images/{sentiment}/{filename}
```

**설명**: 이미지 파일을 직접 서빙합니다.

**파라미터**:
- `sentiment` (path): 감정 분류 (`negative`, `neutral`, `positive`)
- `filename` (path): 이미지 파일명

**예시**: 
- `/api/service/daily-mood-check/images/negative/negative1.png`
- `/api/service/daily-mood-check/images/positive/positive2.jpg`

**에러 응답:**

잘못된 감정 분류:
```json
{
  "detail": "Invalid sentiment"
}
```
HTTP Status: 400

이미지 파일을 찾을 수 없는 경우:
```json
{
  "detail": "Image not found"
}
```
HTTP Status: 404

## 프론트엔드 구현

### DailyMoodCheck 컴포넌트

**주요 기능**:
- 앱 시작 시 일일 체크 상태 확인
- 오늘의 이미지 목록 로드 및 표시
- 이미지 선택 시 감정 분석 트리거
- 감정 분석 결과 표시

**상태 관리**:
- `status`: 일일 체크 상태
- `images`: 오늘의 이미지 목록 (3개)
- `selectedImage`: 선택한 이미지 ID
- `emotionResult`: 감정 분석 결과
- `loading`: 로딩 상태
- `error`: 에러 메시지

**이미지 표시**:
- 이미지 높이: 500px
- 그리드 레이아웃: 3열 (모바일에서는 1열)
- 호버 효과 및 선택 상태 표시
- 이미지 로드 실패 시 플레이스홀더 표시

**사용자 인터랙션**:
- 이미지 클릭 시 선택 및 감정 분석 시작
- 이미 오늘 체크를 완료한 경우 선택 비활성화
- 로딩 중에는 추가 선택 방지

### 스타일링

**DailyMoodCheck.css 주요 스타일**:
- `.daily-mood-check`: 최대 너비 1400px, 중앙 정렬
- `.image-grid`: 3열 그리드 레이아웃, 24px 간격
- `.image-card`: 카드 스타일, 호버 효과, 선택 상태 표시
- 반응형 디자인: 모바일에서는 1열 레이아웃

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

4. 이미지 파일은 자동으로 스캔되므로 파일을 추가하면 자동으로 인식됩니다

### 랜덤 선택 로직

**날짜 기반 시드**:
- 같은 날에는 항상 같은 이미지가 선택됩니다
- 날짜가 바뀌면 다른 이미지가 선택됩니다
- 테스트 모드에서는 시간 기반 시드를 사용하여 매번 다른 이미지가 선택됩니다

**선택 과정**:
1. 각 감정별 폴더에서 이미지 파일 목록을 스캔
2. 날짜 기반 시드로 랜덤 선택
3. 각 감정별로 1개씩 선택하여 총 3개 생성
4. 선택된 이미지들의 순서를 랜덤으로 섞음

### 이미지 설명 매핑

각 감정별로 여러 개의 설명 텍스트가 정의되어 있으며, 이미지 선택 시 랜덤으로 하나가 선택됩니다:

**부정 감정 (negative)**:
- "우울하고 힘든 기분이에요"
- "오늘 기분이 좋지 않아요"
- "마음이 무겁고 힘들어요"
- "슬프고 우울한 하루예요"
- "걱정이 많고 불안해요"

**중립 감정 (neutral)**:
- "그냥 평범한 하루예요"
- "특별한 일 없이 지나가는 하루예요"
- "평온하게 하루를 보내고 있어요"
- "오늘은 그냥 그런 하루예요"
- "감정이 중간쯤인 것 같아요"

**긍정 감정 (positive)**:
- "기분이 좋고 행복해요"
- "오늘 하루가 즐거워요"
- "마음이 편안하고 좋아요"
- "행복한 하루를 보내고 있어요"
- "기쁘고 즐거운 기분이에요"

## 데이터 저장

### daily_checks.json 파일 구조

사용자의 일일 체크 상태는 JSON 파일로 저장됩니다:

**파일 위치**: `backend/service/daily_mood_check/daily_checks.json`

**데이터 구조**:
```json
{
  "1": {
    "last_check_date": "2025-01-21T14:30:00",
    "selected_image_id": 2
  },
  "2": {
    "last_check_date": "2025-01-21T10:15:00",
    "selected_image_id": 3
  }
}
```

**필드 설명**:
- 키: 사용자 ID (문자열)
- `last_check_date`: 마지막 체크 날짜 및 시간 (ISO 형식)
- `selected_image_id`: 선택한 이미지 ID

### 테스트 모드

**환경변수**: `DAILY_MOOD_CHECK_TEST_MODE`

**설정 방법**:
- 테스트 모드 활성화 (기본값): `DAILY_MOOD_CHECK_TEST_MODE=true` 또는 환경변수 미설정
- 테스트 모드 비활성화: `DAILY_MOOD_CHECK_TEST_MODE=false`

**테스트 모드 동작**:
- 일일 체크 제한 없음 (하루에 여러 번 체크 가능)
- 시간 기반 시드 사용 (매번 다른 이미지 선택)
- 개발 및 테스트 시 유용

**실서비스 배포 시**:
- 환경변수를 `false`로 설정하여 일일 체크 제한 활성화

## 감정 분석 연동

### 연동 방법

1. **이미지 선택 시**: 사용자가 이미지를 선택하면 해당 이미지의 `description` 텍스트가 emotion-analysis 엔진에 전달됩니다.

2. **엔진 호출**: `service.py`의 `analyze_emotion_from_image()` 함수가 `rag_pipeline.py`의 `get_rag_pipeline()`을 통해 엔진 인스턴스를 가져옵니다.

3. **분석 수행**: `pipeline.analyze_emotion(description)` 메서드를 호출하여 감정 분석을 수행합니다.

4. **결과 반환**: 분석 결과가 API 응답에 포함되어 프론트엔드로 전달됩니다.

### 감정 분석 결과 구조

```json
{
  "text": "그냥 평범한 하루예요",
  "sentiment_overall": "neutral",
  "primary_emotion": {
    "code": "relief",
    "name_ko": "안심",
    "intensity": 1
  },
  "emotions": [
    {
      "code": "relief",
      "name_ko": "안심",
      "intensity": 1
    }
  ],
  "explanation": "이 텍스트는 중립적인 감정을 나타냅니다..."
}
```

**필드 설명**:
- `text`: 분석한 텍스트
- `sentiment_overall`: 전체 감정 분류 (`negative`, `neutral`, `positive`)
- `primary_emotion`: 주요 감정 (17개 감정 군집 중 하나)
- `emotions`: 감지된 모든 감정 목록
- `explanation`: 감정 분석 설명

**17개 감정 군집**:
emotion-analysis 엔진의 17개 감정 군집을 기반으로 분석됩니다. 각 감정은 `code`, `name_ko`, `intensity` 필드를 가집니다.

## 사용 방법 및 예제

### 1. 이미지 파일 준비

각 감정별 폴더에 이미지 파일을 저장합니다:

```bash
backend/service/daily_mood_check/images/
├── negative/
│   ├── negative1.png
│   ├── negative2.png
│   ├── negative3.png
│   ├── negative4.png
│   ├── negative5.png
│   └── negative6.png
├── neutral/
│   ├── neutral1.png
│   ├── neutral2.png
│   ├── neutral3.png
│   ├── neutral4.png
│   ├── neutral5.png
│   └── neutral6.png
└── positive/
    ├── positive1.jpg
    ├── positive2.jpg
    ├── positive3.png
    ├── positive4.png
    ├── positive5.jpg
    └── positive6.jpg
```

### 2. 서버 시작

`backend/main.py`에 라우터가 자동으로 포함되어 있습니다:

```python
from backend.service.daily_mood_check.routes import router as daily_mood_check_router

app.include_router(daily_mood_check_router, prefix="/api/service/daily-mood-check", tags=["daily-mood-check"])
```

서버 실행:
```bash
cd backend
python main.py
```

### 3. 프론트엔드 연동

**기본 흐름**:

1. **앱 시작 시 상태 확인**:
```javascript
const response = await fetch('http://localhost:8000/api/service/daily-mood-check/status/1')
const status = await response.json()
// status.completed가 false이면 이미지 선택 필요
```

2. **이미지 목록 로드**:
```javascript
const response = await fetch('http://localhost:8000/api/service/daily-mood-check/images')
const data = await response.json()
// data.images에 3개의 이미지 정보가 포함됨
```

3. **이미지 선택 및 감정 분석**:
```javascript
const response = await fetch('http://localhost:8000/api/service/daily-mood-check/select', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: 1,
    image_id: 2
  })
})
const result = await response.json()
// result.emotion_result에 감정 분석 결과가 포함됨
```

4. **감정 분석 결과 표시**:
```javascript
// EmotionResult 컴포넌트에 result.emotion_result 전달
<EmotionResult result={result.emotion_result} />
```

### 4. 프론트엔드 컴포넌트 사용

**App.jsx에서 사용**:
```jsx
import DailyMoodCheck from './components/DailyMoodCheck'

function App() {
  return (
    <div>
      <DailyMoodCheck />
    </div>
  )
}
```

## 주의사항

1. **이미지 파일**: 이미지 파일이 없는 경우 기본 설명만 반환되며, `filename`과 `url`이 `null`입니다.

2. **날짜 기반 선택**: 같은 날에는 항상 같은 이미지가 선택됩니다. 날짜가 바뀌면 다른 이미지가 선택됩니다.

3. **일일 체크 제한**: 테스트 모드가 아닌 경우 하루에 한 번만 체크할 수 있습니다. 이미 체크한 경우 400 에러가 반환됩니다.

4. **자동 스캔**: 이미지 파일은 자동으로 스캔되므로 파일을 추가하면 자동으로 인식됩니다. 서버 재시작 없이도 새 이미지가 반영됩니다.

5. **이미지 순서**: 이미지 목록의 순서는 매일 랜덤으로 섞입니다. 같은 날에도 페이지를 새로고침하면 순서가 바뀔 수 있습니다.

6. **감정 분석 엔진**: emotion-analysis 엔진이 사용 불가능한 경우 `emotion_result`가 `null`로 반환됩니다.

7. **CORS 설정**: 프론트엔드와 백엔드가 다른 포트에서 실행되는 경우 CORS 설정이 필요합니다.

## 향후 개선 사항

1. **이미지별 개별 설명 설정**: 각 이미지 파일에 대한 개별 설명을 설정 파일로 관리
2. **이미지 메타데이터 설정 파일 지원**: JSON/YAML 파일로 이미지별 메타데이터 관리
3. **데이터베이스 연동 옵션**: JSON 파일 대신 데이터베이스 사용 옵션 제공
4. **이미지 캐싱 최적화**: 이미지 파일 캐싱 및 CDN 연동
5. **이미지 업로드 기능**: 관리자 페이지를 통한 이미지 업로드 기능
6. **통계 및 분석**: 사용자별 감정 선택 통계 및 분석 기능
7. **이미지 추천**: 과거 선택 이력을 기반으로 이미지 추천 기능
8. **다국어 지원**: 이미지 설명 및 UI 다국어 지원
