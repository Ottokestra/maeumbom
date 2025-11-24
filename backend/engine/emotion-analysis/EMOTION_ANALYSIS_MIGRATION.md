# 감정 분석 시스템 마이그레이션 가이드

## 개요

이 문서는 감정 분석 시스템이 논문 기반 **Valence/Arousal (VA) 차원 + 감정 군집** 체계를 거쳐, 최종적으로 **17개 감정 군집 기반 시스템**으로 전환된 이유와 변경 사항을 설명합니다.

## 변경 이유

### 1. 이론적 근거

기존 시스템은 10개의 고정된 감정 카테고리(joy, sadness, anger 등)를 사용했지만, 이는 다음과 같은 한계가 있었습니다:

- **감정의 연속적 특성 무시**: 감정은 이산적인 카테고리가 아닌 연속적인 차원으로 표현되어야 합니다.
- **심리학적 타당성 부족**: 임의로 정의된 감정 카테고리는 과학적 근거가 부족합니다.
- **세밀한 감정 표현 불가**: "기쁨 60%, 평온 30%" 같은 표현은 감정의 강도와 방향을 정확히 전달하지 못합니다.

### 2. 논문 기반 접근

**참고 논문**: LLM 기반 한국어 정서 벡터 연구

이 논문은 다음과 같은 이론적 프레임워크를 제시합니다:

- **Russell & Mehrabian (1977)의 차원적 감정 이론** 기반
- **Valence (정서가)**: 쾌-불쾌 차원 (-1.0 ~ +1.0)
- **Arousal (각성가)**: 활성-비활성 차원 (-1.0 ~ +1.0)
- **감정 군집**: 위계적 군집 분석을 통한 의미론적 감정 범주

### 3. 개선 효과

새로운 시스템은 다음과 같은 장점을 제공합니다:

1. **과학적 타당성**: 심리학 연구에서 검증된 차원적 감정 모델 사용
2. **정밀한 표현**: 연속적인 VA 값으로 감정의 세밀한 변화 추적 가능
3. **확장성**: 새로운 감정을 추가하지 않고도 다양한 감정 상태 표현 가능
4. **해석 가능성**: VA 공간에서 감정의 위치를 시각적으로 이해 가능

## 변경 사항

### API 응답 형식 변경

#### 이전 형식 (Deprecated)

```json
{
  "input": "요즘 너무 피곤해요",
  "emotions": {
    "fatigue": 75,
    "sadness": 15,
    "frustration": 10
  },
  "primary_emotion": "fatigue",
  "primary_percentage": 75
}
```

#### 최종 형식 (17개 감정 군집 기반)

```json
{
  "text": "사용자 입력 원문",
  "language": "ko",
  
  "raw_distribution": [
    { "code": "joy", "name_ko": "기쁨", "group": "positive", "score": 0.05 },
    { "code": "excitement", "name_ko": "흥분", "group": "positive", "score": 0.03 },
    { "code": "sadness", "name_ko": "슬픔", "group": "negative", "score": 0.22 },
    { "code": "depression", "name_ko": "우울", "group": "negative", "score": 0.18 }
    // ... score가 0보다 큰 감정만 포함 (17개 중 일부)
  ],
  
  "primary_emotion": {
    "code": "sadness",
    "name_ko": "슬픔",
    "group": "negative",
    "intensity": 4,
    "confidence": 0.82
  },
  
  "secondary_emotions": [
    { "code": "depression", "name_ko": "우울", "intensity": 3 },
    { "code": "discontent", "name_ko": "불만", "intensity": 2 }
  ],
  
  "sentiment_overall": "negative",
  
  "service_signals": {
    "need_empathy": true,
    "need_routine_recommend": true,
    "need_health_check": false,
    "need_voice_analysis": false,
    "risk_level": "watch"
  },
  
  "recommended_response_style": [
    "부드럽고 공감 중심의 답변",
    "비난 없이 감정을 받아주는 방식",
    "천천히 말 걸기"
  ],
  
  "recommended_routine_tags": [
    "light_walk", "breathing", "journaling"
  ],
  
  "report_tags": [
    "슬픔 증가", "우울 경향", "정서적 피로"
  ]
}
```

**주요 특징**:
- `raw_distribution`: LLM이 생성한 원본 raw 값 (정규화 전), score가 0인 항목은 자동으로 필터링됨
- `primary_emotion`: 주요 감정 (code, name_ko, group, intensity 1~5, confidence 0~1)
- `secondary_emotions`: 보조 감정들 (최대 3개, score 5% 이상)
- `sentiment_overall`: 전체 감정 극성 ("positive" / "neutral" / "negative")
- `service_signals`: 다른 엔진 호출 여부 및 위험도 판단
- `recommended_response_style`: 추천 답변 스타일
- `recommended_routine_tags`: 추천 루틴 태그
- `report_tags`: 리포트 태그

**참고**: 이전 VA + 군집 체계의 `cluster_id`, `cluster_label`, `related_clusters`는 백엔드 내부 계산에만 사용되며 API 응답에는 포함되지 않습니다.

### 필드 설명 (17개 감정 군집 기반 시스템)

#### 기본 필드

- **`text`** (string): 사용자 입력 원문
- **`language`** (string): 언어 코드 (기본값: "ko")

#### raw_distribution 필드

- **`raw_distribution`** (array): 17개 감정의 원본 raw 값 배열
  - 각 항목: `{ "code": "joy", "name_ko": "기쁨", "group": "positive", "score": 0.05 }`
  - `code`: 감정 코드 (17개 중 하나)
  - `name_ko`: 한국어 감정 이름
  - `group`: "positive" 또는 "negative"
  - `score`: 원본 raw 값 (정규화 전, 0 이상)
  - **주의**: score가 0인 항목은 자동으로 필터링되어 포함되지 않음

#### 주요 감정 필드

- **`primary_emotion`** (object): 주요 감정
  - `code`: 감정 코드
  - `name_ko`: 한국어 감정 이름
  - `group`: "positive" 또는 "negative"
  - `intensity`: 감정 강도 (1~5)
    - 1: 매우 약함
    - 2: 약함
    - 3: 중간
    - 4: 강함
    - 5: 매우 강함
  - `confidence`: 신뢰도 (0~1)
    - primary_score의 절대값, 점수 차이, 비율 차이를 모두 고려하여 계산
    - primary_score가 높거나 차이가 클수록 높은 신뢰도

- **`secondary_emotions`** (array): 보조 감정들 (최대 3개)
  - 각 항목: `{ "code": "depression", "name_ko": "우울", "intensity": 3 }`
  - score가 5% 이상인 감정만 포함
  - primary_emotion 제외

#### 감정 극성 필드

- **`sentiment_overall`** (string): 전체 감정 극성
  - `"positive"`: 긍정 감정이 우세
  - `"neutral"`: 중립
  - `"negative"`: 부정 감정이 우세
  - 긍정/부정 감정의 score 합계 차이로 계산

#### 서비스 신호 필드

- **`service_signals`** (object): 다른 엔진 호출 여부 및 위험도 판단
  - `need_empathy` (boolean): 봄이 답변 스타일 필요 여부
  - `need_routine_recommend` (boolean): 루틴 분석 엔진 호출 여부
  - `need_health_check` (boolean): 건강 엔진 호출 여부
  - `need_voice_analysis` (boolean): 음성 파동 분석 참고 여부
  - `risk_level` (string): 위험도 레벨
    - `"normal"`: 정상
    - `"watch"`: 주의 관찰
    - `"alert"`: 경고
    - `"critical"`: 위급

#### 추천 필드

- **`recommended_response_style`** (array): 추천 답변 스타일
  - 예: `["부드럽고 공감 중심의 답변", "비난 없이 감정을 받아주는 방식"]`

- **`recommended_routine_tags`** (array): 추천 루틴 태그
  - 예: `["light_walk", "breathing", "journaling"]`

- **`report_tags`** (array): 리포트 태그
  - 예: `["슬픔 증가", "우울 경향", "정서적 피로"]`

#### 이전 필드 (VA + 군집 체계, 참고용)

- **`valence`** (float, -1.0 ~ +1.0): 정서가 (이전 시스템)
- **`arousal`** (float, -1.0 ~ +1.0): 각성가 (이전 시스템)
- **`mood_direction`** (string): 기분 방향 (이전 시스템)
- **`emotion_intensity`** (string): 감정 강도 (이전 시스템)

#### 내부용 필드 (API 응답에 포함되지 않음)

- `cluster_id`: 백엔드 내부 계산용 감정 군집 ID (VA + 군집 체계)
- `cluster_label`: 백엔드 내부 계산용 감정 군집 라벨 (VA + 군집 체계)
- `related_clusters`: 백엔드 내부 계산용 관련 군집 목록 (VA + 군집 체계)

## UI-friendly 라벨 변환 규칙

백엔드에서는 VA 값을 UI 친화적인 라벨로 자동 변환합니다.

### mood_direction 변환 규칙

| Valence 범위 | mood_direction |
|-------------|----------------|
| valence > 0.2 | "긍정" |
| -0.2 ≤ valence ≤ 0.2 | "중립" |
| valence < -0.2 | "부정" |

### emotion_intensity 변환 규칙

| Arousal 절대값 범위 | emotion_intensity |
|-------------------|-------------------|
| \|arousal\| ≥ 0.6 | "높음" |
| 0.3 ≤ \|arousal\| < 0.6 | "보통" |
| \|arousal\| < 0.3 | "낮음" |

**참고**: arousal은 절대값으로 계산되므로, 양수/음수와 관계없이 강도만 측정합니다.

## 17개 감정 군집 정의 (현재 시스템)

현재 시스템은 갱년기 여성 대상 감정 분석을 위해 17개의 감정 군집을 사용합니다.

### 긍정 그룹 (positive)

| 코드 | 한국어 이름 | 설명 |
|---|---|---|
| joy | 기쁨 | 즐거움과 행복 |
| excitement | 흥분 | 활기와 흥미진진함 |
| confidence | 자신감 | 확신과 자신 |
| love | 사랑 | 애정과 사랑 |
| relief | 안심 | 안도와 편안함 |
| enlightenment | 깨달음 | 깨우침과 이해 |
| interest | 흥미 | 관심과 호기심 |

### 부정 그룹 (negative)

| 코드 | 한국어 이름 | 설명 |
|---|---|---|
| discontent | 불만 | 답답함과 불만 |
| shame | 수치 | 부끄러움과 수치심 |
| sadness | 슬픔 | 슬픔과 비애 |
| guilt | 죄책감 | 죄책감과 후회 |
| depression | 우울 | 우울과 절망 |
| boredom | 무료 | 지루함과 무료함 |
| contempt | 경멸 | 경멸과 멸시 |
| anger | 화 | 분노와 화 |
| fear | 공포 | 두려움과 공포 |
| confusion | 혼란 | 혼란과 당황 |

### 감정 분석 프로세스

1. **LLM 호출**: OpenAI GPT-4o mini가 사용자 입력을 분석하여 17개 감정에 대한 `raw_distribution` 생성
2. **필드 검증**: 각 감정 객체의 필드(code, name_ko, group, score) 검증 및 보완
3. **필터링**: score가 0인 항목 자동 제거
4. **정규화**: 내부 계산용으로 score 정규화 (합 = 1.0)
5. **주요 감정 계산**: primary_emotion, secondary_emotions 계산
6. **서비스 신호 생성**: sentiment_overall, service_signals, 추천 태그 생성

## 이전 감정 군집 정의 (VA + 군집 체계, 참고용)

### 긍정 군집

| ID | 라벨 | Valence | Arousal | 설명 |
|---|---|---|---|---|
| 1 | 안심/평온 | +0.6 | -0.4 | 편안하고 안정적인 상태 |
| 2 | 흥미/관심 | +0.7 | +0.5 | 즐거움과 활기 |
| 3 | 애틋/그리움 | +0.3 | +0.2 | 긍정적인 그리움 |

### 부정 군집

| ID | 라벨 | Valence | Arousal | 설명 |
|---|---|---|---|---|
| 4 | 불만 | -0.5 | +0.3 | 답답하고 불만스러운 상태 |
| 5 | 수치 | -0.6 | +0.4 | 부끄러움과 죄책감 |
| 6 | 슬픔/비애 | -0.7 | -0.3 | 우울하고 슬픈 상태 |
| 7 | 분노 | -0.8 | +0.8 | 화가 나고 격앙된 상태 |
| 8 | 불안/공포 | -0.6 | +0.7 | 걱정되고 두려운 상태 |
| 9 | 피로/무기력 | -0.4 | -0.6 | 지치고 무기력한 상태 |
| 10 | 혼란 | -0.3 | +0.5 | 당황하고 혼란스러운 상태 |

**참고**: 이전 VA + 군집 체계는 현재 시스템의 내부 계산에만 사용되며, API 응답에는 17개 감정 군집 기반 형식이 반환됩니다.

## 마이그레이션 가이드

### 프론트엔드 개발자

#### 1. 새로운 필드 사용

```javascript
// 권장: VA 값 + UI-friendly 라벨 사용
const { 
  valence,           // -1.0 ~ +1.0
  arousal,          // -1.0 ~ +1.0
  mood_direction,   // "긍정" | "중립" | "부정"
  emotion_intensity // "높음" | "보통" | "낮음"
} = result

// UI 라벨로 색상 결정
const color = {
  '긍정': '#4CAF50',
  '중립': '#9E9E9E',
  '부정': '#F44336'
}[mood_direction]

// 감정 강도로 스타일 조정
const intensityStyle = {
  '높음': { fontWeight: 'bold', fontSize: '1.2em' },
  '보통': { fontWeight: 'normal', fontSize: '1em' },
  '낮음': { fontWeight: 'lighter', fontSize: '0.9em' }
}[emotion_intensity]
```

#### 2. 하위 호환성

기존 코드는 계속 작동하지만, 새로운 필드를 우선 사용하세요:

```javascript
// 하위 호환성: 기존 코드도 작동
const primaryEmotion = result.primary_emotion
const percentage = result.percentage
const topEmotions = result.top_emotions || result.emotions  // top_emotions 우선

// 권장: 새로운 VA + UI 라벨 형식 사용
const moodDirection = result.mood_direction
const emotionIntensity = result.emotion_intensity
const valence = result.valence
const arousal = result.arousal
```

### 백엔드 개발자

#### 1. API 응답 처리

새로운 필드는 항상 포함되므로, 기존 코드는 수정 없이 작동합니다:

```python
# 기존 코드 (여전히 작동)
primary_emotion = result['primary_emotion']
percentage = result['percentage']
top_emotions = result.get('top_emotions', result.get('emotions', {}))

# 권장: 새로운 VA + UI 라벨 형식 사용
valence = result['valence']
arousal = result['arousal']
mood_direction = result['mood_direction']      # "긍정" | "중립" | "부정"
emotion_intensity = result['emotion_intensity']  # "높음" | "보통" | "낮음"
```

#### 2. 데이터베이스 스키마

기존 데이터베이스에 VA 값을 저장하려면:

```sql
ALTER TABLE emotion_analysis_results 
ADD COLUMN valence FLOAT,
ADD COLUMN arousal FLOAT,
ADD COLUMN mood_direction VARCHAR(10),
ADD COLUMN emotion_intensity VARCHAR(10);
```

## 예시

### 예시 1: 긍정적 감정

**입력**: "오늘 정말 기분이 좋아요!"

**응답**:
```json
{
  "input": "오늘 정말 기분이 좋아요!",
  "valence": 0.8,
  "arousal": 0.4,
  "mood_direction": "긍정",
  "emotion_intensity": "보통",
  "primary_emotion": "joy",
  "percentage": 85,
  "top_emotions": {
    "joy": 85,
    "calmness": 10,
    "loneliness": 5
  }
}
```

**해석**: 
- 높은 정서가(+0.8)와 중간 각성가(+0.4)로 긍정적이고 활기찬 감정
- UI 라벨: "긍정" (mood_direction), "보통" (emotion_intensity)
- 주요 감정: 기쁨 (85%)

### 예시 2: 부정적 감정

**입력**: "요즘 너무 피곤하고 아무것도 하기 싫어요"

**응답**:
```json
{
  "input": "요즘 너무 피곤하고 아무것도 하기 싫어요",
  "valence": -0.7,
  "arousal": -0.5,
  "mood_direction": "부정",
  "emotion_intensity": "보통",
  "primary_emotion": "fatigue",
  "percentage": 75,
  "top_emotions": {
    "fatigue": 75,
    "sadness": 15,
    "frustration": 10
  }
}
```

**해석**:
- 낮은 정서가(-0.7)와 낮은 각성가(-0.5)로 부정적이고 무기력한 감정
- UI 라벨: "부정" (mood_direction), "보통" (emotion_intensity)
- 주요 감정: 피로 (75%)

### 예시 3: 복합 감정 (높은 각성)

**입력**: "가족들에게 화를 내고 나면 미안해요"

**응답**:
```json
{
  "input": "가족들에게 화를 내고 나면 미안해요",
  "valence": -0.5,
  "arousal": 0.6,
  "mood_direction": "부정",
  "emotion_intensity": "높음",
  "primary_emotion": "anger",
  "percentage": 60,
  "top_emotions": {
    "anger": 60,
    "guilt": 30,
    "frustration": 10
  }
}
```

**해석**:
- 부정적 정서가(-0.5)와 높은 각성가(+0.6)로 분노에 가까운 감정
- UI 라벨: "부정" (mood_direction), "높음" (emotion_intensity)
- 주요 감정: 분노 (60%), 죄책감 (30%) - 복합 감정 상태 표현

## FAQ

### Q1: 기존 API가 작동하지 않나요?

**A**: 아니요. 기존 API는 완전히 하위 호환됩니다. `emotions`, `primary_emotion`, `primary_percentage` 필드는 계속 제공됩니다.

### Q2: 언제까지 기존 형식을 사용할 수 있나요?

**A**: 현재로서는 제한이 없습니다. 하지만 새로운 VA + 군집 형식 사용을 권장합니다.

### Q3: VA 값을 어떻게 해석하나요?

**A**: 
- **Valence**: 감정의 쾌/불쾌 정도
- **Arousal**: 감정의 활성/비활성 정도
- 두 값을 함께 보면 감정의 정확한 위치를 파악할 수 있습니다.

### Q4: UI 라벨은 어떻게 결정되나요?

**A**: 
- `mood_direction`: valence 값에 따라 자동 결정
  - valence > 0.2 → "긍정"
  - -0.2 ≤ valence ≤ 0.2 → "중립"
  - valence < -0.2 → "부정"
  
- `emotion_intensity`: arousal 절대값에 따라 자동 결정
  - |arousal| ≥ 0.6 → "높음"
  - 0.3 ≤ |arousal| < 0.6 → "보통"
  - |arousal| < 0.3 → "낮음"

### Q5: cluster_id와 cluster_label은 어디에 있나요?

**A**: `cluster_id`와 `cluster_label`은 백엔드 내부 계산에만 사용되며 API 응답에는 포함되지 않습니다. 프론트엔드에서는 `mood_direction`과 `emotion_intensity`를 사용하세요.

### Q6: raw_distribution에 모든 17개 감정이 포함되나요?

**A**: 아니요. `raw_distribution`에는 score가 0보다 큰 감정만 포함됩니다. LLM이 생성한 원본 raw 값에서 score가 0인 항목은 자동으로 필터링됩니다.

### Q7: confidence는 어떻게 계산되나요?

**A**: `confidence`는 다음 요소들을 종합하여 계산됩니다:
- primary_score의 절대값 (높을수록 보너스)
- primary_score와 secondary_score의 차이 (차이가 클수록 높음)
- primary_score / secondary_score 비율 (비율이 클수록 높음)
- 동적 최소값 (primary_score가 높을수록 최소값도 증가)

예를 들어, primary_score=0.25, secondary_score=0.15인 경우:
- 이전: confidence ≈ 0.55 (55%)
- 개선 후: confidence ≈ 0.78 (78%)

### Q8: secondary_emotions는 몇 개까지 포함되나요?

**A**: 최대 3개까지 포함됩니다. 단, score가 5% 이상인 감정만 포함되며, primary_emotion은 제외됩니다.

### Q9: service_signals의 risk_level은 어떻게 결정되나요?

**A**: `risk_level`은 다음과 같이 결정됩니다:
- `"critical"`: 우울 점수 > 0.5 또는 (우울 > 0.3 AND 슬픔 > 0.3)
- `"alert"`: 전체 부정 감정 합계 > 0.6 또는 우울 > 0.3
- `"watch"`: 전체 부정 감정 합계 > 0.4 또는 sentiment_overall == "negative"
- `"normal"`: 그 외

## 참고 자료

- Russell, J. A., & Mehrabian, A. (1977). Evidence for a three-factor theory of emotions. *Journal of Research in Personality*, 11(3), 273-294.
- 한국어 감정 구조 논문 (LLM 기반 한국어 정서 벡터 연구)

## 변경 이력

- **2024-XX-XX**: 논문 기반 VA + 군집 체계로 전환
  - `emotion_analyzer.py` 전면 개편
  - `config.py`에 감정 군집 정의 추가
  - API 스키마 업데이트
  - 프론트엔드 VA 시각화 추가

- **2024-XX-XX**: UI-friendly 라벨 변환 시스템 추가
  - `utils.py`에 `convert_va_to_ui_labels()` 함수 추가
  - `rag_pipeline.py`에서 cluster 정보 제거 및 UI 라벨 추가
  - `emotions` → `top_emotions`로 필드명 변경
  - `primary_percentage` → `percentage`로 필드명 변경
  - 프론트엔드에서 `mood_direction`, `emotion_intensity` 표시

- **2024-XX-XX**: 17개 감정 군집 기반 시스템으로 전환
  - `config.py`에 17개 감정 군집 정의 추가 (EMOTION_CLUSTERS_17)
  - `emotion_analyzer.py`에 `analyze_emotion()` 메서드 추가 (17개 감정 군집 기반)
  - LLM은 `raw_distribution`만 생성하고, 나머지는 백엔드에서 계산
  - 새로운 API 응답 형식:
    - `raw_distribution`: 17개 감정의 원본 raw 값 (score 0인 항목 자동 필터링)
    - `primary_emotion`: 주요 감정 (code, name_ko, group, intensity 1~5, confidence 0~1)
    - `secondary_emotions`: 보조 감정들 (최대 3개)
    - `sentiment_overall`: 전체 감정 극성
    - `service_signals`: 다른 엔진 호출 여부 및 위험도 판단
    - `recommended_response_style`: 추천 답변 스타일
    - `recommended_routine_tags`: 추천 루틴 태그
    - `report_tags`: 리포트 태그
  - `_parse_raw_distribution()` 메서드 개선:
    - 각 감정 객체의 필드 검증 및 보완 (code, name_ko, group, score)
    - 잘못된 형식의 객체 제거
    - 중복 감정 코드 처리
  - `_calculate_confidence()` 메서드 개선:
    - primary_score의 절대값 반영
    - 점수 차이와 비율 차이 모두 고려
    - 동적 최소값 설정 (primary_score가 높을수록 최소값 증가)
  - score가 0인 항목 자동 필터링
  - `rag_pipeline.py`에서 `similar_contexts` 필드 제거 (최종 응답에 포함하지 않음)

