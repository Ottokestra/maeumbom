"""
API routes for relation training service
Interactive scenario endpoints with authentication
"""
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import Optional
from pathlib import Path

from app.db.database import get_db
from app.auth.dependencies import get_current_user
from app.auth.models import User

from .schemas import (
    ScenarioListResponse,
    ScenarioStartResponse,
    ProgressRequest,
    ProgressResponse
)
from .service import (
    get_scenario_list,
    get_first_node,
    process_progress
)

router = APIRouter()

# 이미지 파일 경로
IMAGES_DIR = Path(__file__).parent / "images"


@router.get("/scenarios", response_model=ScenarioListResponse)
async def list_scenarios(
    category: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    시나리오 목록 조회
    
    Args:
        category: 카테고리 필터 (TRAINING 또는 DRAMA, 선택사항)
        current_user: 현재 로그인한 사용자 (인증 필수)
        db: Database session
        
    Returns:
        시나리오 목록
        
    Example:
        GET /api/service/relation-training/scenarios
        GET /api/service/relation-training/scenarios?category=TRAINING
    """
    try:
        scenarios = get_scenario_list(db, category)
        return ScenarioListResponse(
            scenarios=scenarios,
            total=len(scenarios)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/scenarios/{scenario_id}/start", response_model=ScenarioStartResponse)
async def start_scenario(
    scenario_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    시나리오 시작 - 첫 번째 노드 반환
    
    Args:
        scenario_id: 시나리오 ID
        current_user: 현재 로그인한 사용자 (인증 필수)
        db: Database session
        
    Returns:
        첫 번째 노드 정보 (상황 텍스트 및 선택지 포함)
        
    Example:
        GET /api/service/relation-training/scenarios/1/start
    """
    try:
        result = get_first_node(db, scenario_id)
        return ScenarioStartResponse(**result)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/progress", response_model=ProgressResponse)
async def progress_scenario(
    request: ProgressRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    시나리오 진행 처리
    
    사용자가 선택지를 선택하면 다음 노드 또는 최종 결과를 반환합니다.
    
    Args:
        request: 진행 요청 (현재 노드 ID, 선택한 옵션 코드, 현재 경로)
        current_user: 현재 로그인한 사용자 (인증 필수)
        db: Database session
        
    Returns:
        다음 노드 정보 또는 최종 결과
        - is_finished=False: 다음 노드 정보 반환
        - is_finished=True: 최종 결과 반환 (드라마의 경우 통계 포함)
        
    Example:
        POST /api/service/relation-training/progress
        {
            "scenario_id": 1,
            "current_node_id": 1,
            "selected_option_code": "A",
            "current_path": "A"
        }
    """
    try:
        result = process_progress(
            db=db,
            user_id=current_user.ID,
            scenario_id=request.scenario_id,
            current_node_id=request.current_node_id,
            selected_option_code=request.selected_option_code,
            current_path=request.current_path
        )
        return ProgressResponse(**result)
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/images/{scenario_name}/{filename}")
async def get_image(
    scenario_name: str,
    filename: str
):
    """
    시나리오 이미지 파일 제공
    
    Args:
        scenario_name: 시나리오 폴더명 (예: 'husband_three_meals')
        filename: 이미지 파일명 (예: 'start.png', 'result_AAAA.png')
        current_user: 현재 로그인한 사용자 (인증 필수)
        
    Returns:
        이미지 파일
        
    Example:
        GET /api/service/relation-training/images/husband_three_meals/start.png
        GET /api/service/relation-training/images/husband_three_meals/result_AAAA.png
    """
    try:
        # 경로 보안 검증 (상위 디렉토리 접근 방지)
        if '..' in scenario_name or '..' in filename:
            raise HTTPException(status_code=400, detail="Invalid path")
        
        image_path = IMAGES_DIR / scenario_name / filename
        
        if not image_path.exists():
            raise HTTPException(status_code=404, detail="Image not found")
        
        # 이미지 디렉토리 내에 있는지 확인
        try:
            image_path.resolve().relative_to(IMAGES_DIR.resolve())
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid path")
        
        return FileResponse(
            path=str(image_path),
            filename=filename,
            media_type="image/png"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

