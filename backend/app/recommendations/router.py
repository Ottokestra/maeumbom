"""추천 API 라우터 정의."""

from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..db.database import get_db
from ..db.models import RoutineRecommendation
from ..dependencies import get_current_user
from .schemas import (
    ImageRequest,
    ImageResponse,
    MusicRequest,
    MusicResponse,
    QuoteRequest,
    QuoteResponse,
    RoutineRecommendationResponse,
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


@router.get(
    "/routine/latest",
    response_model=RoutineRecommendationResponse,
    summary="최근 루틴 추천 조회",
)
async def get_latest_routine_recommendation(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> RoutineRecommendationResponse:
    """
    사용자의 최근 루틴 추천 데이터를 조회합니다.
    
    - 하루 전(어제) 데이터 우선 조회
    - 없으면 가장 최근 데이터 반환
    - 데이터가 없으면 빈 routines 배열 반환
    """
    user_id = current_user["user_id"]
    
    # 어제 날짜
    yesterday = date.today() - timedelta(days=1)
    
    # 1. 어제 데이터 조회
    recommendation = (
        db.query(RoutineRecommendation)
        .filter(
            RoutineRecommendation.USER_ID == user_id,
            RoutineRecommendation.RECOMMENDATION_DATE == yesterday,
            RoutineRecommendation.IS_DELETED == False,
        )
        .first()
    )
    
    # 2. 어제 데이터가 없으면 가장 최근 데이터 조회
    if not recommendation:
        recommendation = (
            db.query(RoutineRecommendation)
            .filter(
                RoutineRecommendation.USER_ID == user_id,
                RoutineRecommendation.IS_DELETED == False,
            )
            .order_by(RoutineRecommendation.RECOMMENDATION_DATE.desc())
            .first()
        )
    
    # 3. 데이터가 없으면 빈 응답 반환
    if not recommendation:
        return RoutineRecommendationResponse(routines=[])
    
    # 4. 루틴 데이터 파싱
    routines = []
    if recommendation.ROUTINES:
        # ROUTINES는 JSON 형태로 저장되어 있음
        routines_data = recommendation.ROUTINES
        if isinstance(routines_data, list):
            for routine in routines_data:
                if isinstance(routine, dict):
                    routines.append({
                        "routine_id": routine.get("routine_id", ""),
                        "title": routine.get("title", ""),
                        "category": routine.get("category"),
                    })
    
    return RoutineRecommendationResponse(
        id=recommendation.ID,
        recommendation_date=recommendation.RECOMMENDATION_DATE,
        routines=routines,
        primary_emotion=recommendation.PRIMARY_EMOTION,
        sentiment_overall=recommendation.SENTIMENT_OVERALL,
        total_emotions=recommendation.TOTAL_EMOTIONS,
    )
