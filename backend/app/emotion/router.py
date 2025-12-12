"""감정 분석 API 라우터 정의."""

from fastapi import APIRouter, File, HTTPException, UploadFile

from .schemas import (
    AudioEmotionResponse,
    EmotionScores,
    ImageEmotionResponse,
    TextEmotionRequest,
    TextEmotionResponse,
)
from .services import (
    analyze_image_emotion,
    analyze_text_emotion,
    stt_transcribe_audio,
    summarize_text,
)

router = APIRouter()


@router.post("/api/v1/emotion/image", response_model=ImageEmotionResponse, summary="이미지 감정 분석")
async def analyze_image(file: UploadFile = File(...)) -> ImageEmotionResponse:
    """얼굴 이미지를 업로드하여 감정을 분석한다."""

    if file is None or not file.filename:
        raise HTTPException(
            status_code=400,
            detail={"detail": "파일이 업로드되지 않았습니다.", "code": "FILE_REQUIRED"},
        )

    result = await analyze_image_emotion(file)
    return ImageEmotionResponse(
        emotion_label=result["emotion_label"],
        emotion_index=result["emotion_index"],
        scores=EmotionScores(**result["scores"]),
    )


@router.post(
    "/api/v1/emotion/audio",
    response_model=AudioEmotionResponse,
    summary="음성 감정 분석 (STT 포함)",
)
async def analyze_audio(file: UploadFile = File(...)) -> AudioEmotionResponse:
    """음성을 업로드하여 STT, 요약, 감정 분석을 수행한다."""

    if file is None or not file.filename:
        raise HTTPException(
            status_code=400,
            detail={"detail": "파일이 업로드되지 않았습니다.", "code": "FILE_REQUIRED"},
        )

    try:
        transcript = await stt_transcribe_audio(file)
    except Exception:
        raise HTTPException(
            status_code=500,
            detail={"detail": "STT 처리 중 오류가 발생했습니다.", "code": "STT_ERROR"},
        )

    summary = await summarize_text(transcript)
    emotion_result = await analyze_text_emotion(transcript)

    return AudioEmotionResponse(
        transcript=transcript,
        summary=summary,
        emotion_label=emotion_result["emotion_label"],
        scores=EmotionScores(**emotion_result["scores"]),
    )


@router.post(
    "/api/v1/emotion/text",
    response_model=TextEmotionResponse,
    summary="텍스트 감정 분석",
)
async def analyze_text(request: TextEmotionRequest) -> TextEmotionResponse:
    """텍스트만으로 감정을 분석한다."""

    if not request.text.strip():
        raise HTTPException(
            status_code=400,
            detail={"detail": "텍스트가 비어 있습니다.", "code": "TEXT_REQUIRED"},
        )

    result = await analyze_text_emotion(request.text)
    return TextEmotionResponse(
        emotion_label=result["emotion_label"],
        scores=EmotionScores(**result["scores"]),
    )
