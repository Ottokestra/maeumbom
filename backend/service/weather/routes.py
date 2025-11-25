# backend/service/weather/routes.py

from fastapi import APIRouter, HTTPException, Query
from .service import (
    get_current_weather_info,
    get_current_weather_by_coords,
)
from .models import WeatherInfo
from .client import WeatherApiError

# ⚠️ 여기에서 prefix를 이미 /api/service/weather 로 잡아준다
router = APIRouter(
    prefix="/api/service/weather",
    tags=["weather"],
)


@router.get("/current", response_model=WeatherInfo)
async def get_current_weather(
    city: str = Query(..., description="도시 이름 (예: Seoul)"),
    country: str = Query("KR", description="국가 코드 (기본값: KR)"),
):
    """
    도시 이름 기반 현재 날씨 조회
    """
    try:
        return await get_current_weather_info(city=city, country=country)
    except WeatherApiError as e:
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/current/location", response_model=WeatherInfo)
async def get_current_weather_by_location(
    lat: float = Query(..., description="위도"),
    lon: float = Query(..., description="경도"),
):
    """
    위도/경도 기반 현재 날씨 조회
    """
    try:
        return await get_current_weather_by_coords(lat=lat, lon=lon)
    except WeatherApiError as e:
        raise HTTPException(status_code=502, detail=str(e))
