"""
일일 이미지 선택 감정 분석 API 라우터
"""
import sys
from pathlib import Path
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import FileResponse
from typing import List
from sqlalchemy.orm import Session

# Backend root 경로 추가 (app.auth 모듈 import용)
backend_path = Path(__file__).parent.parent.parent
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

# importlib를 사용하여 같은 디렉토리의 모듈들을 직접 로드 (이름 충돌 방지)
import importlib.util
current_dir = Path(__file__).parent

# models import
models_path = current_dir / "models.py"
spec = importlib.util.spec_from_file_location("daily_mood_check_models", models_path)
models_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(models_module)
ImageSelectionRequest = models_module.ImageSelectionRequest
ImageSelectionResponse = models_module.ImageSelectionResponse
DailyCheckStatus = models_module.DailyCheckStatus
ImagesResponse = models_module.ImagesResponse
ImageInfo = models_module.ImageInfo

# service import
service_path = current_dir / "service.py"
spec = importlib.util.spec_from_file_location("daily_mood_check_service", service_path)
service_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(service_module)
get_daily_random_images = service_module.get_daily_random_images
analyze_emotion_from_image = service_module.analyze_emotion_from_image
get_image_by_id = service_module.get_image_by_id
get_images_base_path = service_module.get_images_base_path
SENTIMENT_DESCRIPTIONS = service_module.SENTIMENT_DESCRIPTIONS
save_daily_selection = service_module.save_daily_selection
get_user_daily_status = service_module.get_user_daily_status
is_user_checked_today = service_module.is_user_checked_today

# storage import
storage_path = current_dir / "storage.py"
spec = importlib.util.spec_from_file_location("daily_mood_check_storage", storage_path)
storage_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(storage_module)
get_storage = storage_module.get_storage
from app.auth.dependencies import get_current_user
from app.auth.models import User
from app.db.database import get_db

router = APIRouter()


@router.get("/status", response_model=DailyCheckStatus)
async def get_daily_check_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    현재 로그인한 사용자의 일일 체크 상태 확인
    
    Returns:
        일일 체크 상태
    """
    # DB에서 상태 조회 (우선)
    status = get_user_daily_status(db, current_user.id)
    
    # DB에 없으면 기존 JSON 파일 저장소에서 조회 (하위 호환성)
    if not status.get("completed"):
        storage = get_storage()
        json_status = storage.get_status(current_user.id)
        if json_status.get("completed"):
            status = json_status
    
    return DailyCheckStatus(**status)


@router.get("/images", response_model=ImagesResponse)
async def get_daily_images():
    """
    오늘의 랜덤 이미지 목록 반환 (부정/중립/긍정 각 1개씩)
    
    Returns:
        이미지 목록 (3개)
    """
    images = get_daily_random_images()
    
    # ImageInfo 객체로 변환
    image_infos = [
        ImageInfo(**img) for img in images if img.get("filename") is not None
    ]
    
    return ImagesResponse(images=image_infos)


@router.post("/select", response_model=ImageSelectionResponse)
async def select_image(
    request: ImageSelectionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    이미지 선택 및 감정 분석 트리거
    
    Args:
        request: 이미지 선택 요청 (user_id는 무시되고 현재 로그인한 사용자 사용)
        current_user: 현재 로그인한 사용자 (인증 필수)
        db: Database session
        
    Returns:
        이미지 선택 응답 (감정 분석 결과 포함, is_update 플래그 포함)
    """
    user_id = current_user.id  # 인증된 사용자 ID 사용
    
    # Check if user already checked today (for is_update flag)
    is_update = is_user_checked_today(db, user_id)
    
    # 프론트엔드에서 전송한 filename과 sentiment가 있으면 우선 사용
    if request.filename and request.sentiment:
        # 전송받은 정보로 직접 이미지 정보 구성
        selected_image = {
            "id": request.image_id,
            "sentiment": request.sentiment,
            "filename": request.filename,
            "description": "",  # 감정 분석에 사용될 설명은 나중에 설정
            "url": f"/api/service/daily-mood-check/images/{request.sentiment}/{request.filename}"
        }
        
        # 이미지 파일이 실제로 존재하는지 확인
        base_path = get_images_base_path()
        image_path = base_path / request.sentiment / request.filename
        if not image_path.exists() or not image_path.is_file():
            raise HTTPException(
                status_code=404,
                detail=f"이미지 파일을 찾을 수 없습니다: {request.sentiment}/{request.filename}"
            )
        
        # 설명은 감정 분석 시 사용되므로, sentiment 기반 기본 설명 사용
        descriptions = SENTIMENT_DESCRIPTIONS.get(request.sentiment, [""])
        selected_image["description"] = descriptions[0] if descriptions else ""
    else:
        # 기존 방식: 오늘의 이미지 목록 가져오기
        daily_images = get_daily_random_images()
        
        # 선택한 이미지 찾기
        selected_image = get_image_by_id(request.image_id, daily_images)
        
        if not selected_image:
            raise HTTPException(
                status_code=404,
                detail=f"이미지 ID {request.image_id}를 찾을 수 없습니다."
            )
    
    # 감정 분석 수행
    emotion_result = analyze_emotion_from_image(selected_image)
    
    # DB에 저장 (upsert: 존재하면 update, 없으면 insert)
    save_daily_selection(
        db=db,
        user_id=user_id,
        image_id=request.image_id,
        sentiment=selected_image["sentiment"],
        filename=selected_image["filename"],
        description=selected_image.get("description"),
        emotion_result=emotion_result
    )
    
    # 기존 JSON 파일 저장소에도 저장 (하위 호환성)
    storage = get_storage()
    storage.mark_checked(user_id, request.image_id)
    
    return ImageSelectionResponse(
        success=True,
        selected_image=ImageInfo(**selected_image),
        emotion_result=emotion_result,
        message="이미지 선택이 완료되었습니다." if not is_update else "오늘의 기분이 변경되었습니다.",
        is_update=is_update
    )


@router.get("/images/{sentiment}/{filename}")
async def get_image_file(sentiment: str, filename: str):
    """
    이미지 파일 직접 서빙
    
    Args:
        sentiment: 감정 분류 (negative, neutral, positive)
        filename: 이미지 파일명
        
    Returns:
        이미지 파일
    """
    if sentiment not in ["negative", "neutral", "positive"]:
        raise HTTPException(status_code=400, detail="Invalid sentiment")
    
    base_path = get_images_base_path()
    image_path = base_path / sentiment / filename
    
    if not image_path.exists() or not image_path.is_file():
        raise HTTPException(status_code=404, detail="Image not found")
    
    # MIME 타입 결정
    mime_type = "image/jpeg"
    if filename.lower().endswith('.png'):
        mime_type = "image/png"
    elif filename.lower().endswith('.gif'):
        mime_type = "image/gif"
    elif filename.lower().endswith('.webp'):
        mime_type = "image/webp"
    
    return FileResponse(
        path=str(image_path),
        media_type=mime_type,
        filename=filename
    )

