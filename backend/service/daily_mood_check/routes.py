"""
일일 이미지 선택 감정 분석 API 라우터
"""
import sys
from pathlib import Path
from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import FileResponse
from typing import List

# 상대 import를 위한 경로 설정
current_dir = Path(__file__).parent
if str(current_dir) not in sys.path:
    sys.path.insert(0, str(current_dir))

# 절대 import로 변경
from models import (
    ImageSelectionRequest,
    ImageSelectionResponse,
    DailyCheckStatus,
    ImagesResponse,
    ImageInfo
)
from service import (
    get_daily_random_images,
    analyze_emotion_from_image,
    get_image_by_id,
    get_images_base_path,
    SENTIMENT_DESCRIPTIONS
)
from storage import get_storage

router = APIRouter()


@router.get("/status/{user_id}", response_model=DailyCheckStatus)
async def get_daily_check_status(user_id: int):
    """
    사용자의 일일 체크 상태 확인
    
    Args:
        user_id: 사용자 ID
        
    Returns:
        일일 체크 상태
    """
    storage = get_storage()
    status = storage.get_status(user_id)
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
async def select_image(request: ImageSelectionRequest):
    """
    이미지 선택 및 감정 분석 트리거
    
    Args:
        request: 이미지 선택 요청
        
    Returns:
        이미지 선택 응답 (감정 분석 결과 포함)
    """
    storage = get_storage()
    
    # 테스트 모드가 아닐 때만 일일 체크 제한 적용
    # storage.py의 is_checked_today()가 테스트 모드에서는 항상 False를 반환하므로
    # 여기서는 별도 체크 불필요 (테스트 모드에서는 제한 없음)
    if storage.is_checked_today(request.user_id):
        raise HTTPException(
            status_code=400,
            detail="오늘 이미 체크를 완료했습니다."
        )
    
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
    
    # 체크 완료 표시
    storage.mark_checked(request.user_id, request.image_id)
    
    return ImageSelectionResponse(
        success=True,
        selected_image=ImageInfo(**selected_image),
        emotion_result=emotion_result,
        message="이미지 선택이 완료되었습니다."
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

