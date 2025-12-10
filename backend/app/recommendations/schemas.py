"""추천 API 스키마 정의."""

from typing import List, Literal, Optional

from pydantic import BaseModel, HttpUrl


class QuoteRequest(BaseModel):
    """명언 추천 요청 본문."""

    emotion_label: str
    language: Literal["ko", "en"] = "ko"


class QuoteItem(BaseModel):
    """명언 아이템."""

    text: str
    source: str


class QuoteResponse(BaseModel):
    """명언 추천 응답."""

    quotes: List[QuoteItem]


class MusicRequest(BaseModel):
    """음악 추천 요청 본문."""

    emotion_label: str
    duration: int = 10


class MusicResponse(BaseModel):
    """음악 추천 응답."""

    audio_url: HttpUrl


class ImageRequest(BaseModel):
    """이미지 추천/생성 요청 본문."""

    prompt: str
    emotion_label: Optional[str] = None


class ImageResponse(BaseModel):
    """이미지 추천 응답."""

    image_url: HttpUrl
