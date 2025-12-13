"""
요청/응답 스키마
Pydantic models for request/response validation
"""
from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import List, Optional, Dict, Any


class AnalyzeDailyRequest(BaseModel):
    """일일 분석 요청"""

    target_date: date = Field(..., description="분석할 날짜 (YYYY-MM-DD)")


class AnalyzeWeeklyRequest(BaseModel):
    """주간 분석 요청"""

    week_start: date = Field(..., description="주 시작일 (월요일, YYYY-MM-DD)")


class DailyEventResponse(BaseModel):
    """일간 이벤트 응답"""

    id: int
    user_id: int
    event_date: date
    target_type: str
    event_summary: str
    event_time: Optional[datetime] = None
    importance: int
    is_future_event: bool
    tags: List[str] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class WeeklyEventResponse(BaseModel):
    """주간 이벤트 응답"""

    id: int
    user_id: int
    week_start: date
    week_end: date
    target_type: str
    events_summary: List[Dict[str, Any]] = []
    total_events: int
    tags: List[str] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class AnalyzeDailyResponse(BaseModel):
    """일일 분석 응답"""

    analyzed_date: date
    events_count: int
    events: List[DailyEventResponse]


class AnalyzeWeeklyResponse(BaseModel):
    """주간 분석 응답"""

    week_start: date
    week_end: date
    summaries_count: int
    summaries: List[WeeklyEventResponse]


class DailyEventsListResponse(BaseModel):
    """일간 이벤트 목록 응답"""

    daily_events: List[DailyEventResponse]
    total_count: int
    available_tags: Dict[str, List[str]]


class WeeklyEventsListResponse(BaseModel):
    """주간 이벤트 목록 응답"""

    weekly_events: List[WeeklyEventResponse]
    total_count: int


class PopularTagsResponse(BaseModel):
    """인기 태그 응답"""

    target: List[str] = []
    event_type: List[str] = []
    time: List[str] = []
    importance: List[str] = []
    other: List[str] = []
    all: List[str] = []

