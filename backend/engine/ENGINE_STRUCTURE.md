# 감정 분석 및 루틴 추천 엔진 구조 (Emotion Analysis & Routine Recommendation Engine Structure)

## 1. 감정 분석 엔진 (`emotion-analysis`)

### **핵심 원리 (Core Principle)**
- **하이브리드 접근 방식**: **LLM (GPT-4o-mini)**의 의미 이해 능력과 **규칙 기반 로직(Rule-based Logic)**을 결합하여 일관된 지표를 산출합니다.
- **이론적 배경**: 쾌(Valence)와 각성(Arousal) 차원에 매핑된 **17개 감정 군집(17-Emotion Cluster)** 모델을 기반으로 합니다.

### **데이터 흐름 (Data Flow)**
1.  **입력 (Input)**: 사용자 텍스트 + (선택 사항) 문맥 텍스트.
2.  **LLM 처리 (LLM Processing)**:
    -   17개 감정 군집을 정의하는 상세한 시스템 프롬프트를 구성합니다.
    -   `raw_distribution` JSON (17개 감정 전체에 대한 점수) 생성을 요청합니다.
3.  **후처리 (Post-Processing, Python)**:
    -   **정규화 (Normalization)**: 감정 점수의 총합이 1.0이 되도록 조정합니다.
    -   **극성 계산 (Polarity Calculation)**: Valence 임계값 또는 점수 집계를 기반으로 긍정/중립/부정을 판별합니다.
    -   **복합 감정 감지 (Mixed Emotion Detection)**: 상충되는 감정(예: 기쁨 + 슬픔)이 특정 임계값 이상으로 공존하는지 식별합니다.
    -   **서비스 신호 생성 (Service Signal Generation)**: 특정 감정 점수(예: 높은 우울/분노)를 기반으로 조치 플래그(`need_empathy`, `risk_level`, `need_health_check`)를 도출합니다.
    -   **추천 생성 (Recommendation Generation)**: 지배적인 감정 그룹을 기반으로 응답 스타일과 루틴 태그를 제안합니다.

### **주요 구성 요소 (Key Components)**
-   `EmotionAnalyzer` (`src/emotion_analyzer.py`): 메인 오케스트레이터(Orchestrator).
-   `config.py`: 모델 설정, 임계값, 감정 군집 정의를 저장합니다.

---

## 2. 루틴 추천 엔진 (`routine_recommend`)

### **핵심 원리 (Core Principle)**
-   **RAG (검색 증강 생성)**: 벡터 데이터베이스(ChromaDB)에서 관련 루틴을 검색하고, LLM을 사용하여 최적의 루틴을 선택 및 개인화합니다.
-   **문맥 인식 (Context-Aware)**: **감정**, **시간대**, **날씨**를 종합적으로 고려합니다.

### **데이터 흐름 (Data Flow)**
1.  **문맥 수집 (Context Gathering)**:
    -   **감정**: 이전 엔진으로부터 `EmotionAnalysisResult`를 수신합니다.
    -   **날씨**: 현재 날씨를 조회합니다 (도시 정보가 제공된 경우).
    -   **시간대**: 기상/취침 로그를 기반으로 사용자의 현재 페이즈(`morning`, `day`, `evening`, `sleep_prep`)를 추론합니다.
2.  **후보 검색 (Candidate Retrieval, RAG)**:
    -   **쿼리 생성**: 감정 상태 + 추천 태그를 자연어 쿼리로 변환합니다 (예: "불안이 섞인 슬픔, 호흡 운동 필요").
    -   **임베딩**: 로컬 모델(`jhgan/ko-sroberta-multitask`)을 사용하여 쿼리를 임베딩합니다.
    -   **검색**: **ChromaDB**에서 상위 K개(기본 20개) 유사 루틴을 쿼리합니다.
3.  **필터링 및 선택 (Filtering & Selection)**:
    -   **날씨 필터**: 비/눈이 올 경우 야외 루틴을 제거합니다.
    -   **LLM 선택**: 후보군을 LLM에 전달하여 최적의 매치를 선택하고, 개인화된 `reason`(추천 사유)과 `ui_message`를 생성합니다.
4.  **최종 정제 (Final Refinement)**:
    -   **시간 제약**: `TIME_*` 루틴을 사용자의 현재 시간대 슬롯에 맞게 필터링합니다.
    -   **다양성 샘플링**: 감정(Emotion), 신체(Body), 시간(Time) 기반 루틴이 골고루 섞이도록 합니다.

### **주요 구성 요소 (Key Components)**
-   `RoutineRecommendFromEmotionEngine` (`engine.py`): 오케스트레이션 및 필터링을 담당하는 메인 로직입니다.
-   `routine_rag.py`: 쿼리 생성, 임베딩, ChromaDB 검색을 처리합니다.
-   `llm_selector.py`: LLM 기반 루틴 선택을 위한 인터페이스입니다.

---

## 최적화 포인트 (관찰 사항)

1.  **지연 시간 (Latency)**:
    -   **감정 분석**: 1회 LLM 호출.
    -   **루틴 추천**: 1회 임베딩 생성 (CPU) + 1회 ChromaDB 쿼리 + 1회 LLM 호출.
    -   **총합**: 순차적 체인 실행 시 2회의 LLM 호출과 1회의 로컬 임베딩이 포함되어 느려질 수 있습니다.

2.  **리소스 사용 (Resource Usage)**:
    -   `routine_rag.py`에서 임베딩을 위한 `SentenceTransformer`가 로드됩니다. 자주 재초기화되거나 CPU에서 실행될 경우 상당한 오버헤드가 발생합니다.
    -   ChromaDB 클라이언트 초기화 또한 적절히 캐싱/지속(persist)되지 않으면 지연을 유발할 수 있습니다.

3.  **의존성 (Dependency)**:
    -   루틴 추천은 생성된 RAG 쿼리 문자열의 *품질*에 크게 의존합니다. 감정 묘사가 모호하면 검색 결과가 좋지 않을 수 있습니다.
