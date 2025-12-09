# Emotion Analysis 종합 가이드

## 목차

1. [개요](#개요)
2. [프로젝트 소개](#프로젝트-소개)
3. [이론적 배경 및 논문 검증](#이론적-배경-및-논문-검증)
4. [시스템 아키텍처](#시스템-아키텍처)
   - [중립 감정 처리](#중립-감정-처리)
5. [API 사용법](#api-사용법)
6. [마이그레이션 가이드](#마이그레이션-가이드)
7. [트러블슈팅](#트러블슈팅)
8. [벡터 스토어 관리](#벡터-스토어-관리)
9. [향후 개선 사항](#향후-개선-사항)
10. [참고 자료](#참고-자료)

---

## 개요

본 문서는 emotion-analysis 기능에 대한 종합 가이드입니다. 프로젝트 소개부터 이론적 배경, 사용법, 트러블슈팅까지 모든 내용을 포함합니다.

**대상 독자**:
- 개발자 (백엔드/프론트엔드)
- 프로젝트 관리자
- 연구자 및 검증 담당자

**작성 목적**: PPT 발표 및 블로그 포스팅을 위한 종합 문서

---

## 프로젝트 소개

### 프로젝트 개요

갱년기 여성을 위한 감정 공감 AI 서비스의 핵심 기능인 감정 분석 시스템입니다. RAG (Retrieval-Augmented Generation) 기술을 활용하여 사용자의 감정을 분석하고 공감합니다.

### 주요 기능

- **17개 감정 군집 기반 분석**: 논문 기반의 과학적 감정 분류 체계
- **RAG 기반 정확도 향상**: 유사 컨텍스트 검색을 통한 분석 정확도 개선
- **혼합 감정 감지**: 긍정과 부정이 섞인 복합 감정 정확히 분석
- **서비스 신호 생성**: 루틴 추천, 위험도 판단 등 후속 서비스 연동

### 기술 스택

**백엔드:**
- Python 3.11
- FastAPI (REST API)
- ChromaDB (벡터 데이터베이스)
- Sentence Transformers (한국어 임베딩)
- OpenAI GPT-4o-mini (감정 분석 LLM)

**프론트엔드:**
- React 18
- Vite
- Axios

### 프로젝트 구조

```
backend/engine/emotion-analysis/
├── api/
│   ├── models.py              # Pydantic 모델 정의
│   └── routes.py              # API 엔드포인트
├── src/
│   ├── config.py              # 설정 (17개 감정 정의)
│   ├── data_loader.py         # 데이터 로딩
│   ├── embeddings.py          # 임베딩 생성
│   ├── vectorstore.py         # 벡터 DB 관리
│   ├── emotion_analyzer.py    # 감정 분석 로직
│   └── rag_pipeline.py        # RAG 파이프라인
├── data/
│   └── raw/
│       └── sample_emotions.json  # 샘플 감정 데이터 (491개)
├── vectordb/                  # ChromaDB 로컬 저장소
├── README.md                  # 프로젝트 개요
├── PAPER_VERIFICATION.md      # 논문 검증 결과
├── TROUBLESHOOTING.md         # 트러블슈팅 내역
├── EMOTION_ANALYSIS_MIGRATION.md  # 마이그레이션 가이드
└── COMPREHENSIVE_GUIDE.md    # 본 문서 (종합 가이드)
```

---

## 이론적 배경 및 논문 검증

### 참고 논문

**논문 정보**:
- 저자: 이준호
- 소속: 서울대학교 대학원 협동과정 인지과학전공
- 제출일: 2025년 1월
- 지도교수: 김청택
- 제목: 감정의 형태: 정서 어휘집과 사전 학습 언어 모델을 이용한 감정의 분포와 구조 분석

**이론적 기반**: Russell & Mehrabian (1977)의 감정 3요인이론
- **Valence (정서가)**: -1.0 (불쾌) ~ +1.0 (쾌)
- **Arousal (각성가)**: -1.0 (저각성/안정) ~ +1.0 (고각성/흥분)
- **Dominance (지배가)**: 일관되게 관찰되지 않아 논문에서는 Valence와 Arousal만 사용

### 17개 감정 범주

논문에서는 **368개 정서어휘의 유사도행렬과 위계적 군집화 결과**를 통해 **17개의 범주로 구성된 감정분류체계**를 구축했습니다.

#### 긍정 감정 (7개)
1. **기쁨** (joy)
2. **흥분** (excitement)
3. **자신감** (confidence)
4. **사랑** (love)
5. **안심** (relief)
6. **깨달음** (enlightenment)
7. **흥미** (interest)

#### 부정 감정 (10개)
1. **불만** (discontent)
2. **수치** (shame)
3. **슬픔** (sadness)
4. **죄책감** (guilt)
5. **우울** (depression)
6. **무료** (boredom)
7. **경멸** (contempt)
8. **화** (anger)
9. **공포** (fear)
10. **혼란** (confusion)

### 논문 기준 검증 결과

**검증 항목**:
- ✅ 17개 감정 목록 일치 여부
- ✅ 이론적 기반 (Russell & Mehrabian) 적용 여부
- ✅ 긍정/부정 구분 일치 여부
- ✅ Top1/Top3 구조 일치 여부

**검증 결과**: ✅ **완벽히 일치**
- 논문의 17개 감정이 모두 정확히 구현되어 있음
- 긍정 7개, 부정 10개로 구성이 동일함
- 각 감정의 한국어 이름도 논문과 일치
- Russell & Mehrabian (1977) 이론을 명시적으로 참조

**상세 검증 내용**: `PAPER_VERIFICATION.md` 참고

---

## 시스템 아키텍처

### RAG 파이프라인

1. **입력 텍스트 수신**: 사용자의 감정 표현 (최대 500-700자)
2. **임베딩 생성**: `jhgan/ko-sroberta-multitask`로 벡터 변환
3. **유사 컨텍스트 검색**: ChromaDB에서 top-5 유사 표현 검색
4. **프롬프트 생성**: 입력 + 검색된 컨텍스트 + 예시 결합
5. **LLM 추론**: `gpt-4o-mini` API로 감정 분석
6. **결과 파싱**: JSON 파싱 → 17개 감정 분포 추출
7. **후처리**: Primary/Secondary 감정 계산, 혼합 감정 감지, 서비스 신호 생성
8. **결과 반환**: 완전한 감정 분석 결과 반환

### 감정 분석 프로세스

1. **LLM 호출**: OpenAI GPT-4o mini가 사용자 입력을 분석하여 17개 감정에 대한 `raw_distribution` 생성
2. **필드 검증**: 각 감정 객체의 필드(code, name_ko, group, score) 검증 및 보완
3. **필터링**: score가 0인 항목 자동 제거
4. **정규화**: 내부 계산용으로 score 정규화 (합 = 1.0)
5. **주요 감정 계산**: primary_emotion, secondary_emotions 계산
6. **혼합 감정 감지**: 하이브리드 방식(그룹 기반 + 점수 기반)으로 혼합 감정 감지
7. **서비스 신호 생성**: sentiment_overall, service_signals, 추천 태그 생성

### 중립 감정 처리

시스템은 감정이 없는 문장(예: "오늘 회의 3시입니다", "물 온도는 25도입니다")을 자동으로 감지하여 중립(neutral)으로 분류합니다.

#### 처리 방식

**1. LLM 프롬프트 지시**
- 감정이 전혀 없는 문장의 경우, 모든 감정의 score를 매우 낮게 설정 (각 감정당 0.01~0.05)
- 17개 score의 총합이 0.1 이하가 되도록 하여 서버에서 "감정 없음(중립)"으로 판단 가능하게 함

**2. 서버 측 판단 로직**
```python
def _calculate_sentiment_overall(self, raw_distribution, normalized_distribution):
    # 1. 감정 없음 판단 (중립 = 감정 없는 문장)
    total_raw_score = sum(item.get("score", 0) for item in raw_distribution)
    max_raw_score = max((item.get("score", 0) for item in raw_distribution), default=0)
    
    # 총합이 임계값(0.1) 이하이거나, 최대 점수가 0.1 이하이면 감정 없음으로 판단
    if total_raw_score <= EMOTION_ABSENCE_THRESHOLD or max_raw_score <= 0.1:
        return "neutral"
    
    # 2. 감정 있음 판단: 정규화된 값으로 긍정/부정 중 더 큰 쪽으로 분류
    # ...
```

**3. 판단 기준**
- **EMOTION_ABSENCE_THRESHOLD**: 0.1 (설정값)
- 모든 감정 점수의 총합이 0.1 이하이거나
- 최대 감정 점수가 0.1 이하이면 → `sentiment_overall = "neutral"`

**4. 서비스 신호 처리**
중립 감정의 경우에도 적절한 서비스 신호를 생성합니다:
- `need_empathy`: 중립이면 `true` (감정이 없는 경우에도 공감 필요)
- `need_routine_recommend`: 중립이면 `true` (긍정이 아닌 경우 루틴 추천)
- `risk_level`: "normal" (중립은 위험도 낮음)

#### 예시

**입력**: "오늘 회의 3시입니다"

**응답**:
```json
{
  "text": "오늘 회의 3시입니다",
  "raw_distribution": [
    { "code": "joy", "name_ko": "기쁨", "group": "positive", "score": 0.02 },
    { "code": "interest", "name_ko": "흥미", "group": "positive", "score": 0.01 },
    // ... 모든 감정이 0.01~0.05 범위
  ],
  "primary_emotion": {
    "code": "interest",
    "name_ko": "흥미",
    "group": "positive",
    "intensity": 1,
    "confidence": 0.5
  },
  "sentiment_overall": "neutral",
  "service_signals": {
    "need_empathy": true,
    "need_routine_recommend": true,
    "need_health_check": false,
    "need_voice_analysis": false,
    "risk_level": "normal"
  }
}
```

**설명**:
- 모든 감정 점수가 매우 낮음 (0.01~0.05)
- 총합이 0.1 이하이므로 `sentiment_overall = "neutral"`
- Primary emotion은 있지만 intensity가 1 (매우 약함)로 표시됨
- 서비스 신호는 중립 감정에 맞게 설정됨

### 사용 모델

| 역할 | 모델 | 용도 | 특징 |
|------|------|------|------|
| **임베딩** | `jhgan/ko-sroberta-multitask` | 텍스트 벡터화 | 한국어 특화, 768차원 |
| **LLM 분석** | `gpt-4o-mini` (OpenAI API) | 감정 분석 | 빠른 응답 속도 (0.5-2초), 한국어 지원 우수 |
| **벡터 DB** | ChromaDB | 유사 컨텍스트 검색 | 로컬 저장, 도커 불필요 |

### 모델 변경 이력

#### 1차: 키워드 기반 → LLM 기반 (2024.11.14)
- **변경 전**: `beomi/KcELECTRA-base` (분류 모델), 키워드 매칭 기반
- **변경 후**: `beomi/gemma-ko-2b` (생성 LLM), LLM 기반 감정 분석
- **개선점**: 문맥 이해, 진짜 RAG 구현

#### 2차: 로컬 LLM → OpenAI GPT-4o mini (2024.11.14)
- **변경 전**: `beomi/gemma-ko-2b` (로컬 Hugging Face 모델), 3-5초/요청
- **변경 후**: `gpt-4o-mini` (OpenAI API), 0.5-2초/요청
- **개선점**: 응답 속도 대폭 개선 (2-10배 빠름), 메모리 사용량 감소

### 출력 형식 변경 이력

#### 1차: 1-5점 → 상위 3개 퍼센트 (2024.11.14)
- **변경 전**: 10가지 감정 모두 1-5점
- **변경 후**: 상위 3개 감정만 퍼센트 (합계 100%)
- **개선점**: 주요 감정에 집중, 직관적인 비율 표시
- **참고**: 모델은 변경되지 않았으며, API 응답 형식만 변경됨

---

## API 사용법

### 설치 및 실행

#### 1. 백엔드 설정

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Mac/Linux
pip install -r requirements.txt
```

#### 2. 환경 변수 설정

`.env` 파일 생성:
```
OPENAI_API_KEY=your_openai_api_key_here
```

#### 3. 벡터 DB 초기화

```bash
# 서버 실행
python -m api.main

# 벡터 DB 초기화
curl -X POST http://localhost:8000/api/init
```

#### 4. 프론트엔드 설정

```bash
cd frontend
npm install
npm run dev
```

### API 엔드포인트

#### POST /api/analyze

텍스트 감정 분석

**Request:**
```json
{
  "text": "요즘 너무 피곤하고 아무것도 하기 싫어요"
}
```

**Response:**
```json
{
  "text": "요즘 너무 피곤하고 아무것도 하기 싫어요",
  "language": "ko",
  
  "raw_distribution": [
    { "code": "depression", "name_ko": "우울", "group": "negative", "score": 0.18 },
    { "code": "sadness", "name_ko": "슬픔", "group": "negative", "score": 0.22 }
  ],
  
  "primary_emotion": {
    "code": "sadness",
    "name_ko": "슬픔",
    "group": "negative",
    "intensity": 4,
    "confidence": 0.82
  },
  
  "secondary_emotions": [
    { "code": "depression", "name_ko": "우울", "group": "negative", "intensity": 3 },
    { "code": "discontent", "name_ko": "불만", "group": "negative", "intensity": 2 }
  ],
  
  "sentiment_overall": "negative",
  
  "mixed_emotion": {
    "is_mixed": false,
    "dominant_group": "negative",
    "positive_ratio": 0.0,
    "negative_ratio": 1.0,
    "mixed_ratio": 0.0
  },
  
  "service_signals": {
    "need_empathy": true,
    "need_routine_recommend": true,
    "need_health_check": false,
    "need_voice_analysis": false,
    "risk_level": "watch"
  },
  
  "recommended_response_style": [
    "부드럽고 공감 중심의 답변",
    "비난 없이 감정을 받아주는 방식"
  ],
  
  "recommended_routine_tags": [
    "light_walk", "breathing", "journaling"
  ],
  
  "report_tags": [
    "슬픔 증가", "우울 경향", "정서적 피로"
  ]
}
```

#### GET /api/health

서버 상태 확인

**Response:**
```json
{
  "status": "ok",
  "vector_store_count": 491,
  "ready": true
}
```

#### POST /api/init

벡터 DB 초기화 (최초 1회 실행)

**Response:**
```json
{
  "status": "success",
  "message": "Vector store initialized with 491 documents",
  "document_count": 491
}
```

### API 응답 필드 설명

#### 기본 필드
- **`text`** (string): 사용자 입력 원문
- **`language`** (string): 언어 코드 (기본값: "ko")

#### raw_distribution 필드
- **`raw_distribution`** (array): 17개 감정의 원본 raw 값 배열
  - 각 항목: `{ "code": "joy", "name_ko": "기쁨", "group": "positive", "score": 0.05 }`
  - score가 0인 항목은 자동으로 필터링되어 포함되지 않음

#### 주요 감정 필드
- **`primary_emotion`** (object): 주요 감정
  - `code`: 감정 코드
  - `name_ko`: 한국어 감정 이름
  - `group`: "positive" 또는 "negative"
  - `intensity`: 감정 강도 (1~5)
  - `confidence`: 신뢰도 (0~1)

- **`secondary_emotions`** (array): 보조 감정들 (최대 3개)
  - score가 5% 이상인 감정만 포함
  - primary_emotion 제외

#### 감정 극성 필드
- **`sentiment_overall`** (string): 전체 감정 극성
  - `"positive"`: 긍정 감정이 우세
  - `"neutral"`: 중립 (감정이 없는 문장, 예: "오늘 회의 3시입니다")
  - `"negative"`: 부정 감정이 우세
  
  **중립 판단 기준**:
  - 모든 감정 점수의 총합이 0.1 이하이거나
  - 최대 감정 점수가 0.1 이하이면 → `"neutral"`

#### 혼합 감정 필드
- **`mixed_emotion`** (object, Optional): 혼합 감정 정보
  - `is_mixed` (bool): 혼합 감정 여부
  - `dominant_group` (string): 주된 그룹 ("positive" | "negative")
  - `positive_ratio` (float): 긍정 비율
  - `negative_ratio` (float): 부정 비율
  - `mixed_ratio` (float): 혼합 비율

#### 서비스 신호 필드
- **`service_signals`** (object): 다른 엔진 호출 여부 및 위험도 판단
  - `need_empathy` (boolean): 봄이 답변 스타일 필요 여부
  - `need_routine_recommend` (boolean): 루틴 분석 엔진 호출 여부
  - `need_health_check` (boolean): 건강 엔진 호출 여부
  - `need_voice_analysis` (boolean): 음성 파동 분석 참고 여부
  - `risk_level` (string): 위험도 레벨 ("normal" | "watch" | "alert" | "critical")

#### 추천 필드
- **`recommended_response_style`** (array): 추천 답변 스타일
- **`recommended_routine_tags`** (array): 추천 루틴 태그
- **`report_tags`** (array): 리포트 태그

---

## 마이그레이션 가이드

### 변경 이력

#### 1단계: 논문 기반 VA + 군집 체계로 전환
- `emotion_analyzer.py` 전면 개편
- `config.py`에 감정 군집 정의 추가
- API 스키마 업데이트

#### 2단계: UI-friendly 라벨 변환 시스템 추가
- `utils.py`에 `convert_va_to_ui_labels()` 함수 추가
- `mood_direction`, `emotion_intensity` 필드 추가

#### 3단계: 17개 감정 군집 기반 시스템으로 전환 (최종)
- `config.py`에 17개 감정 군집 정의 추가 (EMOTION_CLUSTERS_17)
- `emotion_analyzer.py`에 `analyze_emotion()` 메서드 추가
- LLM은 `raw_distribution`만 생성하고, 나머지는 백엔드에서 계산
- 새로운 API 응답 형식 적용

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
  "text": "요즘 너무 피곤해요",
  "raw_distribution": [...],
  "primary_emotion": {
    "code": "depression",
    "name_ko": "우울",
    "group": "negative",
    "intensity": 4,
    "confidence": 0.82
  },
  "secondary_emotions": [...],
  "sentiment_overall": "negative",
  "mixed_emotion": {...},
  "service_signals": {...}
}
```

### 하위 호환성

기존 API는 완전히 하위 호환됩니다. `emotions`, `primary_emotion`, `primary_percentage` 필드는 계속 제공되지만, 새로운 필드 사용을 권장합니다.

---

## 트러블슈팅

### 주요 트러블슈팅 이슈

#### 1. OpenAI API JSON Mode 지원 문제

**문제 상황**:
- OpenAI API 호출 시 `response_format={"type": "json_object"}` 사용 시 오류 발생
- 일부 모델이나 API 버전에서 JSON mode가 지원되지 않음

**해결 방법**:
```python
try:
    response = self.client.chat.completions.create(
        model=self.model_name,
        messages=[...],
        response_format={"type": "json_object"}
    )
except Exception as e:
    if "response_format" in str(e).lower():
        # JSON mode 미지원 시 fallback: response_format 없이 재시도
        response = self.client.chat.completions.create(
            model=self.model_name,
            messages=[...],
            # response_format 제거
        )
```

**결과**: ✅ JSON mode가 지원되지 않는 경우에도 정상 작동, 하위 호환성 확보

#### 2. 벡터 스토어 초기화 문제

**문제 상황**:
- `sample_emotions.json`을 17개 감정으로 변경한 후 벡터 스토어가 업데이트되지 않음
- 기존 데이터가 남아있어 새로운 감정 분류가 반영되지 않음

**해결 방법**:
- **방법 1**: Python 스크립트 실행 (`python reinit_vectorstore.py`)
- **방법 2**: API 엔드포인트 호출 (`POST /api/init`)
- **방법 3**: 자동 초기화 안전장치 추가 (벡터 스토어가 비어있으면 자동 초기화)

**결과**: ✅ 데이터 변경 시 명확한 재초기화 프로세스 확립, 자동화된 안전장치 구현

#### 3. 혼합 감정 처리 미구현 문제

**문제 상황**:
- "좋긴 한데 좀 불안해" 같은 혼합 감정 문장을 제대로 분석하지 못함
- 긍정과 부정이 섞인 감정을 단일 감정으로만 분류

**해결 방법**:
하이브리드 방식(그룹 기반 + 점수 기반)으로 혼합 감정 자동 감지 구현

```python
def _detect_mixed_emotion_hybrid(
    self,
    primary_emotion: Dict[str, Any],
    secondary_emotions: List[Dict[str, Any]],
    normalized_distribution: List[Dict[str, Any]],
    group_threshold: float = 0.15
) -> Dict[str, Any]:
    # 1. 그룹 기반 감지: Primary와 Secondary의 그룹이 다른지 확인
    # 2. 점수 기반 감지: 긍정/부정 점수가 모두 임계값(0.15) 이상인지 확인
    # 3. 하이브리드 판단: 두 조건 중 하나라도 만족하면 혼합 감정
    # 4. 혼합 비율 계산
```

**결과**: ✅ 혼합 감정 정확히 감지 가능, 하위 호환성 유지 (Optional 필드)

**테스트 결과**:
- 입력: "좋긴 한데 좀 불안해"
- 결과: `is_mixed: true`, Primary: "공포" (negative), Secondary: "기쁨" (positive)
- 혼합 비율: 긍정 42.9%, 부정 57.1%

#### 4. 감정 분포 데이터 불일치 문제

**문제 상황**:
- `sample_emotions.json`의 감정 코드가 17개 감정 체계와 일치하지 않음
- 벡터 스토어에 잘못된 감정 코드로 저장됨

**해결 방법**:
1. 데이터 변환 스크립트 작성 (`convert_emotions.py`)
2. 벡터 스토어 재초기화
3. 검증 프로세스 수립 (벡터 스토어 문서 수 확인, 17개 감정 분포 확인)

**결과**: ✅ 데이터 일관성 확보, RAG 검색 정확도 향상

### 성능 최적화

#### Lazy Initialization 적용
- Emotion Analyzer가 매번 새로 생성되지 않도록 캐싱
- 초기화 시간 단축, 메모리 사용량 최적화

#### 벡터 스토어 자동 초기화 안전장치
- 벡터 스토어가 비어있을 때 자동으로 초기화 시도
- 사용자 경험 개선, 에러 방지

**상세 내용**: `TROUBLESHOOTING.md` 참고

---

## 벡터 스토어 관리

### 벡터 스토어 재초기화

`sample_emotions.json`을 17개 감정으로 변경한 후, 벡터 스토어를 재초기화해야 RAG 모델이 새로운 데이터를 사용할 수 있습니다.

#### 방법 1: Python 스크립트 실행 (권장)

```bash
cd backend/engine/emotion-analysis
python reinit_vectorstore.py
```

스크립트가 자동으로:
1. 현재 벡터 스토어 상태 확인
2. 기존 데이터 삭제
3. 새로운 17개 감정 데이터로 재초기화
4. 결과 출력

#### 방법 2: API 엔드포인트 호출

```bash
curl -X POST http://localhost:8000/api/init
```

#### 방법 3: 브라우저에서

1. 서버 실행: `http://localhost:8000/docs`
2. `/api/init` POST 엔드포인트 찾기
3. "Try it out" 클릭
4. "Execute" 클릭

### 재초기화 확인

재초기화 후 다음을 확인하세요:

1. **벡터 스토어 문서 수**: 491개 (sample_emotions.json의 항목 수)
2. **감정 분포**: 17개 감정이 모두 포함되어야 함
   - 긍정: joy, excitement, confidence, love, relief, enlightenment, interest
   - 부정: discontent, shame, sadness, guilt, depression, boredom, contempt, anger, fear, confusion

### 주의사항

- 재초기화하면 기존 벡터 스토어의 모든 데이터가 삭제되고 새로 생성됩니다
- 재초기화는 몇 초에서 수십 초가 걸릴 수 있습니다 (데이터 양에 따라)
- 재초기화 중에는 API 요청이 느려질 수 있습니다

### 문제 해결

#### 벡터 스토어가 비어있음
- `sample_emotions.json` 파일 경로 확인
- `data_loader.py`가 올바른 감정 코드를 사용하는지 확인

#### 감정 분포가 이상함
- `sample_emotions.json`의 `emotion` 필드가 17개 감정 코드인지 확인
- `convert_emotions.py` 스크립트로 변환이 제대로 되었는지 확인

**상세 내용**: `src/REINIT_VECTORSTORE.md` 참고

---

## 향후 개선 사항

### 우선순위 높음

#### 1. VA 좌표값 추가

**현재 상태**: 논문의 Valence/Arousal 좌표값 미구현

**개선 방안**:
- 논문에서 각 감정의 VA 좌표값 확보
- `EMOTION_CLUSTERS_17`에 `valence`, `arousal` 필드 추가
- 루틴 추천 정확도 향상에 활용

**장점**:
- 감정의 차원적 특성 활용
- 루틴 추천 정확도 향상
- 감정 변화 추적 가능
- 시각화 개선

**우선순위**: 중간

### 우선순위 낮음

#### 2. 감정 간 유사도 행렬 활용

**현재 상태**: 감정 간 유사도 정보 미활용

**개선 방안**:
- 논문의 감정 간 유사도 행렬 데이터 확보
- 유사 감정 기반 루틴 확장
- 감정 전이 예측 기능

**장점**:
- 감정 간 관계 이해
- 대체 감정 추천
- 감정 전이 예측
- 루틴 추천 다양성 향상

**우선순위**: 낮음 (고급 기능)

### 개선사항 우선순위 및 진행 상황

1. ✅ **완료**: 혼합 감정 처리 - 2025년 1월 구현 완료
2. **중간**: VA 좌표값 추가 - 논문 데이터 확보 후 구현
3. **낮음**: 감정 간 유사도 행렬 - 논문 데이터 확보 필요, 고급 기능으로 선택적 구현

**상세 내용**: `PAPER_VERIFICATION.md`의 "4. 개선이 필요한 부분" 참고

---

## 참고 자료

### 논문 및 이론

- **논문**: 이준호(2025). 감정의 형태: 정서 어휘집과 사전 학습 언어 모델을 이용한 감정의 분포와 구조 분석. 서울대학교 박사학위논문.
- **이론**: Russell, J. A., & Mehrabian, A. (1977). Evidence for a three-factor theory of emotions. Journal of Research in Personality, 11(3), 273-294.

### 관련 문서

- `README.md`: 프로젝트 개요 및 사용법
- `PAPER_VERIFICATION.md`: 논문 기준 검증 결과 상세
- `TROUBLESHOOTING.md`: 트러블슈팅 내역 상세
- `EMOTION_ANALYSIS_MIGRATION.md`: 마이그레이션 가이드 상세
- `src/REINIT_VECTORSTORE.md`: 벡터 스토어 재초기화 가이드

### 코드 위치

- **설정**: `backend/engine/emotion-analysis/src/config.py`
- **감정 분석 로직**: `backend/engine/emotion-analysis/src/emotion_analyzer.py`
- **RAG 파이프라인**: `backend/engine/emotion-analysis/src/rag_pipeline.py`
- **API 모델**: `backend/engine/emotion-analysis/api/models.py`
- **API 라우터**: `backend/engine/emotion-analysis/api/routes.py`

---

## 부록

### A. 17개 감정 상세 설명

#### 긍정 그룹 (positive)

| 코드 | 한국어 이름 | 설명 |
|---|---|---|
| joy | 기쁨 | 즐거움과 행복 |
| excitement | 흥분 | 활기와 흥미진진함 |
| confidence | 자신감 | 확신과 자신 |
| love | 사랑 | 애정과 사랑 |
| relief | 안심 | 안도와 편안함 |
| enlightenment | 깨달음 | 깨우침과 이해 |
| interest | 흥미 | 관심과 호기심 |

#### 부정 그룹 (negative)

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

### B. API 응답 예시

#### 예시 1: 긍정적 감정

**입력**: "오늘 정말 기분이 좋아요!"

**응답**:
```json
{
  "text": "오늘 정말 기분이 좋아요!",
  "primary_emotion": {
    "code": "joy",
    "name_ko": "기쁨",
    "group": "positive",
    "intensity": 5,
    "confidence": 0.92
  },
  "secondary_emotions": [
    { "code": "excitement", "name_ko": "흥분", "group": "positive", "intensity": 3 }
  ],
  "sentiment_overall": "positive",
  "mixed_emotion": {
    "is_mixed": false,
    "dominant_group": "positive",
    "positive_ratio": 0.905,
    "negative_ratio": 0.095,
    "mixed_ratio": 0.095
  }
}
```

#### 예시 2: 부정적 감정

**입력**: "요즘 너무 피곤하고 아무것도 하기 싫어요"

**응답**:
```json
{
  "text": "요즘 너무 피곤하고 아무것도 하기 싫어요",
  "primary_emotion": {
    "code": "depression",
    "name_ko": "우울",
    "group": "negative",
    "intensity": 4,
    "confidence": 0.78
  },
  "secondary_emotions": [
    { "code": "sadness", "name_ko": "슬픔", "group": "negative", "intensity": 3 },
    { "code": "discontent", "name_ko": "불만", "group": "negative", "intensity": 2 }
  ],
  "sentiment_overall": "negative",
  "service_signals": {
    "need_routine_recommend": true,
    "risk_level": "watch"
  }
}
```

#### 예시 3: 혼합 감정

**입력**: "좋긴 한데 좀 불안해"

**응답**:
```json
{
  "text": "좋긴 한데 좀 불안해",
  "primary_emotion": {
    "code": "fear",
    "name_ko": "공포",
    "group": "negative",
    "intensity": 2,
    "confidence": 0.71
  },
  "secondary_emotions": [
    { "code": "joy", "name_ko": "기쁨", "group": "positive", "intensity": 2 }
  ],
  "sentiment_overall": "negative",
  "mixed_emotion": {
    "is_mixed": true,
    "dominant_group": "negative",
    "positive_ratio": 0.429,
    "negative_ratio": 0.571,
    "mixed_ratio": 0.429
  }
}
```

#### 예시 4: 중립 감정 (감정 없는 문장)

**입력**: "오늘 회의 3시입니다"

**응답**:
```json
{
  "text": "오늘 회의 3시입니다",
  "raw_distribution": [
    { "code": "joy", "name_ko": "기쁨", "group": "positive", "score": 0.02 },
    { "code": "interest", "name_ko": "흥미", "group": "positive", "score": 0.01 },
    { "code": "boredom", "name_ko": "무료", "group": "negative", "score": 0.01 }
  ],
  "primary_emotion": {
    "code": "interest",
    "name_ko": "흥미",
    "group": "positive",
    "intensity": 1,
    "confidence": 0.5
  },
  "secondary_emotions": [],
  "sentiment_overall": "neutral",
  "mixed_emotion": {
    "is_mixed": false,
    "dominant_group": "positive",
    "positive_ratio": 0.75,
    "negative_ratio": 0.25,
    "mixed_ratio": 0.25
  },
  "service_signals": {
    "need_empathy": true,
    "need_routine_recommend": true,
    "need_health_check": false,
    "need_voice_analysis": false,
    "risk_level": "normal"
  }
}
```

**설명**:
- 모든 감정 점수가 매우 낮음 (0.01~0.02)
- 총합이 0.1 이하이므로 `sentiment_overall = "neutral"`
- Primary emotion은 있지만 intensity가 1 (매우 약함)
- 서비스 신호는 중립 감정에 맞게 설정됨 (`need_empathy: true`, `need_routine_recommend: true`)

### C. FAQ

#### Q1: 기존 API가 작동하지 않나요?

**A**: 아니요. 기존 API는 완전히 하위 호환됩니다. `emotions`, `primary_emotion`, `primary_percentage` 필드는 계속 제공됩니다.

#### Q2: 언제까지 기존 형식을 사용할 수 있나요?

**A**: 현재로서는 제한이 없습니다. 하지만 새로운 17개 감정 군집 기반 형식 사용을 권장합니다.

#### Q3: confidence는 어떻게 계산되나요?

**A**: `confidence`는 다음 요소들을 종합하여 계산됩니다:
- primary_score의 절대값 (높을수록 보너스)
- primary_score와 secondary_score의 차이 (차이가 클수록 높음)
- primary_score / secondary_score 비율 (비율이 클수록 높음)
- 동적 최소값 (primary_score가 높을수록 최소값도 증가)

#### Q4: secondary_emotions는 몇 개까지 포함되나요?

**A**: 최대 3개까지 포함됩니다. 단, score가 5% 이상인 감정만 포함되며, primary_emotion은 제외됩니다.

#### Q5: service_signals의 risk_level은 어떻게 결정되나요?

**A**: `risk_level`은 다음과 같이 결정됩니다:
- `"critical"`: 우울 점수 > 0.5 또는 (우울 > 0.3 AND 슬픔 > 0.3)
- `"alert"`: 전체 부정 감정 합계 > 0.6 또는 우울 > 0.3
- `"watch"`: 전체 부정 감정 합계 > 0.4 또는 sentiment_overall == "negative"
- `"normal"`: 그 외

#### Q6: raw_distribution에 모든 17개 감정이 포함되나요?

**A**: 아니요. `raw_distribution`에는 score가 0보다 큰 감정만 포함됩니다. LLM이 생성한 원본 raw 값에서 score가 0인 항목은 자동으로 필터링됩니다.

---

**작성일**: 2025년 1월  
**작성 목적**: PPT 발표 및 블로그 포스팅을 위한 종합 가이드  
**문서 버전**: 1.0

