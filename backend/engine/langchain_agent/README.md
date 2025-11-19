# LangChain Agent v1.0

마음봄 서비스의 LangChain Agent v1.0 프로토타입입니다.

## 개요

STT → 감정 분석 → GPT-4o 응답 생성의 전체 플로우를 orchestration하는 Agent입니다.

## 폴더 구조

```
/backend/engine/langchain-agent/
├── __init__.py              # 모듈 진입점
├── agent.py                 # 메인 Agent 로직
├── adapters/                # 엔진 어댑터들
│   ├── __init__.py
│   ├── stt_adapter.py       # STT 어댑터
│   └── emotion_adapter.py   # Emotion Analysis 어댑터
└── README.md                # 이 문서
```

## 주요 기능

### 1. 음성/텍스트 입력 처리
- `run_ai_bomi_from_text()`: 텍스트 입력 처리
- `run_ai_bomi_from_audio()`: 음성 입력 처리 (STT → 텍스트)

### 2. 감정 분석
- 기존 emotion-analysis 엔진 연동
- 17개 감정 군집 기반 분석

### 3. LLM 응답 생성
- GPT-4o를 사용한 공감적 응답 생성
- "AI 봄이" 페르소나

### 4. 대화 히스토리 관리
- In-memory 세션별 대화 저장
- 나중에 DB/Redis로 교체 가능

## 설치

```bash
# 프로젝트 루트에서
cd backend
pip install -r requirements.txt
```

## 환경 설정

`.env` 파일에 다음 환경변수를 설정하세요:

```bash
# OpenAI API 키 (필수)
OPENAI_API_KEY=your_openai_api_key_here

# 모델명 (선택, 기본값: gpt-4o-mini)
OPENAI_MODEL_NAME=gpt-4o-mini
```

## 사용법

### Python 코드에서 사용

```python
from engine.langchain_agent import run_ai_bomi_from_text, run_ai_bomi_from_audio

# 텍스트 입력
result = run_ai_bomi_from_text(
    user_text="오늘 하루 정말 힘들었어요.",
    session_id="user_123"
)

print(result["reply_text"])  # AI 봄이의 응답
print(result["emotion_result"])  # 감정 분석 결과

# 음성 입력
with open("audio.wav", "rb") as f:
    audio_bytes = f.read()

result = run_ai_bomi_from_audio(
    audio_bytes=audio_bytes,
    session_id="user_123"
)
```

### 테스트 실행

```bash
cd backend/engine/langchain-agent
python agent.py
```

## 응답 구조

```python
{
    "reply_text": "AI 봄이의 응답 텍스트",
    "input_text": "사용자 입력 텍스트",
    "emotion_result": {
        "text": "...",
        "language": "ko",
        "raw_distribution": [...],
        "primary_emotion": {
            "code": "sadness",
            "name_ko": "슬픔",
            "group": "negative",
            "intensity": 4,
            "confidence": 0.85
        },
        "secondary_emotions": [...],
        "sentiment_overall": "negative",
        "service_signals": {
            "need_empathy": True,
            "need_routine_recommend": True,
            "need_health_check": False,
            "need_voice_analysis": False,
            "risk_level": "watch"
        },
        "recommended_response_style": [...],
        "recommended_routine_tags": [...],
        "report_tags": [...]
    },
    "meta": {
        "model": "gpt-4o",
        "used_tools": ["emotion_analysis"],
        "session_id": "user_123"
    }
}
```

## 아키텍처

### 주요 컴포넌트

1. **InMemoryConversationStore**
   - 세션별 대화 히스토리 관리
   - v1.0: In-memory 구현
   - 향후: DB/Redis로 교체 가능

2. **ToolRouter**
   - Tool 호출 라우팅
   - v1.0: emotion-analysis만 사용
   - 향후: routine_recommend, health_advisor 등 추가 가능

3. **LLM Chain**
   - LangChain의 ChatOpenAI + ChatPromptTemplate 사용
   - System Prompt: "AI 봄이" 페르소나
   - 감정 분석 결과를 기반으로 공감적 응답 생성

### 어댑터 패턴

기존 엔진을 수정하지 않고 어댑터를 통해 연동:

- `/backend/engine/langchain-agent/adapters/stt_adapter.py`
- `/backend/engine/langchain-agent/adapters/emotion_adapter.py`

## v1.0 제약사항

1. **STT 엔진**: 실제 모델이 없으면 더미 텍스트 반환
2. **대화 히스토리**: In-memory 저장 (서버 재시작 시 소실)
3. **Tool Router**: emotion-analysis만 사용

## 향후 개선 사항

1. STT 엔진 실제 연동
2. DB/Redis 기반 대화 히스토리 저장
3. 추가 Tool 연동 (routine_recommend, health_advisor 등)
4. 스트리밍 응답 지원
5. 에러 핸들링 강화

## 라이선스

MIT

