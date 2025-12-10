from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from app.db.database import get_db
from app.auth.dependencies import get_current_user
from app.db.models import User, EmotionAnalysis
from sqlalchemy import desc

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
