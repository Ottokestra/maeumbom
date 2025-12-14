"""
요청/응답 스키마
Pydantic models for request/response validation
"""
from pydantic import BaseModel, Field, ConfigDict
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

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        extra='ignore',  # 추가 필드 무시
    )

    id: int = Field(alias="ID")
    user_id: int = Field(alias="USER_ID")
    event_date: date = Field(alias="EVENT_DATE")
    event_type: str = Field(alias="EVENT_TYPE")
    target_type: str = Field(alias="TARGET_TYPE")
    event_summary: str = Field(alias="EVENT_SUMMARY")
    event_time: Optional[datetime] = Field(None, alias="EVENT_TIME")
    importance: Optional[int] = Field(default=3, alias="IMPORTANCE")
    is_future_event: bool = Field(alias="IS_FUTURE_EVENT")
    tags: List[str] = Field(default=[], alias="TAGS")
    created_at: datetime = Field(alias="CREATED_AT")
    updated_at: datetime = Field(alias="UPDATED_AT")


class WeeklyEventResponse(BaseModel):
    """주간 이벤트 응답"""

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        extra='ignore'  # 추가 필드 무시
    )

    id: int = Field(alias="ID")
    user_id: int = Field(alias="USER_ID")
    week_start: date = Field(alias="WEEK_START")
    week_end: date = Field(alias="WEEK_END")
    target_type: str = Field(alias="TARGET_TYPE")
    events_summary: List[Dict[str, Any]] = Field(default=[], alias="EVENTS_SUMMARY")
    total_events: int = Field(alias="TOTAL_EVENTS")
    tags: List[str] = Field(default=[], alias="TAGS")
    created_at: datetime = Field(alias="CREATED_AT")
    updated_at: datetime = Field(alias="UPDATED_AT")


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

