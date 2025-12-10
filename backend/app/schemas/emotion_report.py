from datetime import date
from pydantic import BaseModel
from typing import List, Optional


class EmotionDaySummary(BaseModel):
    date: date
    weekday_label: str  # "월", "화" ...
    character_code: str  # "PEACH_WORRY"
    main_emotion: Optional[str] = None


class WeeklyEmotionReport(BaseModel):
    has_data: bool = True
    start_date: date
    end_date: date
    title: str            # "금주의 너는 '걱정이 복숭아'"
    temperature: int      # 0~100
    main_character_code: str
    main_emotion: Optional[str] = None
    coach_message: str    # 딥에이전트 멘트
    days: List[EmotionDaySummary]
