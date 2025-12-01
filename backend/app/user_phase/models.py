"""
Pydantic models for User Phase Service
Request/Response validation
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, date, time


class HealthSyncRequest(BaseModel):
    """건강 데이터 동기화 요청"""
    log_date: str = Field(..., description="날짜 (YYYY-MM-DD)")
    
    # Phase 계산용 핵심 데이터 (모두 Optional)
    sleep_start_time: Optional[str] = Field(None, description="취침 시간 (ISO datetime)")
    sleep_end_time: Optional[str] = Field(None, description="기상 시간 (ISO datetime)")
    step_count: Optional[int] = Field(None, description="걸음 수", ge=0)
    
    # 갱년기 건강 모니터링 데이터 (모두 Optional)
    sleep_duration_hours: Optional[float] = Field(None, description="수면 시간 (시간)", ge=0)
    heart_rate_avg: Optional[int] = Field(None, description="평균 심박수", ge=0)
    heart_rate_resting: Optional[int] = Field(None, description="안정 시 심박수", ge=0)
    heart_rate_variability: Optional[float] = Field(None, description="심박 변이도 (HRV)", ge=0)
    active_minutes: Optional[int] = Field(None, description="활동 시간 (분)", ge=0)
    exercise_minutes: Optional[int] = Field(None, description="운동 시간 (분)", ge=0)
    calories_burned: Optional[int] = Field(None, description="소모 칼로리", ge=0)
    distance_km: Optional[float] = Field(None, description="이동 거리 (km)", ge=0)
    
    # 메타데이터
    source_type: str = Field(..., description="데이터 출처 (manual, apple_health, google_fit)")
    raw_data: Optional[dict] = Field(None, description="원본 데이터 (JSON)")
    
    class Config:
        json_schema_extra = {
            "example": {
                "log_date": "2025-11-27",
                "sleep_start_time": "2025-11-26T23:00:00Z",
                "sleep_end_time": "2025-11-27T07:00:00Z",
                "step_count": 8500,
                "sleep_duration_hours": 7.5,
                "heart_rate_avg": 72,
                "heart_rate_resting": 65,
                "heart_rate_variability": 45,
                "active_minutes": 60,
                "source_type": "manual"
            }
        }


class HealthDataSummary(BaseModel):
    """건강 데이터 요약"""
    sleep_duration_hours: Optional[float] = None
    heart_rate_avg: Optional[int] = None
    heart_rate_resting: Optional[int] = None
    heart_rate_variability: Optional[float] = None
    step_count: Optional[int] = None
    active_minutes: Optional[int] = None


class UserPhaseResponse(BaseModel):
    """현재 Phase 조회 응답"""
    current_phase: str = Field(..., description="현재 Phase (morning, day, evening, sleep_prep)")
    hours_since_wake: float = Field(..., description="기상 후 경과 시간")
    hours_to_sleep: Optional[float] = Field(None, description="취침까지 남은 시간")
    data_source: str = Field(..., description="데이터 출처 (real_data, pattern_analysis, user_setting)")
    message: str = Field(..., description="사용자 친화적 메시지")
    health_data: Optional[HealthDataSummary] = Field(None, description="건강 데이터 요약")
    
    class Config:
        json_schema_extra = {
            "example": {
                "current_phase": "day",
                "hours_since_wake": 5.5,
                "hours_to_sleep": 6.5,
                "data_source": "real_data",
                "message": "기상 후 5시간 30분 경과",
                "health_data": {
                    "sleep_duration_hours": 7.5,
                    "heart_rate_avg": 72,
                    "step_count": 8500
                }
            }
        }


class WeekdayPattern(BaseModel):
    """평일 패턴"""
    avg_wake_time: str = Field(..., description="평균 기상 시간 (HH:MM)")
    avg_sleep_time: str = Field(..., description="평균 취침 시간 (HH:MM)")
    avg_sleep_duration: Optional[float] = Field(None, description="평균 수면 시간")


class WeekendPattern(BaseModel):
    """주말 패턴"""
    avg_wake_time: str = Field(..., description="평균 기상 시간 (HH:MM)")
    avg_sleep_time: str = Field(..., description="평균 취침 시간 (HH:MM)")
    avg_sleep_duration: Optional[float] = Field(None, description="평균 수면 시간")


class UserPatternResponse(BaseModel):
    """패턴 분석 결과 응답"""
    weekday: WeekdayPattern = Field(..., description="평일 패턴")
    weekend: WeekendPattern = Field(..., description="주말 패턴")
    last_analysis_date: Optional[str] = Field(None, description="마지막 분석 날짜")
    data_completeness: Optional[float] = Field(None, description="데이터 완성도 (0.0-1.0)")
    analysis_period_days: int = Field(..., description="분석 기간 (일)")
    insight: Optional[str] = Field(None, description="패턴 분석 인사이트")
    
    class Config:
        json_schema_extra = {
            "example": {
                "weekday": {
                    "avg_wake_time": "07:15",
                    "avg_sleep_time": "23:30",
                    "avg_sleep_duration": 7.75
                },
                "weekend": {
                    "avg_wake_time": "09:30",
                    "avg_sleep_time": "01:00",
                    "avg_sleep_duration": 8.5
                },
                "last_analysis_date": "2025-11-25",
                "data_completeness": 0.86,
                "analysis_period_days": 7,
                "insight": "평일보다 주말에 2시간 15분 늦게 일어나시네요"
            }
        }


class UserPatternSettingUpdate(BaseModel):
    """사용자 설정 업데이트 요청"""
    weekday_wake_time: str = Field(..., description="평일 기상 시간 (HH:MM)")
    weekday_sleep_time: str = Field(..., description="평일 취침 시간 (HH:MM)")
    weekend_wake_time: str = Field(..., description="주말 기상 시간 (HH:MM)")
    weekend_sleep_time: str = Field(..., description="주말 취침 시간 (HH:MM)")
    is_night_worker: Optional[bool] = Field(False, description="야간 근무 여부")
    
    class Config:
        json_schema_extra = {
            "example": {
                "weekday_wake_time": "07:00",
                "weekday_sleep_time": "23:00",
                "weekend_wake_time": "09:00",
                "weekend_sleep_time": "01:00",
                "is_night_worker": False
            }
        }


class UserPatternSettingResponse(BaseModel):
    """사용자 설정 조회 응답"""
    weekday_wake_time: str
    weekday_sleep_time: str
    weekend_wake_time: str
    weekend_sleep_time: str
    is_night_worker: bool
    last_analysis_date: Optional[str] = None
    data_completeness: Optional[float] = None
    created_at: datetime
    updated_at: datetime

