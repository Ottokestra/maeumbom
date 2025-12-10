"""API routes for User Phase Service."""
from typing import Dict, Any

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.auth.models import User
from app.db.database import get_db

from . import service
from .models import (
    HealthSyncRequest,
    UserPhaseResponse,
    UserPatternResponse,
    UserPatternSettingResponse,
    UserPatternSettingUpdate,
)

router = APIRouter(
    prefix="/api/service/user-phase",
    tags=["user-phase"]
)


@router.post("/sync", response_model=UserPhaseResponse)
async def sync_health_data(
    request: HealthSyncRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    건강 데이터 동기화
    
    - 건강 데이터를 DB에 저장 (upsert)
    - **월요일**: 지난 7일(월~일) 데이터를 동기화하고 패턴 분석 자동 실행
    - **평일(화~일)**: 오늘 데이터만 동기화
    - Phase 계산은 패턴 분석 결과(평일/주말 평균) 기준으로 수행
    - source_type: "manual" (테스트), "apple_health" (iOS), "google_fit" (Android)
    """
    try:
        # 건강 데이터 저장
        service.sync_health_data(current_user.ID, request, db)
        
        # 주간 패턴 분석 필요 여부 체크 (백그라운드에서 실행)
        if service.should_analyze_pattern(current_user.ID, db):
            try:
                service.analyze_weekly_pattern(current_user.ID, db)
            except Exception as e:
                # 패턴 분석 실패해도 Phase 계산은 계속
                print(f"[WARN] Pattern analysis failed: {e}")
        
        # Phase 계산
        phase_data = service.get_current_phase(current_user.ID, db)
        
        return UserPhaseResponse(**phase_data)
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={"detail": f"건강 데이터 동기화 실패: {str(e)}", "code": "SYNC_FAILED"},
        )


@router.get("/current", response_model=UserPhaseResponse)
async def get_current_phase(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    현재 Phase 조회
    
    Fallback 전략:
    1. 패턴 분석 결과 (평일/주말 평균) - 최우선
    2. 사용자 수동 설정 (건강 데이터 비동의 시)
    3. 에러 처리 (설정 필요)
    
    Phase는 월요일에 계산된 평일/주말 평균 기상 시간을 기준으로 계산됩니다.
    """
    try:
        phase_data = service.get_current_phase(current_user.ID, db)
        return UserPhaseResponse(**phase_data)
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={"detail": f"Phase 조회 실패: {str(e)}", "code": "PHASE_QUERY_FAILED"},
        )


@router.get("/settings", response_model=UserPatternSettingResponse)
async def get_user_settings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    사용자 설정 조회
    """
    setting = service.get_user_setting(current_user.ID, db)
    
    if not setting:
        raise HTTPException(
            status_code=404,
            detail={"detail": "사용자 설정이 없습니다. 온보딩을 완료하거나 설정을 입력해주세요.", "code": "SETTING_NOT_FOUND"},
        )
    
    return UserPatternSettingResponse(
        weekday_wake_time=setting.WEEKDAY_WAKE_TIME.strftime("%H:%M"),
        weekday_sleep_time=setting.WEEKDAY_SLEEP_TIME.strftime("%H:%M"),
        weekend_wake_time=setting.WEEKEND_WAKE_TIME.strftime("%H:%M"),
        weekend_sleep_time=setting.WEEKEND_SLEEP_TIME.strftime("%H:%M"),
        is_night_worker=setting.IS_NIGHT_WORKER,
        last_analysis_date=setting.LAST_ANALYSIS_DATE.isoformat() if setting.LAST_ANALYSIS_DATE else None,
        data_completeness=setting.DATA_COMPLETENESS,
        created_at=setting.CREATED_AT,
        updated_at=setting.UPDATED_AT
    )


@router.put("/settings", response_model=UserPatternSettingResponse)
async def update_user_settings(
    request: UserPatternSettingUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    사용자 설정 업데이트
    
    - 온보딩 시 초기 설정 입력
    - 사용자가 직접 설정 수정
    """
    try:
        setting = service.update_user_setting(
            user_id=current_user.ID,
            weekday_wake_time=request.weekday_wake_time,
            weekday_sleep_time=request.weekday_sleep_time,
            weekend_wake_time=request.weekend_wake_time,
            weekend_sleep_time=request.weekend_sleep_time,
            is_night_worker=request.is_night_worker,
            db=db
        )
        
        return UserPatternSettingResponse(
            weekday_wake_time=setting.WEEKDAY_WAKE_TIME.strftime("%H:%M"),
            weekday_sleep_time=setting.WEEKDAY_SLEEP_TIME.strftime("%H:%M"),
            weekend_wake_time=setting.WEEKEND_WAKE_TIME.strftime("%H:%M"),
            weekend_sleep_time=setting.WEEKEND_SLEEP_TIME.strftime("%H:%M"),
            is_night_worker=setting.IS_NIGHT_WORKER,
            last_analysis_date=setting.LAST_ANALYSIS_DATE.isoformat() if setting.LAST_ANALYSIS_DATE else None,
            data_completeness=setting.DATA_COMPLETENESS,
            created_at=setting.CREATED_AT,
            updated_at=setting.UPDATED_AT
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={"detail": f"설정 업데이트 실패: {str(e)}", "code": "SETTING_UPDATE_FAILED"},
        )


@router.post("/analyze", response_model=UserPatternResponse)
async def analyze_pattern(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    주간 패턴 분석 (수동 트리거)
    
    - 지난 7일 건강 데이터를 분석하여 평일/주말 패턴 계산
    - 분석 결과를 UserPatternSetting에 저장
    """
    try:
        pattern_data = service.analyze_weekly_pattern(current_user.ID, db)
        return UserPatternResponse(**pattern_data)
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={"detail": f"패턴 분석 실패: {str(e)}", "code": "PATTERN_ANALYSIS_FAILED"},
        )


@router.get("/pattern", response_model=UserPatternResponse)
async def get_pattern(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    패턴 분석 결과 조회
    """
    setting = service.get_user_setting(current_user.ID, db)
    
    if not setting:
        raise HTTPException(
            status_code=404,
            detail={"detail": "패턴 분석 결과가 없습니다. 먼저 분석을 실행해주세요.", "code": "PATTERN_NOT_FOUND"},
        )
    
    # 인사이트 생성
    weekday_wake_minutes = setting.WEEKDAY_WAKE_TIME.hour * 60 + setting.WEEKDAY_WAKE_TIME.minute
    weekend_wake_minutes = setting.WEEKEND_WAKE_TIME.hour * 60 + setting.WEEKEND_WAKE_TIME.minute
    diff_minutes = weekend_wake_minutes - weekday_wake_minutes
    
    if diff_minutes > 60:
        insight = f"평일보다 주말에 {diff_minutes // 60}시간 {diff_minutes % 60}분 늦게 일어나시네요"
    elif diff_minutes < -60:
        insight = f"주말보다 평일에 {abs(diff_minutes) // 60}시간 {abs(diff_minutes) % 60}분 늦게 일어나시네요"
    else:
        insight = "평일과 주말의 기상 시간이 비슷하시네요"
    
    return UserPatternResponse(
        weekday={
            "avg_wake_time": setting.WEEKDAY_WAKE_TIME.strftime("%H:%M"),
            "avg_sleep_time": setting.WEEKDAY_SLEEP_TIME.strftime("%H:%M"),
            "avg_sleep_duration": None
        },
        weekend={
            "avg_wake_time": setting.WEEKEND_WAKE_TIME.strftime("%H:%M"),
            "avg_sleep_time": setting.WEEKEND_SLEEP_TIME.strftime("%H:%M"),
            "avg_sleep_duration": None
        },
        last_analysis_date=setting.LAST_ANALYSIS_DATE.isoformat() if setting.LAST_ANALYSIS_DATE else None,
        data_completeness=setting.DATA_COMPLETENESS,
        analysis_period_days=7,
        insight=insight
    )

