# Engine 개발 가이드

이 문서는 `backend/engine` 폴더에 새로운 기능을 추가하는 개발자를 위한 가이드입니다.

**중요**: 이 가이드를 Cursor AI 프롬프트에 포함하면, 동일한 프로젝트 구조와 코드 스타일로 새로운 엔진을 생성할 수 있습니다.

## 개발 환경

### 필수 요구사항
- **Python**: 3.11
- **프레임워크**: FastAPI
- **가상환경**: 각 엔진 모듈별로 독립적인 가상환경 사용 권장

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
backend/engine/
├── emotion-analysis/     # 감정 분석 엔진 (예시)
│   ├── api/             # FastAPI 애플리케이션
│   │   ├── main.py      # FastAPI 앱 진입점
│   │   ├── routes.py    # API 라우트 정의
│   │   └── models.py    # Pydantic 모델 정의
│   ├── src/             # 핵심 로직
│   ├── data/            # 데이터 파일
│   ├── tests/           # 테스트 코드
│   └── venv/           # 가상환경
├── speech-to-text/      # 음성 인식 엔진 (예시)
└── your-new-engine/     # 새로운 엔진 (여기에 추가)
```

## 새로운 엔진 생성 가이드

### 1. 폴더 구조 생성

새로운 엔진을 추가할 때는 다음 **기본 구조**를 참고하되, 각 엔진의 특성에 맞게 조정할 수 있습니다:

**기본 구조 (최소 필수 요소):**
```
your-new-engine/
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

**원칙**: FastAPI 앱(`api/main.py`, `api/routes.py`, `api/models.py`)은 필수이며, 나머지는 엔진의 특성에 맞게 구성하세요.

### 2. FastAPI 애플리케이션 기본 구조

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

### 3. 의존성 관리

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

### 4. 환경 변수 설정

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
- 각 엔진의 `tests/` 폴더에 테스트 코드 작성
- API 엔드포인트 테스트 포함

### 4. 문서화
- 각 엔진 폴더에 `README.md` 작성
- API 문서는 FastAPI의 자동 문서화 기능 활용 (`/docs`)

## 서버 실행

### 개발 모드
```bash
cd your-new-engine
python api/main.py
```

또는 uvicorn을 직접 사용:
```bash
python -m uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

### 프로덕션 모드
```bash
uvicorn api.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## API 문서 확인

서버 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 참고사항

1. **포트 충돌**: 각 엔진은 다른 포트를 사용하거나, API 게이트웨이를 통해 라우팅
2. **CORS 설정**: 프론트엔드 개발 서버 주소에 맞게 CORS 설정
3. **환경 변수**: 민감한 정보는 환경 변수로 관리
4. **로깅**: 적절한 로깅 설정 추가 권장

## Cursor AI 사용 시

이 가이드를 Cursor AI 프롬프트에 포함하고 다음과 같이 요청하면, 기본 구조로 프로젝트가 생성됩니다:

**기본 요청 예시:**
```
"backend/engine/DEVELOPER_GUIDE.md를 참고하여 
backend/engine/my-new-engine 폴더에 새로운 FastAPI 엔진을 만들어줘.
엔진 이름은 'my-new-engine'이고, /api/process 엔드포인트를 만들어줘."
```

**구조 커스터마이징 요청 예시:**
```
"backend/engine/DEVELOPER_GUIDE.md의 기본 구조를 참고하되,
이 엔진은 데이터베이스가 필요하므로 data/ 폴더를 추가하고,
설정 파일을 위해 config.yaml을 만들어줘."
```

**중요**: 가이드는 기본 구조를 제공하지만, 각 엔진의 특성에 맞게 구조를 조정하는 것이 좋습니다.

## 예시 프로젝트 참고

기존 엔진들을 참고하여 구조를 파악할 수 있습니다:
- `emotion-analysis/`: 감정 분석 엔진 예시
- `speech-to-text/`: 음성 인식 엔진 예시

**참고**: 
- 기존 프로젝트의 `routes.py`는 복잡한 importlib.util 패턴을 사용하지만, 
  새 프로젝트는 일반적인 Python import (`from .models import ...`)를 사용해도 됩니다.
- 각 엔진의 기능이 다르므로, 구조도 달라질 수 있습니다. 
  기본 구조를 참고하되, 엔진의 특성에 맞게 폴더와 파일을 추가/수정하세요.

## 문의

프로젝트 관련 문의사항이 있으면 팀에 문의하세요.

