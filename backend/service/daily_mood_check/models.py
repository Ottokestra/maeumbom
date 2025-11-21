"""
Pydantic models for daily mood check API
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ImageInfo(BaseModel):
    """이미지 정보"""
    id: int = Field(..., description="이미지 ID")
    sentiment: str = Field(..., description="감정 분류: negative, neutral, positive")
    filename: str = Field(..., description="이미지 파일명")
    description: str = Field(..., description="감정 분석에 사용될 텍스트 설명")
    url: str = Field(..., description="이미지 URL")


class ImageSelectionRequest(BaseModel):
    """이미지 선택 요청"""
    user_id: int = Field(..., description="사용자 ID")
    image_id: int = Field(..., description="선택한 이미지 ID")


class ImageSelectionResponse(BaseModel):
    """이미지 선택 응답"""
    success: bool = Field(..., description="성공 여부")
    selected_image: ImageInfo = Field(..., description="선택한 이미지 정보")
    emotion_result: Optional[dict] = Field(None, description="감정 분석 결과")
    message: str = Field(..., description="응답 메시지")


class DailyCheckStatus(BaseModel):
    """일일 체크 상태"""
    user_id: int = Field(..., description="사용자 ID")
    completed: bool = Field(..., description="오늘 체크 완료 여부")
    last_check_date: Optional[str] = Field(None, description="마지막 체크 날짜 (YYYY-MM-DD)")
    selected_image_id: Optional[int] = Field(None, description="선택한 이미지 ID")


class ImagesResponse(BaseModel):
    """이미지 목록 응답"""
    images: List[ImageInfo] = Field(..., description="이미지 목록 (부정/중립/긍정 각 1개씩)")

