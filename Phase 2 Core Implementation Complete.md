# **Phase 2 Core Implementation Complete**

### **1. tools.py ✅**

**파일:**

backend/engine/langchain_agent/tools.py

**5개 도구 정의:**

1. **search_emotion_cache**
    - 캐시된 감정 분석 검색
    - 빠르고 비용 효율적
    - 우선순위: 최우선
2. **analyze_emotion**
    - 새로운 감정 분석 실행 (17개 군집)
    - 캐시 미스 시에만 사용
    - 결과 자동 캐시 저장
3. **recommend_routine**
    - 감정 기반 루틴 추천
    - RAG + LLM 선택 엔진
    - 감정 분석 결과 필요
4. **save_plan**
    - TB_AGENT_PLANS에 계획 저장
    - 타입: routine, reminder, goal, suggestion
    - 미래 의도 감지 시 호출
5. **search_memory**
    - 장기 기억(Global Memory) 검색
    - 키워드 기반 필터링
    - 과거 컨텍스트 조회

**헬퍼 함수:**

```
get_tool_by_name(name)  # 이름으로 도구 조회
get_tool_names()        # 모든 도구 이름 리스트
```

---

### **2. orchestrator.py ✅**

**파일:**

backend/engine/langchain_agent/orchestrator.py

### **2.1 orchestrator_llm()**

**목적:** 사용자 의도 분석 및 도구 선택

**Input:**

```
user_text: str           # 사용자 입력
context: Dict            # session_id, memory, history
classifier_hint: str     # "필요"/"불필요"/"애매"
```

**Output:**

```
tool_calls: List  # OpenAI tool_calls 객체 리스트
```

**시스템 프롬프트 구조:**

- **시스템 프롬프트 한국어 번역**
    
    ### 1. 역할 정의 (Role)
    
    > "당신은 갱년기 중년 여성을 돕는 AI 컴패니언의 오케스트레이터(지휘자)입니다."
    > 
    - **의미:** 이 AI는 직접 대화를 생성하기보다는, 사용자의 의도를 파악해서 **필요한 기능(도구)을 연결해 주는 관리자**입니다.
    
    ### 2. 경량 분류기 힌트 (Lightweight Classifier Hint) - **핵심 포인트!**
    
    > "경량 모델이 미리 귀띔해 준 힌트를 참고하세요."
    > 
    
    이 부분이 바로 아까 질문하신 **[2. 경량 Classifier]**와 **[3. 하이브리드]** 전략이 적용된 부분입니다.
    
    - **`classifier_hint` 변수:** 경량 모델이 먼저 판단한 결과("필요", "불필요", "애매")가 여기에 들어옵니다.
        - **"필요" (Needed):** 감정이 확실하니 → **`search_emotion_cache()`(캐시 검색)**를 최우선으로 실행해라.
        - **"불필요" (Not Needed):** 인사나 단순 질문이니 → 감정 분석 단계를 **건너뛰어라(Skip).** (비용/시간 절약)
        - **"애매" (Unclear):** 경량 모델이 모르겠다고 하니 → **네가(Orchestrator LLM) 문맥을 보고 판단해라.**
    
    ### 3. 도구 선택 원칙 (Tool Selection Principles)
    
    AI가 사용할 수 있는 4가지 무기(기능)와 사용 규칙입니다.
    
    1. **감정 분석 (Emotion Analysis)**
        - **규칙:** 무작정 분석부터 하지 말고, **무조건 `search_emotion_cache()`(캐시 뒤지기)부터 해라.**
        - **비용 절감:** 캐시에 없을 것 같을 때만 비싼 `analyze_emotion()`을 돌려라.
    2. **루틴 추천 (Routine Recommendation)**
        - **조건:** 사용자가 힘들다고 하거나, 추천을 원할 때.
        - **의존성:** 이 기능은 **감정 분석 결과가 있어야만** 작동한다. (순서 중요)
    3. **계획 저장 (Plan Saving)**
        - **기능:** 사용자가 미래의 일("내일 ~할 거야", "예정이야")을 말하면 놓치지 말고 `save_plan`으로 저장해라.
        - **예시:** "내일 아침 명상하려고" → 명상 루틴으로 저장.
    4. **기억 검색 (Memory Search)**
        - **기능:** 과거 대화 내용이 필요하면("지난주에 내가 뭐랬지?") `search_memory`를 써라.
    
    ### 4. 지시 사항 (Instructions)
    
    - **논리적 순서:** 도구 호출 순서를 지켜라. (캐시 확인 -> 감정 분석 -> 루틴 추천 순서)
    - **과잉 엔지니어링 금지:** 쓸데없이 도구 호출하지 마라. (그냥 대답만 해도 되면 도구 쓰지 마라)
1. Lightweight Classifier 힌트 활용
2. 도구 선택 원칙 명시
3. 사용자 입력 분석
4. 최소 필수 도구만 선택

**핵심 로직:**

- Temperature: 0.3 (일관된 도구 선택)
- tool_choice: "auto" (0개 도구도 가능)
- 최근 3개 메시지 컨텍스트 제공

---

### **2.2 execute_tools()**

**목적:** 선택된 도구 순차 실행 및 결과 집계

**Input:**

```
tool_calls: List      # Orchestrator 선택 결과
user_id: int
session_id: str
user_text: str
db_session: Session   # SQLAlchemy session

```

**Output:**

```
results: Dict[str, Any]
{
    "emotion": {...},
    "routines": [...],
    "plan_saved": {...},
    "memory_search": {...}
}

```

**도구별 실행 로직:**

### 🔍 search_emotion_cache

```
cache_result = cache.search(
    query_text=user_text,
    user_id=user_id,
    threshold=0.85,
    freshness_days=30
)
if cache_result:
    results["emotion"] = cache_result  # 캐시 히트
else:
    results["emotion_cache_miss"] = True

```

### 🧠 analyze_emotion

```
# 캐시 히트 시 스킵
if "emotion" in results and results["emotion"].get("cached"):
    continue
analyzer = EmotionAnalyzer()
emotion_result = analyzer.analyze_emotion(user_text)
# DB + 캐시 저장
analysis_id = store.save_emotion_analysis(...)
cache.save(...)
results["emotion"] = {"cached": False, "result": emotion_result}

```

### 🏃 recommend_routine

```
emotion = results.get("emotion", {}).get("result")
# EmotionAnalysisResult 객체 생성
emotion_obj = EmotionAnalysisResult(
    cluster_label=emotion.get("cluster_label"),
    polarity=emotion.get("polarity"),
    ...
)
engine = RoutineRecommendFromEmotionEngine()
routines = await engine.recommend(emotion=emotion_obj, ...)
results["routines"] = routines

```

### 📅 save_plan

```
plan = AgentPlan(
    USER_ID=user_id,
    PLAN_TYPE=args["plan_type"],  # routine/reminder/goal/suggestion
    TARGET_DATE=args.get("target_date"),  # ISO 8601 or None
    CONTENT=json.dumps(args["content"], ensure_ascii=False),
    STATUS="pending",
    SOURCE_SESSION_ID=session_id
)
db_session.add(plan)
db_session.commit()
results["plan_saved"] = {
    "id": plan.ID,
    "type": plan.PLAN_TYPE,
    ...
}

```

### 🔎 search_memory

```
query = args.get("query", "")
memories = get_memories_for_prompt(session_id, user_id)
# 키워드 검색
relevant = [line for line in memories.split('\n') if query in line]
results["memory_search"] = {
    "query": query,
    "results": relevant or memories,
    "found_count": len(relevant)
}

```

---

## **🔧 에러 핸들링**

### **1. Import Fallback**

```
try:
    from engine.emotion_analysis.src.emotion_analyzer import EmotionAnalyzer
except ImportError:
    try:
        from emotion_analysis.src.emotion_analyzer import EmotionAnalyzer
    except ImportError:
        logger.error("EmotionAnalyzer import failed")
        return {"error": "Import failed"}

```

### **2. 도구별 에러 캡처**

```
try:
    # 도구 실행
except json.JSONDecodeError:
    results[f"{func_name}_error"] = "Invalid arguments"
except Exception as e:
    logger.error(f"Tool failed: {func_name} - {e}")
    results[f"{func_name}_error"] = str(e)

```

### **3. DB 트랜잭션 롤백**

```
try:
    db_session.add(plan)
    db_session.commit()
except Exception as e:
    db_session.rollback()
    results["save_plan_error"] = str(e)

```

---

## **📊 도구 선택 시나리오**

### **시나리오 1: 감정 표현**

**입력:** "오늘 너무 힘들어"

**Orchestrator 선택:**

```
["search_emotion_cache", "recommend_routine"]

```

**실행 흐름:**

1. search_emotion_cache → Cache Hit/Miss
2. (Cache Miss 시) analyze_emotion (Orchestrator 예측)
3. recommend_routine → 스트레스 완화 루틴 추천

---

### **시나리오 2: 계획 저장**

**입력:** "내일 아침 7시에 명상하려고 해"

**Orchestrator 선택:**

```
["save_plan"]

```

**실행 흐름:**

1. save_plan → TB_AGENT_PLANS 저장
    - plan_type: "routine"
    - target_date: "2025-12-05T07:00:00"
    - content: {"title": "아침 명상", "description": "7시에 명상"}

---

### **시나리오 3: 중립적 질문**

**입력:** "오늘 날씨 어때?"

**Orchestrator 선택:**

```
[]  # 도구 없음

```

**실행 흐름:**

- 도구 실행 없이 바로 응답 생성

---

### **시나리오 4: 기억 조회**

**입력:** "지난주에 내가 뭐라고 했지?"

**Orchestrator 선택:**

```
["search_memory"]

```

**실행 흐름:**

1. search_memory → 장기 기억 검색
    - query: "지난주"
    - 관련 기억 반환

---

## **🎯 TB_AGENT_PLANS 활용**

### **테이블 구조**

```
CREATE TABLE TB_AGENT_PLANS (
    ID INTEGER PRIMARY KEY,
    USER_ID INTEGER NOT NULL,
    PLAN_TYPE VARCHAR(50),       -- 'routine', 'reminder', 'goal', 'suggestion'
    TARGET_DATE TIMESTAMP,        -- 실행 예정 시간
    CONTENT TEXT,                 -- JSON: {"title": "...", "description": "..."}
    STATUS VARCHAR(20),           -- 'pending', 'completed', 'cancelled'
    SOURCE_SESSION_ID VARCHAR(255),
    CREATED_AT TIMESTAMP,
    UPDATED_AT TIMESTAMP
);

```

### **저장 예시**

```
# 사용자: "내일 저녁 산책하기로 했어"
plan = AgentPlan(
    USER_ID=123,
    PLAN_TYPE="routine",
    TARGET_DATE="2025-12-05T18:00:00",
    CONTENT='{"title": "저녁 산책", "description": "30분 걷기"}',
    STATUS="pending",
    SOURCE_SESSION_ID="abc123"
)

```

---

## **📝 다음 단계**

### **즉시 필요**

1. **agent_v2.py 통합** (임시 테스트용)
    - orchestrator_llm() 호출
    - execute_tools() 호출
    - 결과 메타데이터에 추가
2. **계획 조회 API** (선택적)
    
    ```
    GET /api/agent/plans?user_id={id}&status=pending
    ```
    
3. **테스트**
    - 도구 선택 정확도 측정
    - TB_AGENT_PLANS 저장 확인
    - 에러 핸들링 검증

### **Phase 3 준비**

- Response Generator 분리
- agent_v3.py 생성
- V2 → V3 마이그레이션