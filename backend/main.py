"""
팀 프로젝트 메인 FastAPI 애플리케이션
"""
import sys
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 하이픈이 있는 폴더명을 import하기 위해 경로 추가
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

# emotion-analysis 폴더를 import하기 위해 importlib 사용
import importlib.util
emotion_analysis_path = backend_path / "engine" / "emotion-analysis" / "api" / "routes.py"
spec = importlib.util.spec_from_file_location("emotion_routes", emotion_analysis_path)
emotion_routes = importlib.util.module_from_spec(spec)
spec.loader.exec_module(emotion_routes)
emotion_router = emotion_routes.router

# Create FastAPI app
app = FastAPI(
    title="Team Project API",
    description="팀 프로젝트 통합 API 서비스",
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

# Include emotion analysis routes
app.include_router(emotion_router, prefix="/emotion/api", tags=["emotion"])
# 하위 호환성을 위해 /api 경로도 지원
app.include_router(emotion_router, prefix="/api", tags=["emotion"])


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Team Project API",
        "version": "1.0.0",
        "docs": "/docs",
        "modules": {
            "emotion_analysis": "/emotion/api"
        }
    }


if __name__ == "__main__":
    import uvicorn
    print("=" * 50)
    print("팀 프로젝트 API 서버 시작")
    print("=" * 50)
    print("\n서버 정보:")
    print("  - URL: http://localhost:8000")
    print("  - API 문서: http://localhost:8000/docs")
    print("  - 감정 분석: http://localhost:8000/emotion/api")
    print("\n최초 실행 시:")
    print("  1. 서버 시작 후 http://localhost:8000/docs 접속")
    print("  2. POST /emotion/api/init 엔드포인트 실행하여 벡터 DB 초기화")
    print("\n" + "=" * 50 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)

