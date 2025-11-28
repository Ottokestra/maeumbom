# service/weather/service.py

"""
Weather service layer
"""

from typing import Optional
import os

import httpx

from .models import WeatherInfo
from .client import WeatherClient, WeatherApiError, to_weather_info


async def get_current_weather_info(city: str, country: str = "KR") -> WeatherInfo:
    client = WeatherClient(city=city, country=country)
    return await client.get_current_info()


async def get_current_weather_by_coords(
    lat: float,
    lon: float,
    units: str = "metric",
) -> WeatherInfo:
    """
    위도/경도 기반 현재 날씨 조회 (현재 위치용)

    Args:
        lat: 위도
        lon: 경도
        units: 온도 단위 ("metric"=섭씨)

    Returns:
        WeatherInfo 객체
    """
    api_key = os.getenv("OPENWEATHER_API_KEY")
    if not api_key:
        raise WeatherApiError(
            "OPENWEATHER_API_KEY 환경변수가 설정되지 않았습니다. "
            ".env 파일에 API 키를 추가해주세요."
        )

    base_url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": api_key,
        "units": units,
        "lang": "kr",
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            resp = await client.get(base_url, params=params)
            if resp.status_code != 200:
                raise WeatherApiError(
                    f"날씨 API 호출 실패 (status={resp.status_code}): {resp.text}"
                )
            raw = resp.json()
            # client.py 에서 만든 변환 함수 재사용
            return to_weather_info(raw)

        except httpx.TimeoutException:
            raise WeatherApiError("날씨 API 호출 타임아웃 (10초 초과)")
        except httpx.RequestError as e:
            raise WeatherApiError(f"날씨 API 네트워크 오류: {str(e)}")