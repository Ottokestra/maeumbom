# 전체 프로젝트 개발 가이드

이 문서는 프로젝트 전체에 새로운 기능을 추가하는 개발자를 위한 가이드입니다.

**중요**: 이 가이드를 Cursor AI 프롬프트에 포함하면, 동일한 프로젝트 구조와 코드 스타일로 새로운 기능을 생성할 수 있습니다.

## 프로젝트 개요

이 프로젝트는 FastAPI 기반의 백엔드 애플리케이션으로, 다음과 같이 구성되어 있습니다:

- **`backend/app/`**: 비즈니스 로직 및 API 서비스 (인증, 일일 감정 체크, 날씨 등)
- **`backend/engine/`**: AI 모델 및 LangChain 에이전트 (감정 분석, STT, TTS 등)
- **`backend/main.py`**: 통합 FastAPI 애플리케이션 (모든 라우터 통합)

### 폴더 역할 구분

| 폴더 | 역할 | 예시 |
|------|------|------|
| `backend/app/` | 비즈니스 로직, 사용자 서비스, API 엔드포인트 | 인증, 일일 감정 체크, 날씨 조회 |
| `backend/engine/` | AI 모델, ML 엔진, LangChain 에이전트 | 감정 분석, 음성 인식, 텍스트 음성 변환 |
| `backend/app/db/` | 데이터베이스 모델 및 연결 | SQLAlchemy 모델, DB 연결 설정 |

**참고**: 데이터베이스 모델 추가는 `DB_GUIDE.md`를 참조하세요.

## 개발 환경

### 필수 요구사항
- **Python**: 3.11
- **프레임워크**: FastAPI
- **가상환경**: 프로젝트 루트에서 가상환경 사용 권장

### Python 3.11 가상환경 설정

```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Linux/Mac
python3.11 -m venv venv
source venv/bin/activate
```

## 프로젝트 구조

```
backend/
├── app/                    # 비즈니스 로직 및 API 서비스
│   ├── auth/              # 인증 서비스 (OAuth, JWT)
│   ├── daily_mood_check/  # 일일 감정 체크 서비스
│   ├── weather/           # 날씨 조회 서비스
│   └── db/                # 데이터베이스 모델 및 연결
│       ├── database.py    # DB 연결 설정
│       └── models.py      # SQLAlchemy 모델
├── engine/                 # AI 모델 및 LangChain 에이전트
│   ├── emotion-analysis/  # 감정 분석 엔진
│   ├── speech-to-text/    # 음성 인식 엔진
│   ├── text-to-speech/    # 텍스트 음성 변환 엔진
│   ├── langchain_agent/   # LangChain 에이전트
│   └── routine_recommend/ # 루틴 추천 엔진
└── main.py                 # 통합 FastAPI 애플리케이션
```

---

## Part 1: `backend/app/` 폴더 개발 가이드

`backend/app/` 폴더는 **비즈니스 로직**과 **API 서비스**를 담당합니다.

### 역할
- 사용자 인증 및 권한 관리
- 비즈니스 로직 처리
- 외부 API 연동 (날씨, OAuth 등)
- 데이터베이스 CRUD 작업

### 기본 구조

새로운 서비스를 추가할 때는 다음 구조를 따르세요:

```
app/your-service/
├── __init__.py
├── routes.py       # FastAPI 라우터 (Controller)
├── service.py      # 비즈니스 로직 (Service)
├── models.py       # Pydantic 모델 (요청/응답)
├── storage.py     # 데이터 저장소 로직 (필요시)
├── client.py       # 외부 API 클라이언트 (필요시)
└── README.md       # 서비스별 문서 (권장)
```

### 파일 역할

#### `routes.py` - API 엔드포인트 (Controller)

FastAPI 라우터를 정의합니다. 요청을 받아 서비스 로직을 호출하고 응답을 반환합니다.

```python
"""
API endpoints for your service
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from .models import YourRequest, YourResponse
from .service import your_service_function

router = APIRouter()


@router.post("/your-endpoint", response_model=YourResponse)
async def your_endpoint(
    request: YourRequest,
    db: Session = Depends(get_db)
):
    """
    엔드포인트 설명
    
    Args:
        request: 요청 데이터
        db: Database session
        
    Returns:
        YourResponse: 응답 데이터
    """
    try:
        result = your_service_function(db, request)
        return YourResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

#### `service.py` - 비즈니스 로직 (Service)

실제 비즈니스 로직을 처리합니다. 데이터베이스 작업, 외부 API 호출 등을 수행합니다.

```python
"""
Business logic for your service
"""
from sqlalchemy.orm import Session
from typing import Dict, Any
from .models import YourRequest

def your_service_function(db: Session, request: YourRequest) -> Dict[str, Any]:
    """
    비즈니스 로직 처리
    
    Args:
        db: Database session
        request: 요청 데이터
        
    Returns:
        처리 결과 딕셔너리
    """
    # 비즈니스 로직 구현
    # DB 작업, 외부 API 호출 등
    
    return {
        "result": "success",
        "data": {}
    }
```

#### `models.py` - Pydantic 모델

요청/응답 데이터의 스키마를 정의합니다.

```python
"""
Pydantic models for request/response validation
"""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class YourRequest(BaseModel):
    """요청 모델"""
    field1: str
    field2: Optional[int] = None

class YourResponse(BaseModel):
    """응답 모델"""
    result: str
    data: dict
    created_at: datetime
```

### 예시 프로젝트 참고

기존 서비스들을 참고하여 구조를 파악할 수 있습니다:

- **`app/auth/`**: OAuth 인증, JWT 토큰 관리
  - `routers.py`: 인증 엔드포인트
  - `services.py`: OAuth 로직, 토큰 생성
  - `dependencies.py`: 인증 의존성 (`get_current_user`)
  - `models.py`: SQLAlchemy User 모델
  - `schemas.py`: Pydantic 요청/응답 모델

- **`app/daily_mood_check/`**: 일일 감정 체크 서비스
  - `routes.py`: 이미지 선택, 상태 조회 엔드포인트
  - `service.py`: 감정 분석 로직, 이미지 선택 처리
  - `storage.py`: JSON 파일 저장소 (하위 호환성)
  - `models.py`: Pydantic 모델

- **`app/weather/`**: 날씨 조회 서비스
  - `routes.py`: 날씨 조회 엔드포인트
  - `service.py`: 날씨 정보 조회 로직
  - `client.py`: 외부 날씨 API 클라이언트
  - `models.py`: Pydantic 모델

### 인증 사용하기

인증이 필요한 엔드포인트는 `app.auth.dependencies`의 `get_current_user`를 사용하세요:

```python
from app.auth.dependencies import get_current_user
from app.auth.models import User
from fastapi import Depends

@router.get("/protected")
async def protected_endpoint(
    current_user: User = Depends(get_current_user)
):
    """인증이 필요한 엔드포인트"""
    return {"user_id": current_user.id, "email": current_user.email}
```

### 데이터베이스 사용하기

데이터베이스 모델을 사용하려면 `app.db`에서 import하세요:

```python
from app.db.database import get_db
from app.db.models import YourModel
from sqlalchemy.orm import Session
from fastapi import Depends

@router.post("/create")
async def create_item(
    db: Session = Depends(get_db)
):
    """데이터베이스에 항목 생성"""
    new_item = YourModel(
        FIELD1="value1",
        FIELD2="value2"
    )
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item
```

**참고**: 데이터베이스 모델 추가 방법은 `DB_GUIDE.md`를 참조하세요.

### 서비스 추가 예시

**기본 서비스 생성 요청 예시:**
```
"backend/DEVELOPER_GUIDE.md를 참고하여 
backend/app/my-service 폴더에 새로운 서비스를 만들어줘.
서비스 이름은 'my-service'이고, /api/service/my-service/hello 엔드포인트를 만들어줘."
```

**인증이 필요한 서비스 생성 요청 예시:**
```
"backend/DEVELOPER_GUIDE.md를 참고하여 
backend/app/my-service 폴더에 인증이 필요한 서비스를 만들어줘.
/api/service/my-service/protected 엔드포인트는 인증이 필요하고,
/api/service/my-service/public 엔드포인트는 인증이 필요 없어야 해."
```

---

## Part 2: `backend/engine/` 폴더 개발 가이드

`backend/engine/` 폴더는 **AI 모델**과 **LangChain 에이전트**를 담당합니다.

### 역할
- AI 모델 추론 (감정 분석, 음성 인식 등)
- LangChain 에이전트 및 RAG 파이프라인
- ML 엔진 및 벡터 데이터베이스
- 독립적으로 실행 가능한 FastAPI 앱

### 기본 구조

새로운 엔진을 추가할 때는 다음 **기본 구조**를 참고하되, 각 엔진의 특성에 맞게 조정할 수 있습니다:

**기본 구조 (최소 필수 요소):**
```
engine/your-new-engine/
├── api/
│   ├── __init__.py
│   ├── main.py         # FastAPI 앱 (필수)
│   ├── routes.py       # API 엔드포인트 (필수)
│   └── models.py       # 요청/응답 모델 (필수)
├── src/                # 핵심 비즈니스 로직 (필수)
│   ├── __init__.py
│   └── your_logic.py
├── tests/              # 테스트 코드 (권장)
│   ├── __init__.py
│   └── test_api.py
├── requirements.txt    # 의존성 목록 (필수)
└── README.md          # 엔진별 문서 (권장)
```

**구조 조정 예시:**
- **데이터가 필요한 경우**: `data/` 폴더 추가
- **설정 파일이 필요한 경우**: `config/` 폴더 또는 `config.yaml` 추가
- **벡터 DB가 필요한 경우**: `vectordb/` 폴더 추가
- **복잡한 파이프라인이 있는 경우**: `src/` 내부에 여러 모듈로 분리

**참고**: 기존 엔진들을 보면 구조가 다릅니다:
- `emotion-analysis/`: RAG 파이프라인, 벡터 스토어 등 복잡한 구조
- `speech-to-text/`: 음성 처리, VAD 엔진 등 다른 구조
- `text-to-speech/`: TTS 모델, 음성 합성 등 다른 구조

**원칙**: FastAPI 앱(`api/main.py`, `api/routes.py`, `api/models.py`)은 필수이며, 나머지는 엔진의 특성에 맞게 구성하세요.

### FastAPI 애플리케이션 기본 구조

#### `api/main.py` 예시

```python
"""
FastAPI application entry point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes import router

# Create FastAPI app
app = FastAPI(
    title="Your Engine API",
    description="엔진 설명",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],  # React dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(router, prefix="/api", tags=["your-engine"])


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Your Engine API",
        "version": "1.0.0",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
```

#### `api/routes.py` 예시

```python
"""
API routes
"""
from fastapi import APIRouter, HTTPException
from .models import YourRequest, YourResponse

router = APIRouter()


@router.post("/your-endpoint", response_model=YourResponse)
async def your_endpoint(request: YourRequest):
    """
    엔드포인트 설명
    
    Args:
        request: 요청 데이터
        
    Returns:
        YourResponse: 응답 데이터
    """
    try:
        # 비즈니스 로직 호출
        # src/your_logic.py에서 함수 import하여 사용
        from ..src.your_logic import process_request
        
        result = process_request(request)
        return YourResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}
```

#### `api/models.py` 예시

```python
"""
Pydantic models for request/response validation
"""
from pydantic import BaseModel
from typing import Optional

class YourRequest(BaseModel):
    """요청 모델"""
    text: str
    option: Optional[str] = None

class YourResponse(BaseModel):
    """응답 모델"""
    result: str
    confidence: float
```

### 의존성 관리

#### `requirements.txt` 예시

```
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.0.0
python-dotenv>=1.0.0
```

설치:
```bash
pip install -r requirements.txt
```

### 환경 변수 설정

프로젝트 루트의 `.env` 파일을 사용하거나, 엔진별로 `.env` 파일을 생성할 수 있습니다.

```python
# src/config.py 예시
import os
from pathlib import Path
from dotenv import load_dotenv

# 프로젝트 루트의 .env 파일 로드
project_root = Path(__file__).parent.parent.parent.parent  # backend/
env_path = project_root / ".env"
load_dotenv(dotenv_path=env_path)

# 환경 변수 사용
API_KEY = os.getenv("YOUR_API_KEY")
```

### 서버 실행

#### 개발 모드
```bash
cd engine/your-new-engine
python api/main.py
```

또는 uvicorn을 직접 사용:
```bash
python -m uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

#### 프로덕션 모드
```bash
uvicorn api.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### API 문서 확인

서버 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### 예시 프로젝트 참고

기존 엔진들을 참고하여 구조를 파악할 수 있습니다:
- `emotion-analysis/`: 감정 분석 엔진 예시 (RAG 파이프라인)
- `speech-to-text/`: 음성 인식 엔진 예시
- `text-to-speech/`: 텍스트 음성 변환 엔진 예시
- `langchain_agent/`: LangChain 에이전트 예시

**참고**: 
- 기존 프로젝트의 `routes.py`는 복잡한 importlib.util 패턴을 사용하지만, 
  새 프로젝트는 일반적인 Python import (`from .models import ...`)를 사용해도 됩니다.
- 각 엔진의 기능이 다르므로, 구조도 달라질 수 있습니다. 
  기본 구조를 참고하되, 엔진의 특성에 맞게 폴더와 파일을 추가/수정하세요.

### Cursor AI 사용 시

이 가이드를 Cursor AI 프롬프트에 포함하고 다음과 같이 요청하면, 기본 구조로 프로젝트가 생성됩니다:

**기본 요청 예시:**
```
"backend/DEVELOPER_GUIDE.md를 참고하여 
backend/engine/my-new-engine 폴더에 새로운 FastAPI 엔진을 만들어줘.
엔진 이름은 'my-new-engine'이고, /api/process 엔드포인트를 만들어줘."
```

**구조 커스터마이징 요청 예시:**
```
"backend/DEVELOPER_GUIDE.md의 기본 구조를 참고하되,
이 엔진은 데이터베이스가 필요하므로 data/ 폴더를 추가하고,
설정 파일을 위해 config.yaml을 만들어줘."
```

**중요**: 가이드는 기본 구조를 제공하지만, 각 엔진의 특성에 맞게 구조를 조정하는 것이 좋습니다.

---

## Part 3: 통합 애플리케이션 (`main.py`) 가이드

`backend/main.py`는 모든 라우터를 통합하는 메인 FastAPI 애플리케이션입니다.

### 라우터 통합 방법

#### 1. 일반적인 import 방식 (권장)

`app/` 폴더의 서비스는 일반적인 import를 사용합니다:

```python
from app.weather.routes import router as weather_router
from app.auth import router as auth_router

app.include_router(weather_router, prefix="/api/service/weather", tags=["weather"])
app.include_router(auth_router, prefix="/auth", tags=["authentication"])
```

#### 2. 동적 모듈 로딩 방식 (하이픈이 있는 폴더명)

`engine/` 폴더의 엔진은 하이픈이 있는 폴더명 때문에 `importlib.util`을 사용합니다:

```python
import importlib.util
from pathlib import Path

backend_path = Path(__file__).parent

# Emotion Analysis 라우터 로딩
emotion_router = None
try:
    emotion_analysis_path = backend_path / "engine" / "emotion-analysis" / "api" / "routes.py"
    spec = importlib.util.spec_from_file_location("emotion_routes", emotion_analysis_path)
    emotion_routes = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(emotion_routes)
    emotion_router = emotion_routes.router
    print("[INFO] Emotion analysis router loaded successfully.")
except Exception as e:
    print("[WARN] Emotion analysis module load failed:", e)
    emotion_router = None

# 라우터 등록
if emotion_router is not None:
    app.include_router(emotion_router, prefix="/emotion/api", tags=["emotion"])
```

### WebSocket 엔드포인트 추가

WebSocket 엔드포인트는 `main.py`에 직접 추가합니다:

```python
from fastapi import WebSocket, WebSocketDisconnect

@app.websocket("/your-websocket")
async def your_websocket(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive()
            # 데이터 처리
            await websocket.send_json({"status": "ok"})
    except WebSocketDisconnect:
        print("WebSocket 연결 종료")
```

### 에러 처리

모듈 로딩 실패 시에도 서버가 계속 실행되도록 try-except를 사용합니다:

```python
try:
    from app.your_service.routes import router as your_router
    app.include_router(your_router, prefix="/api/service/your-service", tags=["your-service"])
    print("[INFO] Your service router loaded successfully.")
except Exception as e:
    import traceback
    print(f"[WARN] Your service module load failed: {e}")
    traceback.print_exc()
```

### 새로운 서비스/엔진 통합하기

#### `app/` 폴더 서비스 통합

1. `app/your-service/routes.py`에 라우터 정의
2. `main.py`에 import 및 등록:

```python
from app.your_service.routes import router as your_service_router

app.include_router(
    your_service_router,
    prefix="/api/service/your-service",
    tags=["your-service"]
)
```

#### `engine/` 폴더 엔진 통합

1. `engine/your-engine/api/routes.py`에 라우터 정의
2. `main.py`에 동적 로딩 및 등록:

```python
import importlib.util
from pathlib import Path

backend_path = Path(__file__).parent

your_engine_router = None
try:
    your_engine_path = backend_path / "engine" / "your-engine" / "api" / "routes.py"
    spec = importlib.util.spec_from_file_location("your_engine_routes", your_engine_path)
    your_engine_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(your_engine_module)
    your_engine_router = your_engine_module.router
    print("[INFO] Your engine router loaded successfully.")
except Exception as e:
    print("[WARN] Your engine module load failed:", e)
    your_engine_router = None

if your_engine_router is not None:
    app.include_router(your_engine_router, prefix="/engine/your-engine/api", tags=["your-engine"])
```

---

## 개발 가이드라인

### 1. 코드 스타일
- Python PEP 8 스타일 가이드 준수
- 타입 힌트 사용 권장
- Docstring 작성 (Google 스타일 권장)

### 2. 에러 처리
- FastAPI의 `HTTPException` 사용
- 적절한 HTTP 상태 코드 반환
- 에러 메시지는 명확하고 사용자 친화적으로

### 3. 테스트
- 각 서비스/엔진의 `tests/` 폴더에 테스트 코드 작성
- API 엔드포인트 테스트 포함

### 4. 문서화
- 각 서비스/엔진 폴더에 `README.md` 작성
- API 문서는 FastAPI의 자동 문서화 기능 활용 (`/docs`)

### 5. 환경 변수
- 민감한 정보는 환경 변수로 관리
- `.env` 파일은 `.gitignore`에 포함

### 6. 로깅
- 적절한 로깅 설정 추가 권장
- 디버그 정보는 개발 환경에서만 출력

## 참고 문서

- **데이터베이스 모델 가이드**: `backend/DB_GUIDE.md`
- **FastAPI 공식 문서**: https://fastapi.tiangolo.com/
- **SQLAlchemy 문서**: https://docs.sqlalchemy.org/

## 문의

프로젝트 관련 문의사항이 있으면 팀에 문의하세요.
