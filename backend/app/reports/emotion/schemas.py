from datetime import date
from typing import List, Optional

from pydantic import BaseModel


class EmotionDailyScore(BaseModel):
    date: date
    main_emotion: str  # e.g. "기쁨", "불안", "우울"
    score: float  # 0.0 ~ 1.0 (강도)
    subtitle: Optional[str] = None  # “일이 많았지만 잘 버텼어요” 같은 한줄 메모


class EmotionCharacterBubble(BaseModel):
    character_name: str  # "봄이"
    mood: str  # "cheerful", "worried" 등
    message: str  # 말풍선 안에 들어갈 대사


class EmotionRecommendation(BaseModel):
    type: str  # "routine", "emotion", "relationship" 등
    title: str  # "이번 주 나에게 필요한 한 마디"
    content: str  # 실제 추천 내용 텍스트


class WeeklyEmotionReport(BaseModel):
    user_id: int
    week_start: date
    week_end: date
    summary_title: str
    summary_text: str
    dominant_emotion: str
    character_bubble: EmotionCharacterBubble
    daily_scores: List[EmotionDailyScore]
    recommendations: List[EmotionRecommendation]
