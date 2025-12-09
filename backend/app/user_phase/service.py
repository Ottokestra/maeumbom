"""
Business logic for User Phase Service

Phase 계산 방식:
- 월요일에 계산된 평일/주말 평균 기상 시간을 기준으로 Phase 계산
- 실시간 데이터가 아닌 패턴 평균 사용 (알림 발송에 적합)

월요일 자동 처리:
- 월요일에 /sync 호출 시 지난 7일(월~일) 데이터를 동기화
- 패턴 분석 자동 실행 (평일/주말 패턴 학습)
"""
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, date, time, timedelta
from typing import Optional, Dict, Any, List
from fastapi import HTTPException

from app.db.models import HealthLog, UserPatternSetting, ManualHealthLog
from .models import HealthSyncRequest, HealthDataSummary


def sync_health_data(user_id: int, request: HealthSyncRequest, db: Session):
    """
    건강 데이터 동기화
    
    - 자동 동기화 (apple_health, google_fit): TB_HEALTH_LOGS에 항상 추가 저장
    - 수동 입력 (manual): TB_MANUAL_HEALTH_LOGS에 사용자당 하나의 레코드만 업데이트
    
    Args:
        user_id: 사용자 ID
        request: 건강 데이터 요청
        db: Database session
        
    Returns:
        저장된 HealthLog 또는 ManualHealthLog
    """
    # 날짜 파싱
    log_date = datetime.strptime(request.log_date, "%Y-%m-%d").date()
    
    # 시간 데이터 파싱
    sleep_start_time = None
    if request.sleep_start_time:
        sleep_start_time = datetime.fromisoformat(request.sleep_start_time.replace('Z', '+00:00'))
    
    sleep_end_time = None
    if request.sleep_end_time:
        sleep_end_time = datetime.fromisoformat(request.sleep_end_time.replace('Z', '+00:00'))
    
    # 수동 입력인 경우: TB_MANUAL_HEALTH_LOGS 사용
    if request.source_type == "manual":
        # 기존 수동 입력 데이터 확인 (사용자당 하나의 레코드만 존재)
        existing_manual_log = db.query(ManualHealthLog).filter(
            ManualHealthLog.USER_ID == user_id
        ).first()
        
        if existing_manual_log:
            # Update: 사용자당 하나의 레코드만 업데이트
            existing_manual_log.LOG_DATE = log_date
            existing_manual_log.SLEEP_START_TIME = sleep_start_time
            existing_manual_log.SLEEP_END_TIME = sleep_end_time
            existing_manual_log.STEP_COUNT = request.step_count
            existing_manual_log.SLEEP_DURATION_HOURS = request.sleep_duration_hours
            existing_manual_log.HEART_RATE_AVG = request.heart_rate_avg
            existing_manual_log.HEART_RATE_RESTING = request.heart_rate_resting
            existing_manual_log.HEART_RATE_VARIABILITY = request.heart_rate_variability
            existing_manual_log.ACTIVE_MINUTES = request.active_minutes
            existing_manual_log.EXERCISE_MINUTES = request.exercise_minutes
            existing_manual_log.CALORIES_BURNED = request.calories_burned
            existing_manual_log.DISTANCE_KM = request.distance_km
            existing_manual_log.RAW_DATA = request.raw_data
            # UPDATED_AT는 자동으로 업데이트됨 (onupdate=func.now())
            
            db.commit()
            db.refresh(existing_manual_log)
            return existing_manual_log
        else:
            # Insert: 첫 번째 수동 입력
            new_manual_log = ManualHealthLog(
                USER_ID=user_id,
                LOG_DATE=log_date,
                SLEEP_START_TIME=sleep_start_time,
                SLEEP_END_TIME=sleep_end_time,
                STEP_COUNT=request.step_count,
                SLEEP_DURATION_HOURS=request.sleep_duration_hours,
                HEART_RATE_AVG=request.heart_rate_avg,
                HEART_RATE_RESTING=request.heart_rate_resting,
                HEART_RATE_VARIABILITY=request.heart_rate_variability,
                ACTIVE_MINUTES=request.active_minutes,
                EXERCISE_MINUTES=request.exercise_minutes,
                CALORIES_BURNED=request.calories_burned,
                DISTANCE_KM=request.distance_km,
                RAW_DATA=request.raw_data
            )
            
            db.add(new_manual_log)
            db.commit()
            db.refresh(new_manual_log)
            return new_manual_log
    
    # 자동 동기화인 경우 (apple_health, google_fit): TB_HEALTH_LOGS에 항상 추가 저장
    else:
        # 기존 데이터 확인 없이 항상 추가 저장 (같은 날짜여도 새 레코드)
        new_log = HealthLog(
            USER_ID=user_id,
            LOG_DATE=log_date,
            SLEEP_START_TIME=sleep_start_time,
            SLEEP_END_TIME=sleep_end_time,
            STEP_COUNT=request.step_count,
            SLEEP_DURATION_HOURS=request.sleep_duration_hours,
            HEART_RATE_AVG=request.heart_rate_avg,
            HEART_RATE_RESTING=request.heart_rate_resting,
            HEART_RATE_VARIABILITY=request.heart_rate_variability,
            ACTIVE_MINUTES=request.active_minutes,
            EXERCISE_MINUTES=request.exercise_minutes,
            CALORIES_BURNED=request.calories_burned,
            DISTANCE_KM=request.distance_km,
            SOURCE_TYPE=request.source_type,
            RAW_DATA=request.raw_data
        )
        
        db.add(new_log)
        db.commit()
        db.refresh(new_log)
        return new_log


def get_current_phase(user_id: int, db: Session) -> Dict[str, Any]:
    """
    현재 Phase 계산
    
    Fallback 전략:
    1. 패턴 분석 결과 (평일/주말 평균) - 최우선
    2. 사용자 수동 설정 (건강 데이터 비동의 시)
    3. 에러 처리 (설정 필요)
    
    Args:
        user_id: 사용자 ID
        db: Database session
        
    Returns:
        Phase 정보 딕셔너리
    """
    today = date.today()
    
    # Step 1: 패턴 분석 결과 사용 (최우선)
    setting = db.query(UserPatternSetting).filter(
        UserPatternSetting.USER_ID == user_id
    ).first()
    
    if setting:
        # 평일/주말 구분
        is_weekend = today.weekday() >= 5  # 토(5), 일(6)
        
        if is_weekend:
            # 주말인데 주말 데이터가 없으면 평일 패턴 사용
            if setting.WEEKEND_WAKE_TIME and setting.WEEKEND_SLEEP_TIME:
                wake_time_obj = setting.WEEKEND_WAKE_TIME
                sleep_time_obj = setting.WEEKEND_SLEEP_TIME
                pattern_type = "주말"
            else:
                # 주말 데이터가 없으면 평일 패턴 사용
                wake_time_obj = setting.WEEKDAY_WAKE_TIME
                sleep_time_obj = setting.WEEKDAY_SLEEP_TIME
                pattern_type = "평일 (주말 데이터 부족)"
            data_source = "pattern_analysis" if setting.LAST_ANALYSIS_DATE else "user_setting"
        else:
            wake_time_obj = setting.WEEKDAY_WAKE_TIME
            sleep_time_obj = setting.WEEKDAY_SLEEP_TIME
            pattern_type = "평일"
            data_source = "pattern_analysis" if setting.LAST_ANALYSIS_DATE else "user_setting"
        
        # 오늘 날짜와 시간 결합
        wake_time = datetime.combine(today, wake_time_obj)
        sleep_time = datetime.combine(today, sleep_time_obj)
        
        hours_since_wake = calculate_hours_since(wake_time)
        hours_to_sleep = calculate_hours_until(sleep_time)
        
        current_phase = calculate_phase(hours_since_wake, hours_to_sleep)
        
        # 건강 데이터 요약 (오늘 데이터가 있으면 포함)
        today_log = db.query(HealthLog).filter(
            HealthLog.USER_ID == user_id,
            HealthLog.LOG_DATE == today
        ).first()
        
        health_data = None
        if today_log:
            health_data = HealthDataSummary(
                sleep_duration_hours=today_log.SLEEP_DURATION_HOURS,
                heart_rate_avg=today_log.HEART_RATE_AVG,
                heart_rate_resting=today_log.HEART_RATE_RESTING,
                heart_rate_variability=today_log.HEART_RATE_VARIABILITY,
                step_count=today_log.STEP_COUNT,
                active_minutes=today_log.ACTIVE_MINUTES,
                exercise_minutes=today_log.EXERCISE_MINUTES,
                calories_burned=today_log.CALORIES_BURNED,
                distance_km=today_log.DISTANCE_KM
            )
        
        return {
            "current_phase": current_phase,
            "hours_since_wake": round(hours_since_wake, 1),
            "hours_to_sleep": round(hours_to_sleep, 1),
            "data_source": data_source,
            "message": f"{pattern_type} 패턴 기준 기상 후 {format_hours(hours_since_wake)} 경과",
            "health_data": health_data
        }
    
    # Step 2: 설정 없음 - 에러
    raise HTTPException(
        status_code=400,
        detail="사용자 설정이 필요합니다. 온보딩을 완료하거나 건강 데이터 동기화를 허용해주세요."
    )


def calculate_phase(hours_since_wake: float, hours_to_sleep: Optional[float]) -> str:
    """
    Phase 계산 로직 (루틴 추천 엔진과 동일)
    
    Args:
        hours_since_wake: 기상 후 경과 시간
        hours_to_sleep: 취침까지 남은 시간
        
    Returns:
        Phase 문자열 (morning, day, evening, sleep_prep)
    """
    # 취침 관련 정보 우선
    if hours_to_sleep is not None:
        # 취침 0~2.5시간 전 → 취침 준비
        if 0 <= hours_to_sleep <= 2.5:
            return "sleep_prep"
        # 취침 2.5~3.5시간 전 → 개인화 저녁
        if 2.5 < hours_to_sleep <= 3.5:
            return "evening"
    
    # 기상 후 기준
    if 0 <= hours_since_wake <= 3:
        return "morning"
    if 3 < hours_since_wake <= 10:
        return "day"
    
    # 그 외는 저녁으로 간주
    return "evening"


def calculate_hours_since(wake_time: datetime) -> float:
    """기상 후 경과 시간 계산"""
    now = datetime.now(wake_time.tzinfo) if wake_time.tzinfo else datetime.now()
    delta = now - wake_time
    return delta.total_seconds() / 3600


def calculate_hours_until(sleep_time: datetime) -> float:
    """취침까지 남은 시간 계산"""
    now = datetime.now(sleep_time.tzinfo) if sleep_time.tzinfo else datetime.now()
    delta = sleep_time - now
    return delta.total_seconds() / 3600


def format_hours(hours: float) -> str:
    """시간을 사용자 친화적 문자열로 변환"""
    h = int(hours)
    m = int((hours - h) * 60)
    
    if h > 0 and m > 0:
        return f"{h}시간 {m}분"
    elif h > 0:
        return f"{h}시간"
    else:
        return f"{m}분"


def analyze_weekly_pattern(user_id: int, db: Session) -> Dict[str, Any]:
    """
    주간 패턴 분석 (지난 7일 데이터)
    
    Args:
        user_id: 사용자 ID
        db: Database session
        
    Returns:
        분석 결과 딕셔너리
    """
    # 지난 7일 데이터 조회
    end_date = date.today()
    start_date = end_date - timedelta(days=7)
    
    logs = db.query(HealthLog).filter(
        HealthLog.USER_ID == user_id,
        HealthLog.LOG_DATE >= start_date,
        HealthLog.LOG_DATE < end_date
    ).all()
    
    if not logs:
        raise HTTPException(
            status_code=400,
            detail="분석할 데이터가 부족합니다. 최소 7일의 데이터가 필요합니다."
        )
    
    # 평일/주말 분리
    weekday_logs = [log for log in logs if log.LOG_DATE.weekday() < 5]
    weekend_logs = [log for log in logs if log.LOG_DATE.weekday() >= 5]
    
    # 평일 평균 계산
    weekday_wake_times = [log.SLEEP_END_TIME.time() for log in weekday_logs if log.SLEEP_END_TIME]
    weekday_sleep_times = [log.SLEEP_START_TIME.time() for log in weekday_logs if log.SLEEP_START_TIME]
    
    # 주말 평균 계산
    weekend_wake_times = [log.SLEEP_END_TIME.time() for log in weekend_logs if log.SLEEP_END_TIME]
    weekend_sleep_times = [log.SLEEP_START_TIME.time() for log in weekend_logs if log.SLEEP_START_TIME]
    
    # 평일 데이터가 없으면 에러
    if not weekday_wake_times:
        raise HTTPException(
            status_code=400,
            detail="평일 데이터가 부족합니다. 최소 평일 데이터가 필요합니다."
        )
    
    # 평균 시간 계산
    weekday_avg_wake = calculate_average_time(weekday_wake_times)
    weekday_avg_sleep = calculate_average_time(weekday_sleep_times) if weekday_sleep_times else time(23, 0)
    
    # 주말 데이터가 있으면 계산, 없으면 None
    weekend_avg_wake = calculate_average_time(weekend_wake_times) if weekend_wake_times else None
    weekend_avg_sleep = calculate_average_time(weekend_sleep_times) if weekend_sleep_times else None
    
    # 데이터 완성도 계산
    data_completeness = len(logs) / 7.0
    
    # UserPatternSetting 업데이트 또는 생성
    setting = db.query(UserPatternSetting).filter(
        UserPatternSetting.USER_ID == user_id
    ).first()
    
    if setting:
        # Update - 평일만 업데이트, 주말은 데이터가 있을 때만 업데이트
        setting.WEEKDAY_WAKE_TIME = weekday_avg_wake
        setting.WEEKDAY_SLEEP_TIME = weekday_avg_sleep
        if weekend_avg_wake is not None:
            setting.WEEKEND_WAKE_TIME = weekend_avg_wake
        if weekend_avg_sleep is not None:
            setting.WEEKEND_SLEEP_TIME = weekend_avg_sleep
        setting.LAST_ANALYSIS_DATE = date.today()
        setting.DATA_COMPLETENESS = data_completeness
    else:
        # Create - 주말 데이터가 없으면 평일 데이터만 사용
        if weekend_avg_wake is None:
            weekend_avg_wake = weekday_avg_wake  # 평일 값으로 대체
        if weekend_avg_sleep is None:
            weekend_avg_sleep = weekday_avg_sleep  # 평일 값으로 대체
        
        setting = UserPatternSetting(
            USER_ID=user_id,
            WEEKDAY_WAKE_TIME=weekday_avg_wake,
            WEEKDAY_SLEEP_TIME=weekday_avg_sleep,
            WEEKEND_WAKE_TIME=weekend_avg_wake,
            WEEKEND_SLEEP_TIME=weekend_avg_sleep,
            LAST_ANALYSIS_DATE=date.today(),
            DATA_COMPLETENESS=data_completeness,
            IS_NIGHT_WORKER=False
        )
        db.add(setting)
    
    db.commit()
    db.refresh(setting)
    
    # 인사이트 생성 (주말 데이터가 있을 때만)
    insight = None
    if weekend_avg_wake is not None:
        weekday_wake_minutes = weekday_avg_wake.hour * 60 + weekday_avg_wake.minute
        weekend_wake_minutes = weekend_avg_wake.hour * 60 + weekend_avg_wake.minute
        diff_minutes = weekend_wake_minutes - weekday_wake_minutes
        
        if diff_minutes > 60:
            insight = f"평일보다 주말에 {diff_minutes // 60}시간 {diff_minutes % 60}분 늦게 일어나시네요"
        elif diff_minutes < -60:
            insight = f"주말보다 평일에 {abs(diff_minutes) // 60}시간 {abs(diff_minutes) % 60}분 늦게 일어나시네요"
        else:
            insight = "평일과 주말의 기상 시간이 비슷하시네요"
    
    # 응답 생성
    result = {
        "weekday": {
            "avg_wake_time": weekday_avg_wake.strftime("%H:%M"),
            "avg_sleep_time": weekday_avg_sleep.strftime("%H:%M")
        },
        "last_analysis_date": date.today().isoformat(),
        "data_completeness": round(data_completeness, 2),
        "analysis_period_days": 7,
    }
    
    # 주말 데이터가 있을 때만 주말 패턴 포함
    if weekend_avg_wake is not None and weekend_avg_sleep is not None:
        result["weekend"] = {
            "avg_wake_time": weekend_avg_wake.strftime("%H:%M"),
            "avg_sleep_time": weekend_avg_sleep.strftime("%H:%M")
        }
        if insight:
            result["insight"] = insight
    else:
        # 주말 데이터가 없으면 주말 패턴을 None으로 설정
        result["weekend"] = None
        result["insight"] = "주말 데이터가 부족하여 주말 패턴을 분석할 수 없습니다."
    
    return result


def calculate_average_time(times: List[time]) -> time:
    """시간 리스트의 평균 계산"""
    if not times:
        return time(7, 0)  # 기본값
    
    # 분 단위로 변환
    total_minutes = sum(t.hour * 60 + t.minute for t in times)
    avg_minutes = total_minutes // len(times)
    
    # 시간으로 변환
    hours = avg_minutes // 60
    minutes = avg_minutes % 60
    
    return time(hours, minutes)


def should_analyze_pattern(user_id: int, db: Session) -> bool:
    """
    주간 패턴 분석이 필요한지 체크
    
    월요일에 지난 7일 데이터를 동기화한 후 패턴 분석 실행
    
    Args:
        user_id: 사용자 ID
        db: Database session
        
    Returns:
        분석 필요 여부
    """
    # 월요일이 아니면 분석 불필요
    if date.today().weekday() != 0:
        return False
    
    setting = db.query(UserPatternSetting).filter(
        UserPatternSetting.USER_ID == user_id
    ).first()
    
    # 설정이 없으면 분석 필요
    if not setting or not setting.LAST_ANALYSIS_DATE:
        return True
    
    # 이번 주에 이미 분석했는지 확인
    days_since_analysis = (date.today() - setting.LAST_ANALYSIS_DATE).days
    
    # 7일 이상 지났으면 분석 필요 (이번 주 분석 안 함)
    if days_since_analysis >= 7:
        return True
    
    return False


def get_user_setting(user_id: int, db: Session) -> Optional[UserPatternSetting]:
    """사용자 설정 조회"""
    return db.query(UserPatternSetting).filter(
        UserPatternSetting.USER_ID == user_id
    ).first()


def update_user_setting(
    user_id: int,
    weekday_wake_time: str,
    weekday_sleep_time: str,
    weekend_wake_time: str,
    weekend_sleep_time: str,
    is_night_worker: bool,
    db: Session
) -> UserPatternSetting:
    """
    사용자 설정 업데이트
    
    Args:
        user_id: 사용자 ID
        weekday_wake_time: 평일 기상 시간 (HH:MM)
        weekday_sleep_time: 평일 취침 시간 (HH:MM)
        weekend_wake_time: 주말 기상 시간 (HH:MM)
        weekend_sleep_time: 주말 취침 시간 (HH:MM)
        is_night_worker: 야간 근무 여부
        db: Database session
        
    Returns:
        업데이트된 UserPatternSetting
    """
    # 시간 파싱
    weekday_wake = datetime.strptime(weekday_wake_time, "%H:%M").time()
    weekday_sleep = datetime.strptime(weekday_sleep_time, "%H:%M").time()
    weekend_wake = datetime.strptime(weekend_wake_time, "%H:%M").time()
    weekend_sleep = datetime.strptime(weekend_sleep_time, "%H:%M").time()
    
    setting = db.query(UserPatternSetting).filter(
        UserPatternSetting.USER_ID == user_id
    ).first()
    
    if setting:
        # Update
        setting.WEEKDAY_WAKE_TIME = weekday_wake
        setting.WEEKDAY_SLEEP_TIME = weekday_sleep
        setting.WEEKEND_WAKE_TIME = weekend_wake
        setting.WEEKEND_SLEEP_TIME = weekend_sleep
        setting.IS_NIGHT_WORKER = is_night_worker
    else:
        # Create
        setting = UserPatternSetting(
            USER_ID=user_id,
            WEEKDAY_WAKE_TIME=weekday_wake,
            WEEKDAY_SLEEP_TIME=weekday_sleep,
            WEEKEND_WAKE_TIME=weekend_wake,
            WEEKEND_SLEEP_TIME=weekend_sleep,
            IS_NIGHT_WORKER=is_night_worker
        )
        db.add(setting)
    
    db.commit()
    db.refresh(setting)
    return setting

