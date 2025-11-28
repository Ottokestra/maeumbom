"""
Weather information models
"""

from typing import Optional
from pydantic import BaseModel, Field


class WeatherInfo(BaseModel):
    """
    날씨 정보 모델
    """
    location: str = Field(..., description="위치 문자열 (예: 'Seoul, KR')")
    condition: str = Field(..., description="날씨 상태 코드: clear, rain, clouds, snow, thunderstorm 등")
    description: str = Field(..., description="날씨 설명 (한국어, 예: '맑음', '비', '구름 조금')")
    temperature_c: float = Field(..., description="현재 기온 (섭씨)")
    is_rainy: bool = Field(..., description="비가 오는지 여부")
    humidity: Optional[int] = Field(None, description="습도 (0-100)")
    raw: Optional[dict] = Field(None, description="원본 API 응답 (디버깅용)")

    class Config:
        json_schema_extra = {
            "example": {
                "location": "Seoul, KR",
                "condition": "clear",
                "description": "맑음",
                "temperature_c": 15.5,
                "is_rainy": False,
                "humidity": 60,
                "raw": {}
            }
        }
