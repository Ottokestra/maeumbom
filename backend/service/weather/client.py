"""
OpenWeatherMap API client + 고수준 WeatherClient
"""

import os
from typing import Optional
import httpx

from .models import WeatherInfo


class WeatherApiError(Exception):
    """Weather API 호출 중 발생한 에러"""
    pass


async def _fetch_current_weather_raw(
    city: str,
    country: str = "KR",
    units: str = "metric",
) -> dict:
    """
    OpenWeatherMap API에서 원본 날씨 JSON을 그대로 가져오는 함수
    """
    api_key = os.getenv("OPENWEATHER_API_KEY")
    if not api_key:
        raise WeatherApiError(
            "OPENWEATHER_API_KEY 환경변수가 설정되지 않았습니다. "
            ".env 파일에 API 키를 추가해주세요."
        )

    base_url = "https://api.openweathermap.org/data/2.5/weather"

    params = {
        "q": f"{city},{country}",
        "appid": api_key,
        "units": units,
        "lang": "kr",  # 한국어 설명
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            resp = await client.get(base_url, params=params)

            if resp.status_code != 200:
                raise WeatherApiError(
                    f"날씨 API 호출 실패 (status={resp.status_code}): {resp.text}"
                )

            return resp.json()

        except httpx.TimeoutException:
            raise WeatherApiError("날씨 API 호출 타임아웃 (10초 초과)")
        except httpx.RequestError as e:
            raise WeatherApiError(f"날씨 API 네트워크 오류: {str(e)}")


def to_weather_info(raw: dict) -> WeatherInfo:
    """
    OpenWeatherMap 원본 JSON → WeatherInfo 모델 변환
    (__init__.py 에서 import 하는 함수)
    """
    # 날씨 상태
    weather_list = raw.get("weather") or []
    if weather_list:
        main = weather_list[0].get("main", "").lower()
        description = weather_list[0].get("description", "")
    else:
        main = ""
        description = ""

    # 기온 / 습도
    main_block = raw.get("main") or {}
    temp_c = float(main_block.get("temp", 0.0))
    humidity = main_block.get("humidity")

    # 위치
    name = raw.get("name") or ""
    country = (raw.get("sys") or {}).get("country") or ""
    location = f"{name}, {country}".strip(", ")

    # 비 오는지 여부
    is_rainy = any(
        key in main
        for key in ["rain", "drizzle", "thunder"]
    )

    return WeatherInfo(
        location=location or "Unknown",
        condition=main or "unknown",
        description=description or "",
        temperature_c=temp_c,
        is_rainy=is_rainy,
        humidity=humidity,
        raw=raw,
    )


class WeatherClient:
    """
    고수준 날씨 클라이언트
    - 내부에서는 _fetch_current_weather_raw 사용
    - 밖으로는 WeatherInfo 모델만 반환
    """

    def __init__(
        self,
        city: str,
        country: str = "KR",
        units: str = "metric",
    ):
        self.city = city
        self.country = country
        self.units = units

    async def get_current_info(self) -> WeatherInfo:
        """
        현재 날씨를 WeatherInfo 형태로 반환
        """
        raw = await _fetch_current_weather_raw(
            city=self.city,
            country=self.country,
            units=self.units,
        )
        return to_weather_info(raw)
