# Emotion Analysis 트러블슈팅 내역

## 개요

본 문서는 emotion-analysis 기능 개발 및 운영 중 발생한 주요 이슈와 해결 과정을 정리한 문서입니다.

**작성 목적**: PPT 발표 및 블로그 포스팅을 위한 트러블슈팅 내역 정리

---

## 1. 주요 트러블슈팅 이슈

### 1-1. OpenAI API JSON Mode 지원 문제

**문제 상황**:
- OpenAI API 호출 시 `response_format={"type": "json_object"}` 사용 시 오류 발생
- 일부 모델이나 API 버전에서 JSON mode가 지원되지 않음

**에러 메시지**:
```
response_format is not supported for this model
```

**해결 방법**:
```python
# emotion_analyzer.py의 analyze_emotion() 메서드
try:
    response = self.client.chat.completions.create(
        model=self.model_name,
        messages=[...],
        response_format={"type": "json_object"}  # JSON mode 시도
    )
except Exception as e:
    if "response_format" in str(e).lower():
        # JSON mode 미지원 시 fallback: response_format 없이 재시도
        print("JSON mode not supported, retrying without response_format...")
        response = self.client.chat.completions.create(
            model=self.model_name,
            messages=[...],
            # response_format 제거
        )
```

**결과**:
- ✅ JSON mode가 지원되지 않는 경우에도 정상 작동
- ✅ 하위 호환성 확보
- ✅ 에러 발생 시 자동으로 fallback 처리

**교훈**:
- 외부 API 사용 시 버전/모델별 차이를 고려한 fallback 로직 필수
- 에러 핸들링을 통해 서비스 안정성 향상

---

### 1-2. 벡터 스토어 초기화 문제

**문제 상황**:
- `sample_emotions.json`을 17개 감정으로 변경한 후 벡터 스토어가 업데이트되지 않음
- 기존 데이터가 남아있어 새로운 감정 분류가 반영되지 않음

**원인**:
- 벡터 스토어는 한 번 생성되면 자동으로 업데이트되지 않음
- 데이터 파일 변경 후 수동으로 재초기화 필요

**해결 방법**:

**방법 1: Python 스크립트 실행 (권장)**
```bash
cd backend/engine/emotion-analysis
python reinit_vectorstore.py
```

**방법 2: API 엔드포인트 호출**
```bash
curl -X POST http://localhost:8000/api/init
```

**방법 3: 자동 초기화 안전장치 추가**
```python
# rag_pipeline.py의 analyze_emotion() 메서드
# Step 0: 벡터 스토어가 비어있으면 자동 초기화
if self.vector_store.get_count() == 0:
    print("⚠️ 벡터 스토어가 비어있어 자동 초기화를 시도합니다...")
    try:
        self.vector_store.initialize_from_data()
    except Exception as e:
        print(f"⚠️ 자동 초기화 실패: {str(e)}")
```

**결과**:
- ✅ 데이터 변경 시 명확한 재초기화 프로세스 확립
- ✅ 자동 초기화 안전장치로 빈 벡터 스토어 문제 방지
- ✅ 문서화를 통한 재현 가능성 확보

**교훈**:
- 데이터 변경 시 관련 컴포넌트 재초기화 필요성 인지
- 자동화된 안전장치로 사용자 경험 개선
- 명확한 문서화로 유지보수성 향상

---

### 1-3. 혼합 감정 처리 미구현 문제

**문제 상황**:
- "좋긴 한데 좀 불안해" 같은 혼합 감정 문장을 제대로 분석하지 못함
- 긍정과 부정이 섞인 감정을 단일 감정으로만 분류
- `sentiment_overall`이 긍정/부정 점수 차이로만 계산되어 혼합 상태를 반영하지 못함

**원인**:
- 초기 구현에서는 Primary 감정만 고려
- Secondary 감정의 그룹(positive/negative) 정보가 없음
- 혼합 감정을 명시적으로 감지하는 로직 부재

**해결 방법**:

**하이브리드 방식 구현** (그룹 기반 + 점수 기반)

```python
# emotion_analyzer.py의 _detect_mixed_emotion_hybrid() 메서드
def _detect_mixed_emotion_hybrid(
    self,
    primary_emotion: Dict[str, Any],
    secondary_emotions: List[Dict[str, Any]],
    normalized_distribution: List[Dict[str, Any]],
    group_threshold: float = 0.15
) -> Dict[str, Any]:
    """
    하이브리드 방식으로 혼합 감정 감지
    - 그룹 기반: Primary와 Secondary의 그룹이 다른지 확인
    - 점수 기반: 긍정/부정 점수가 모두 임계값(0.15) 이상인지 확인
    """
    # 1. 그룹 기반 감지
    primary_group = primary_emotion.get("group")
    has_different_group = any(
        sec.get("group") != primary_group 
        for sec in secondary_emotions 
        if sec.get("group")
    )
    
    # 2. 점수 기반 감지
    pos_sum = sum(item["score"] for item in normalized_distribution 
                  if item.get("group") == "positive")
    neg_sum = sum(item["score"] for item in normalized_distribution 
                  if item.get("group") == "negative")
    
    # 3. 하이브리드 판단
    is_mixed = has_different_group or (pos_sum >= group_threshold and neg_sum >= group_threshold)
    
    # 4. 혼합 비율 계산
    total = pos_sum + neg_sum
    mixed_ratio = min(pos_sum, neg_sum) / total if total > 0 else 0.0
    
    return {
        "is_mixed": is_mixed,
        "dominant_group": "positive" if pos_sum > neg_sum else "negative",
        "positive_ratio": pos_sum / total if total > 0 else 0.0,
        "negative_ratio": neg_sum / total if total > 0 else 0.0,
        "mixed_ratio": mixed_ratio
    }
```

**API 응답 구조 변경**:
```python
# models.py에 MixedEmotion 모델 추가
class MixedEmotion(BaseModel):
    is_mixed: bool
    dominant_group: str  # "positive" | "negative"
    positive_ratio: float
    negative_ratio: float
    mixed_ratio: float

# AnalyzeResponse17에 mixed_emotion 필드 추가 (Optional)
class AnalyzeResponse17(BaseModel):
    ...
    mixed_emotion: Optional[MixedEmotion] = None
```

**결과**:
- ✅ 혼합 감정 정확히 감지 가능
- ✅ "좋긴 한데 좀 불안해" 같은 문장 정확히 분석
- ✅ 하위 호환성 유지 (Optional 필드)
- ✅ 루틴 추천 로직에서 혼합 감정 활용 가능

**테스트 결과**:
- 입력: "좋긴 한데 좀 불안해"
- 결과: `is_mixed: true`, Primary: "공포" (negative), Secondary: "기쁨" (positive)
- 혼합 비율: 긍정 42.9%, 부정 57.1%

**교훈**:
- 복잡한 문제는 여러 방법을 조합한 하이브리드 접근이 효과적
- 하위 호환성을 고려한 점진적 개선
- 실제 사용 사례를 고려한 기능 설계

---

### 1-4. 감정 분포 데이터 불일치 문제

**문제 상황**:
- `sample_emotions.json`의 감정 코드가 17개 감정 체계와 일치하지 않음
- 벡터 스토어에 잘못된 감정 코드로 저장됨
- RAG 검색 결과가 부정확함

**원인**:
- 초기 데이터가 다른 감정 분류 체계를 사용
- 17개 감정 체계로 변경 후 데이터 변환 필요

**해결 방법**:

**1. 데이터 변환 스크립트 작성**
```python
# convert_emotions.py
# 기존 감정 코드를 17개 감정 코드로 매핑
```

**2. 벡터 스토어 재초기화**
- 변환된 데이터로 벡터 스토어 재생성
- `reinit_vectorstore.py` 실행

**3. 검증 프로세스 수립**
- 벡터 스토어 문서 수 확인 (491개)
- 17개 감정이 모두 포함되어 있는지 확인
- 감정 분포 확인

**결과**:
- ✅ 데이터 일관성 확보
- ✅ RAG 검색 정확도 향상
- ✅ 명확한 검증 프로세스 확립

**교훈**:
- 데이터 마이그레이션 시 검증 프로세스 필수
- 문서화를 통한 재현 가능성 확보
- 자동화된 검증 스크립트 활용

---

## 2. 성능 최적화

### 2-1. Lazy Initialization 적용

**문제 상황**:
- Emotion Analyzer가 매번 새로 생성되어 초기화 시간 소요
- 불필요한 리소스 사용

**해결 방법**:
```python
# adapters/emotion_adapter.py
_emotion_analyzer = None

def _get_emotion_analyzer():
    """Lazy initialization with caching"""
    global _emotion_analyzer
    if _emotion_analyzer is None:
        _emotion_analyzer = get_emotion_analyzer()
    return _emotion_analyzer
```

**결과**:
- ✅ 초기화 시간 단축
- ✅ 메모리 사용량 최적화
- ✅ 재사용을 통한 성능 향상

---

### 2-2. 벡터 스토어 자동 초기화 안전장치

**문제 상황**:
- 벡터 스토어가 비어있을 때 에러 발생
- 사용자가 수동으로 초기화해야 함

**해결 방법**:
```python
# rag_pipeline.py
if self.vector_store.get_count() == 0:
    print("⚠️ 벡터 스토어가 비어있어 자동 초기화를 시도합니다...")
    try:
        self.vector_store.initialize_from_data()
    except Exception as e:
        print(f"⚠️ 자동 초기화 실패: {str(e)}")
```

**결과**:
- ✅ 사용자 경험 개선
- ✅ 에러 방지
- ✅ 자동 복구 기능

---

## 3. 아키텍처 개선

### 3-1. 17개 감정 체계로 전환

**변경 전**:
- 다양한 감정 분류 체계 혼재
- 논문 기준과 불일치

**변경 후**:
- 이준호(2025) 논문 기준 17개 감정 체계 적용
- 긍정 7개, 부정 10개로 명확히 구분
- Russell & Mehrabian (1977) 이론 기반

**결과**:
- ✅ 논문 기준과 일치
- ✅ 이론적 근거 확보
- ✅ 일관된 감정 분류

---

### 3-2. RAG 파이프라인 구조화

**구조**:
1. 벡터 스토어에서 유사 컨텍스트 검색
2. 검색 결과를 LLM에 컨텍스트로 제공
3. LLM이 17개 감정 분포 생성
4. 백엔드에서 Primary/Secondary 감정 계산

**장점**:
- ✅ 컨텍스트 기반 정확도 향상
- ✅ 모듈화된 구조로 유지보수 용이
- ✅ 각 단계별 독립적 테스트 가능

---

## 4. 검증 및 테스트

### 4-1. 논문 기준 검증

**검증 항목**:
- ✅ 17개 감정 목록 일치 여부
- ✅ 이론적 기반 (Russell & Mehrabian) 적용 여부
- ✅ 긍정/부정 구분 일치 여부
- ✅ Top1/Top3 구조 일치 여부

**결과**: 
- 모든 항목에서 논문 기준과 일치 확인
- 상세 내용은 `PAPER_VERIFICATION.md` 참고

---

### 4-2. 혼합 감정 테스트

**테스트 케이스**:
1. 혼합 감정: "좋긴 한데 좀 불안해" → ✅ 정확히 감지
2. 단일 긍정: "오늘 정말 기분이 좋아요!" → ✅ 정확히 판단
3. 단일 부정: "너무 슬프고 우울해요" → ✅ 정확히 판단

**결과**: 모든 테스트 케이스 통과

---

## 5. 향후 개선 사항

### 5-1. VA 좌표값 추가

**현재 상태**: 논문의 Valence/Arousal 좌표값 미구현

**개선 방안**:
- 논문에서 각 감정의 VA 좌표값 확보
- `EMOTION_CLUSTERS_17`에 `valence`, `arousal` 필드 추가
- 루틴 추천 정확도 향상에 활용

**우선순위**: 중간

---

### 5-2. 감정 간 유사도 행렬 활용

**현재 상태**: 감정 간 유사도 정보 미활용

**개선 방안**:
- 논문의 감정 간 유사도 행렬 데이터 확보
- 유사 감정 기반 루틴 확장
- 감정 전이 예측 기능

**우선순위**: 낮음 (고급 기능)

---

## 6. 교훈 및 베스트 프랙티스

### 6-1. 외부 API 사용 시

- ✅ 버전/모델별 차이를 고려한 fallback 로직 구현
- ✅ 에러 핸들링을 통한 서비스 안정성 확보
- ✅ 재시도 로직으로 일시적 오류 대응

### 6-2. 데이터 마이그레이션 시

- ✅ 명확한 변환 프로세스 수립
- ✅ 검증 스크립트 작성
- ✅ 문서화를 통한 재현 가능성 확보

### 6-3. 복잡한 기능 구현 시

- ✅ 하이브리드 접근 방식 고려
- ✅ 하위 호환성 유지
- ✅ 실제 사용 사례 기반 설계

### 6-4. 성능 최적화

- ✅ Lazy initialization 활용
- ✅ 캐싱 전략 수립
- ✅ 자동화된 안전장치 구현

---

## 7. 참고 자료

- 논문: 이준호(2025). 감정의 형태: 정서 어휘집과 사전 학습 언어 모델을 이용한 감정의 분포와 구조 분석. 서울대학교 박사학위논문.
- 이론: Russell, J. A., & Mehrabian, A. (1977). Evidence for a three-factor theory of emotions.
- 검증 문서: `PAPER_VERIFICATION.md`
- 벡터 스토어 가이드: `src/REINIT_VECTORSTORE.md`

---

**작성일**: 2025년 1월  
**작성자**: [작성자명]  
**목적**: PPT 발표 및 블로그 포스팅

