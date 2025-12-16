"""
Routine Recommendations API Routes
"""

from datetime import date, datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import User, RoutineRecommendation
from app.auth.dependencies import get_current_user
from .schemas import RoutineRecommendationsListResponse, RoutineRecommendationResponse


router = APIRouter(prefix="/api/routine-recommendations", tags=["Routine Recommendations"])


@router.get("/list", response_model=RoutineRecommendationsListResponse)
async def list_routine_recommendations(
    start_date: Optional[date] = Query(None, description="시작 날짜 (YYYY-MM-DD)"),
    end_date: Optional[date] = Query(None, description="종료 날짜 (YYYY-MM-DD)"),
    limit: int = Query(7, le=30, description="조회할 최대 개수"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    루틴 추천 목록 조회
    
    Args:
        start_date: 시작 날짜 (없으면 최근 7일)
        end_date: 종료 날짜 (없으면 오늘)
        limit: 최대 조회 개수 (기본 7, 최대 30)
        db: Database session
        current_user: Current authenticated user
    
    Returns:
        루틴 추천 목록
    """
    try:
        # 기본 날짜 설정
        if end_date is None:
            end_date = datetime.now().date()
        if start_date is None:
            start_date = end_date - timedelta(days=limit - 1)
        
        # 쿼리 실행
        query = db.query(RoutineRecommendation).filter(
            RoutineRecommendation.USER_ID == current_user.ID,
            RoutineRecommendation.IS_DELETED == False,
            RoutineRecommendation.RECOMMENDATION_DATE >= start_date,
            RoutineRecommendation.RECOMMENDATION_DATE <= end_date,
        ).order_by(RoutineRecommendation.RECOMMENDATION_DATE.desc()).limit(limit)
        
        recommendations = query.all()
        
        return RoutineRecommendationsListResponse(
            recommendations=[
                RoutineRecommendationResponse.model_validate(rec)
                for rec in recommendations
            ],
            total_count=len(recommendations),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"조회 실패: {str(e)}")


@router.get("/health")
async def health_check():
    """헬스 체크"""
    return {"status": "ok", "service": "routine-recommendations"}

