from typing import List, Optional

from pydantic import BaseModel


class WeeklyEmotionItem(BaseModel):
    day: str
    emoji: str
    code: str


class WeeklyEmotionReport(BaseModel):
    week_label: str
    title: str
    temperature: int
    temperature_label: str
    main_character_code: str
    main_character_emoji: str
    main_character_name: str
    weekly_emotions: List[WeeklyEmotionItem]
    suggestion: Optional[str] = None

    class Config:
        from_attributes = True
