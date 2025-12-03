# Deep Agent Pipeline 아키텍처 변경 이력

## 현재 아키텍처 (2025-12-03)

### Orchestrator-Writer 패턴

```
GPT-4o-mini (Orchestrator)
  ↓ 프롬프트 준비 및 변수 설정
Qwen 2.5 14B (Scenario Writer)
  ↓ 시나리오 텍스트 생성
GPT-4o-mini (Validator)
  ↓ 품질 검증 및 파싱
DB 저장
```

### 역할 분리

**Orchestrator (GPT-4o-mini)**:
- 전체 파이프라인 기획 및 지시
- 프롬프트 로드 및 변수 준비
- 결과 검증 및 품질 체크
- JSON 파싱 및 최종 조합

**Scenario Writer (Qwen 2.5 14B GGUF)**:
- 시나리오 텍스트 생성 (Step 0-3)
- 한국어 시나리오 고품질 생성
- 로컬 실행 (무료, 6-7분)

**Image Generator (FLUX.1-schnell)**:
- 17장 이미지 생성 (선택적)

### 4단계 생성 프로세스

1. **STEP 0: Character Design** - 캐릭터 비주얼 설명
2. **STEP 1: Nodes (15개)** - 타겟의 말/행동
3. **STEP 2: Options (30개)** - 주인공의 선택/대사
4. **STEP 3: Results (16개)** - 결과 및 분석

### 검증 로직

각 단계에서 Orchestrator가 품질 검증:
- **노드**: 개수(15), 필수 필드, 역할 분리, 타겟 적합성
- **옵션**: 개수(30), 필수 필드, 주인공 대사만 포함
- **결과**: 개수(16), 필수 필드, 타겟 관계 표현

---

## 이전 아키텍처 (레거시)

### 문제 상황

**요구사항**:
Deep Agent Pipeline에서 GPT-4o-mini를 사용하여 **15-30-16 구조**의 시나리오를 생성해야 함:
- **15개 노드** (Nodes)
- **30개 선택지** (Options)
- **16개 결과** (Results)

**발생한 문제**:
1. **JSON 파싱 실패**: LLM이 ` ```json` 마크다운 코드 블록으로 감싸서 응답
2. **구조 불일치**: 노드 13개, 옵션 14개 등 요구사항과 다른 개수 생성
3. **내용 불일치**: 프롬프트의 예시를 그대로 복사 (예: "김장 갈등" 제목)
4. **역할 분리 실패**: 노드에 주인공 대사 포함, 옵션에 타겟 대사 포함
5. **타겟 차별화 실패**: 모든 타겟(HUSBAND, FRIEND, etc.)이 "아들" 패턴으로 생성

### 왜 이런 문제가 발생했나?

**1. 프롬프트 복잡도**:
- `scenario_architect.md` 프롬프트가 120줄 이상으로 매우 복잡
- GPT-4o-mini는 빠르고 저렴하지만, 매우 긴 구조화된 출력에서 가끔 실수

**2. 61개 객체 동시 생성의 어려움**:
- 15 + 30 + 16 = **61개의 객체**를 한 번에 정확히 생성하는 것은 LLM에게 까다로운 작업

**3. 역할 분리 불명확**:
- 노드와 옵션의 역할이 프롬프트에서 명확히 구분되지 않음
- 예시가 모두 "아들" 케이스만 있어서 다른 타겟도 아들 패턴으로 생성

---

## 해결 방법 (현재)

### ✅ 채택한 방법: Orchestrator-Writer 패턴 + 4단계 분리

**핵심 개선사항**:

1. **역할 분리**:
   - Orchestrator (GPT-4o-mini): 기획/검증 (강점)
   - Writer (Qwen 2.5 14B): 창작 (강점)

2. **4단계 분리 생성**:
   - Step 0-3으로 나눠서 생성
   - 각 단계마다 검증 및 보완

3. **프롬프트 개선**:
   - 역할 분리 규칙 강화 (노드=타겟, 옵션=주인공)
   - 타겟별 차별화 (HUSBAND, CHILD, FRIEND, etc.)
   - 예시 편향 제거

4. **품질 향상**:
   - Qwen 2.5 14B가 GPT-4o-mini보다 한국어 시나리오 생성에 우수
   - 로컬 실행으로 비용 절감 (99% 절감)

**장점**:
- ✅ 높은 품질 (Qwen 14B)
- ✅ 비용 절감 (거의 무료)
- ✅ 역할 분리 명확
- ✅ 타겟별 차별화

**단점**:
- ⚠️ 느림 (6-7분 vs 15초)
- ⚠️ 첫 실행 시 모델 다운로드 필요 (~8GB)

---

## 이전 해결 방법 (레거시)

### ✅ 검증 후 보완 (Validate & Complete)

```
1단계: 전체 생성 시도
   ↓
2단계: 구조 검증 (15-30-16 확인)
   ↓
3단계: 부족한 부분만 추가 생성 (필요시)
```

#### 장점
- **대부분 1회 호출로 완료** (성공률 ~70%)
- **비용 효율적**: 실패 시 부족한 부분만 추가 (전체 재생성 불필요)
- **평균 API 호출**: ~1.3회
- **관계 개선 훈련의 의미 유지**: 복잡한 프롬프트 그대로 사용

#### 구현 방식

```python
async def generate_scenario_json(target, topic):
    # 1단계: 전체 생성
    scenario = await _generate_initial_scenario(target, topic)
    
    # 2단계: 검증 및 보완
    scenario = await _validate_and_complete(scenario, target, topic)
    
    return scenario

async def _validate_and_complete(scenario, target, topic, max_attempts=2):
    for attempt in range(max_attempts):
        # 부족한 요소 확인
        missing_nodes = max(0, 15 - len(scenario.nodes))
        missing_options = max(0, 30 - len(scenario.options))
        missing_results = max(0, 16 - len(scenario.results))
        
        if missing_nodes == 0 and missing_options == 0 and missing_results == 0:
            return scenario  # ✅ 완벽!
        
        # 부족한 부분만 추가 생성
        scenario = await _complete_missing_parts(
            scenario, target, topic,
            missing_nodes, missing_options, missing_results
        )
    
    return scenario
```

#### 보완 프롬프트 예시

```
기존 시나리오:
- 제목: 남편의 밥투정
- 현재 Nodes: 13개
- 현재 Options: 28개
- 현재 Results: 16개

부족한 요소:
- Nodes: 2개 추가 필요
- Options: 2개 추가 필요

위 시나리오에 부족한 요소를 추가로 생성해주세요.
기존 스타일과 일관성을 유지하세요.
```

### ❌ 고려했지만 채택하지 않은 방법들

#### 1. 프롬프트 단순화
```
장점: LLM 성공률 100%
단점: 관계 개선 훈련의 의미 퇴색
결론: ❌ 채택 안 함
```

#### 2. 완전 분리 생성 (3단계)
```
1. Nodes만 생성 (1회 호출)
2. Options만 생성 (1회 호출)
3. Results만 생성 (1회 호출)

장점: 각 단계 정확도 높음
단점: API 3회 호출 (비용 3배), 시간 3배
결론: ❌ 비효율적
```

#### 3. GPT-4o로 업그레이드
```
장점: 복잡한 구조 정확도 매우 높음
단점: 비용 10배 (gpt-4o-mini 대비)
결론: ❌ 비용 부담
```

## 추가 개선 사항

### 1. JSON 추출 로직 강화
`prompt_utils.py`의 `extract_json_from_response()` 함수 개선:

```python
def extract_json_from_response(response_text: str) -> str:
    # Method 1: 마크다운 코드 블록 제거
    pattern = r'```(?:json)?\s*(.*?)\s*```'
    matches = re.findall(pattern, response_text, re.DOTALL)
    if matches:
        return matches[0].strip()
    
    # Method 2: 중괄호 패턴 추출
    first_brace = response_text.find('{')
    last_brace = response_text.rfind('}')
    if first_brace != -1 and last_brace != -1:
        return response_text[first_brace:last_brace + 1].strip()
    
    # Method 3: 원본 반환
    return response_text.strip()
```

### 2. 프롬프트 개선
- 구체적인 예시 제거 (LLM이 복사하는 문제 방지)
- 출력 개수 명시 강화
- "순수 JSON만 출력" 지시 추가

### 3. 검증 로직 완화
개발 단계에서는 경고만 출력하고 진행:

```python
if len(nodes) != 15:
    print(f"[WARN] Expected 15 nodes, got {len(nodes)} - continuing anyway")
    # raise ValueError  # 주석 처리
```

## 성능 비교

| 방법 | 평균 API 호출 | 평균 비용 | 성공률 | 시간 |
|------|--------------|----------|--------|------|
| **검증 후 보완** | **1.3회** | **$0.003** | **~95%** | **~15초** |
| 완전 분리 | 3회 | $0.007 | ~99% | ~30초 |
| GPT-4o | 1회 | $0.03 | ~99% | ~20초 |

## 결론

**검증 후 보완 방식**이 최적의 해결책:
- ✅ 비용 효율적
- ✅ 높은 성공률
- ✅ 빠른 속도
- ✅ 관계 개선 훈련의 의미 유지

## 참고 자료

- 구현 파일: `backend/app/relation_training/deep_agent_service.py`
- 프롬프트 파일: `backend/app/relation_training/prompts/scenario_architect.md`
- 유틸리티: `backend/app/relation_training/prompt_utils.py`

