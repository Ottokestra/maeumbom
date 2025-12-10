"""헬스 체크 엔드포인트를 제공하는 라우터 모듈."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/api/health", summary="헬스 체크")
async def health_check() -> dict:
    """서버 상태를 확인하기 위한 헬스 체크 엔드포인트."""
    return {"status": "ok", "version": "v1"}
