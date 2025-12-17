from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date
from app.db.database import get_db
from app.auth.dependencies import get_current_user
from app.db.models import User, EmotionAnalysis, DailyTargetEvent
from sqlalchemy import desc, and_

router = APIRouter()

@router.get("/emotion-history")
async def get_emotion_history(
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    대시보드용 감정 분석 히스토리 조회
    """
    try:
        # 최근 기록부터 조회
        emotions = db.query(EmotionAnalysis).filter(
            EmotionAnalysis.USER_ID == current_user.ID
        ).order_by(
            desc(EmotionAnalysis.CREATED_AT)
        ).limit(limit).all()
        
        return emotions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/daily-emotions")
async def get_daily_emotions(
    start_date: str = Query(..., description="시작 날짜 (YYYY-MM-DD)"),
    end_date: str = Query(..., description="종료 날짜 (YYYY-MM-DD)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    일간 대표 감정 조회
    TB_DAILY_TARGET_EVENTS의 PRIMARY_EMOTION 반환
    
    Args:
        start_date: 시작 날짜 (YYYY-MM-DD)
        end_date: 종료 날짜 (YYYY-MM-DD)
        
    Returns:
        List of daily emotions with date and primary_emotion
    """
    try:
        # 날짜 파싱
        start = datetime.strptime(start_date, "%Y-%m-%d").date()
        end = datetime.strptime(end_date, "%Y-%m-%d").date()
        
        # 일간 이벤트 조회 (PRIMARY_EMOTION이 있는 것만)
        daily_events = db.query(DailyTargetEvent).filter(
            and_(
                DailyTargetEvent.USER_ID == current_user.ID,
                DailyTargetEvent.EVENT_DATE >= start,
                DailyTargetEvent.EVENT_DATE <= end,
                DailyTargetEvent.IS_DELETED == False,
                DailyTargetEvent.PRIMARY_EMOTION.isnot(None)
            )
        ).order_by(DailyTargetEvent.EVENT_DATE).all()
        
        # 응답 포맷
        result = []
        for event in daily_events:
            result.append({
                "date": event.EVENT_DATE.isoformat(),
                "primary_emotion": event.PRIMARY_EMOTION
            })
        
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid date format: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
