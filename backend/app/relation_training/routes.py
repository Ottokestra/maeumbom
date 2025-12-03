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
from .deep_agent_schemas import (
    GenerateScenarioRequest,
    GenerateScenarioResponse
)
from .deep_agent_service import DeepAgentService

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
        scenarios = get_scenario_list(db, category, user_id=current_user.ID)
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


@router.delete("/scenarios/{scenario_id}")
async def delete_scenario(
    scenario_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    시나리오 삭제 (테스트 데이터 정리용)
    
    해당 시나리오와 연관된 모든 데이터를 삭제합니다:
    - Scenario (시나리오 메타데이터)
    - ScenarioNodes (노드)
    - ScenarioOptions (선택지)
    - ScenarioResults (결과)
    
    Args:
        scenario_id: 삭제할 시나리오 ID
        current_user: 현재 로그인한 사용자 (인증 필수)
        db: Database session
        
    Returns:
        삭제 완료 메시지
        
    Example:
        DELETE /api/service/relation-training/scenarios/9
    """
    from app.db.models import Scenario
    
    # 시나리오 조회 (본인 소유 확인)
    scenario = db.query(Scenario).filter(
        Scenario.ID == scenario_id,
        Scenario.USER_ID == current_user.ID
    ).first()
    
    if not scenario:
        raise HTTPException(
            status_code=404,
            detail="시나리오를 찾을 수 없거나 삭제 권한이 없습니다."
        )
    
    # 시나리오 삭제 (cascade로 연관 데이터 자동 삭제)
    db.delete(scenario)
    db.commit()
    
    return {
        "success": True,
        "message": f"시나리오 ID {scenario_id}가 삭제되었습니다.",
        "deleted_scenario_id": scenario_id
    }


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


@router.post("/generate-scenario", response_model=GenerateScenarioResponse)
async def generate_scenario(
    request: GenerateScenarioRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Deep Agent Pipeline - 시나리오 자동 생성
    
    사용자 입력(Target, Topic)을 받아 GPT-4o-mini로 시나리오를 생성하고,
    FLUX.1-schnell로 17장의 이미지를 자동 생성한 후 DB에 저장합니다.
    
    Args:
        request: 생성 요청 (target, topic)
        current_user: 현재 로그인한 사용자 (인증 필수)
        db: Database session
    
    Returns:
        생성 결과 (scenario_id, status, image_count, folder_name)
    
    Example:
        POST /api/service/relation-training/generate-scenario
        {
            "target": "HUSBAND",
            "topic": "남편이 밥투정을 합니다"
        }
    
    Note:
        - 이미지 생성은 시간이 걸립니다 (8~34분)
        - USE_SKIP_IMAGES=true 설정 시 이미지 생성 스킵
    """
    try:
        # Create Deep Agent service
        service = DeepAgentService(db)
        
        # Run pipeline
        result = await service.generate_scenario(request, current_user.ID)
        
        return GenerateScenarioResponse(**result)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"시나리오 생성 실패: {str(e)}"
        )


@router.get("/images/{scenario_name}/{filename}")
async def get_image(
    scenario_name: str,
    filename: str
):
    """
    시나리오 이미지 파일 제공 (공용 시나리오)
    
    Args:
        scenario_name: 시나리오 폴더명 (예: 'husband_three_meals')
        filename: 이미지 파일명 (예: 'start.png', 'result_AAAA.png')
        
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


@router.delete("/scenarios/{scenario_id}")
async def delete_scenario(
    scenario_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    시나리오 삭제 (테스트 데이터 정리용)
    
    해당 시나리오와 연관된 모든 데이터를 삭제합니다:
    - Scenario (시나리오 메타데이터)
    - ScenarioNodes (노드)
    - ScenarioOptions (선택지)
    - ScenarioResults (결과)
    
    Args:
        scenario_id: 삭제할 시나리오 ID
        current_user: 현재 로그인한 사용자 (인증 필수)
        db: Database session
        
    Returns:
        삭제 완료 메시지
        
    Example:
        DELETE /api/service/relation-training/scenarios/9
    """
    from app.db.models import Scenario
    
    # 시나리오 조회
    scenario = db.query(Scenario).filter(
        Scenario.ID == scenario_id
    ).first()
    
    if not scenario:
        raise HTTPException(
            status_code=404,
            detail="시나리오를 찾을 수 없습니다."
        )
    
    # 공용 시나리오(USER_ID가 NULL) 삭제 방지
    if scenario.USER_ID is None:
        raise HTTPException(
            status_code=403,
            detail="공용 시나리오는 삭제할 수 없습니다."
        )
    
    # 본인 소유 확인
    if scenario.USER_ID != current_user.ID:
        raise HTTPException(
            status_code=403,
            detail="다른 사용자의 시나리오는 삭제할 수 없습니다."
        )
    
    # JSON 파일 삭제 (개인 시나리오만)
    import glob
    import os
    
    data_dir = Path(__file__).parent / "data" / str(scenario.USER_ID)
    if data_dir.exists():
        # 해당 시나리오의 JSON 파일 찾기 (제목 기반)
        # 파일명 패턴: {target}_{timestamp}.json
        json_files = list(data_dir.glob("*.json"))
        
        # 시나리오 제목으로 매칭되는 파일 찾기 (완벽한 매칭은 어려우므로 모든 파일 검사)
        for json_file in json_files:
            try:
                import json
                with open(json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    # 제목이 일치하는 파일 삭제
                    if data.get('scenario', {}).get('title') == scenario.TITLE:
                        json_file.unlink()
                        print(f"[Delete] JSON 파일 삭제: {json_file}")
                        break
            except Exception as e:
                print(f"[Delete] JSON 파일 확인 중 오류: {e}")
                continue
    
    # 시나리오 삭제 (cascade로 연관 데이터 자동 삭제)
    db.delete(scenario)
    db.commit()
    
    return {
        "success": True,
        "message": f"시나리오 ID {scenario_id}가 삭제되었습니다.",
        "deleted_scenario_id": scenario_id
    }


@router.get("/images/{user_id}/{scenario_name}/{filename}")
async def get_user_image(
    user_id: int,
    scenario_name: str,
    filename: str
):
    """
    시나리오 이미지 파일 제공 (사용자별 시나리오)
    
    Deep Agent로 생성된 사용자별 시나리오 이미지를 제공합니다.
    
    Args:
        user_id: 사용자 ID
        scenario_name: 시나리오 폴더명 (예: 'husband_20231215_143022')
        filename: 이미지 파일명 (예: 'start.png', 'result_AAAA.png')
        
    Returns:
        이미지 파일
        
    Example:
        GET /api/service/relation-training/images/123/husband_20231215_143022/start.png
        GET /api/service/relation-training/images/123/husband_20231215_143022/result_AAAA.png
    """
    try:
        # 경로 보안 검증 (상위 디렉토리 접근 방지)
        if '..' in scenario_name or '..' in filename:
            raise HTTPException(status_code=400, detail="Invalid path")
        
        image_path = IMAGES_DIR / str(user_id) / scenario_name / filename
        
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


@router.delete("/scenarios/{scenario_id}")
async def delete_scenario(
    scenario_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    시나리오 삭제 (테스트 데이터 정리용)
    
    해당 시나리오와 연관된 모든 데이터를 삭제합니다:
    - Scenario (시나리오 메타데이터)
    - ScenarioNodes (노드)
    - ScenarioOptions (선택지)
    - ScenarioResults (결과)
    
    Args:
        scenario_id: 삭제할 시나리오 ID
        current_user: 현재 로그인한 사용자 (인증 필수)
        db: Database session
        
    Returns:
        삭제 완료 메시지
        
    Example:
        DELETE /api/service/relation-training/scenarios/9
    """
    from app.db.models import Scenario
    
    # 시나리오 조회 (본인 소유 확인)
    scenario = db.query(Scenario).filter(
        Scenario.ID == scenario_id,
        Scenario.USER_ID == current_user.ID
    ).first()
    
    if not scenario:
        raise HTTPException(
            status_code=404,
            detail="시나리오를 찾을 수 없거나 삭제 권한이 없습니다."
        )
    
    # 시나리오 삭제 (cascade로 연관 데이터 자동 삭제)
    db.delete(scenario)
    db.commit()
    
    return {
        "success": True,
        "message": f"시나리오 ID {scenario_id}가 삭제되었습니다.",
        "deleted_scenario_id": scenario_id
    }

