"""추천 API 라우터 정의."""

from fastapi import APIRouter, HTTPException

from .schemas import (
    ImageRequest,
    ImageResponse,
    MusicRequest,
    MusicResponse,
    QuoteRequest,
    QuoteResponse,
)
from .services import generate_image, generate_quotes, recommend_music

router = APIRouter(prefix="/api/v1/recommendations")


@router.post("/quote", response_model=QuoteResponse, summary="감정 기반 명언 추천")
async def recommend_quote(request: QuoteRequest) -> QuoteResponse:
    """현재 감정 상태에 맞는 명언을 추천한다."""

    if not request.emotion_label.strip():
        raise HTTPException(
            status_code=400,
            detail={"detail": "emotion_label은 비어 있을 수 없습니다.", "code": "INVALID_EMOTION"},
        )

    quotes = await generate_quotes(request.emotion_label, request.language)
    return QuoteResponse(quotes=quotes)


@router.post("/music", response_model=MusicResponse, summary="감정 기반 음악 추천")
async def recommend_music_clip(request: MusicRequest) -> MusicResponse:
    """감정에 맞춘 음악 클립을 추천한다."""

    if not request.emotion_label.strip():
        raise HTTPException(
            status_code=400,
            detail={"detail": "emotion_label은 비어 있을 수 없습니다.", "code": "INVALID_EMOTION"},
        )

    audio_url = await recommend_music(request.emotion_label, request.duration)
    return MusicResponse(audio_url=audio_url)


@router.post("/image", response_model=ImageResponse, summary="감정 기반 이미지 생성")
async def generate_emotion_image(request: ImageRequest) -> ImageResponse:
    """감정 또는 프롬프트 기반 위로 이미지를 생성한다."""

    if not request.prompt.strip():
        raise HTTPException(
            status_code=400,
            detail={"detail": "prompt는 비어 있을 수 없습니다.", "code": "PROMPT_REQUIRED"},
        )

    image_url = await generate_image(request.prompt, request.emotion_label)
    return ImageResponse(image_url=image_url)
