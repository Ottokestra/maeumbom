"""
대상별 이벤트 API 엔드포인트
API endpoints for target-specific event management
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import date, timedelta
from typing import List, Optional

from app.db.database import get_db
from app.auth.dependencies import get_current_user
from app.db.models import User
from .schemas import (
    DailyEventResponse,
    WeeklyEventResponse,
    AnalyzeDailyRequest,
    AnalyzeDailyResponse,
    AnalyzeWeeklyRequest,
    AnalyzeWeeklyResponse,
    DailyEventsListResponse,
    WeeklyEventsListResponse,
    PopularTagsResponse,
)
from .service import (
    analyze_daily_events,
    analyze_weekly_events,
    get_daily_events,
    get_weekly_events,
    get_popular_tags,
)
from .constants import TARGET_TAGS

router = APIRouter()


@router.post("/analyze-daily", response_model=AnalyzeDailyResponse)
async def trigger_daily_analysis(
    request: AnalyzeDailyRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    특정 날짜의 대화 분석 실행

    Args:
        request: 분석 요청 (target_date)
        db: Database session
        current_user: Current authenticated user

    Returns:
        분석 결과 및 생성된 이벤트 목록
    """
    try:
        events = analyze_daily_events(
            db, current_user.ID, request.target_date, created_by=current_user.ID
        )

        return AnalyzeDailyResponse(
            analyzed_date=request.target_date,
            events_count=len(events),
            events=[DailyEventResponse.from_orm(event) for event in events],
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"분석 실패: {str(e)}")


@router.post("/analyze-weekly", response_model=AnalyzeWeeklyResponse)
async def trigger_weekly_analysis(
    request: AnalyzeWeeklyRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    특정 주간의 이벤트 요약 실행

    Args:
        request: 분석 요청 (week_start)
        db: Database session
        current_user: Current authenticated user

    Returns:
        주간 요약 결과
    """
    try:
        # 주 시작일이 월요일인지 확인
        if request.week_start.weekday() != 0:
            raise HTTPException(
                status_code=400, detail="주 시작일은 월요일이어야 합니다."
            )

        summaries = analyze_weekly_events(
            db, current_user.ID, request.week_start, created_by=current_user.ID
        )

        week_end = request.week_start + timedelta(days=6)

        return AnalyzeWeeklyResponse(
            week_start=request.week_start,
            week_end=week_end,
            summaries_count=len(summaries),
            summaries=[WeeklyEventResponse.from_orm(summary) for summary in summaries],
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"주간 분석 실패: {str(e)}")


@router.get("/daily", response_model=DailyEventsListResponse)
async def list_daily_events(
    event_type: Optional[str] = Query(None, description="이벤트 타입 (alarm/event/memory)"),
    tags: Optional[str] = Query(
        None, description="쉼표로 구분된 태그 (예: #아들,#픽업)"
    ),
    start_date: Optional[date] = Query(None, description="시작 날짜 (YYYY-MM-DD)"),
    end_date: Optional[date] = Query(None, description="종료 날짜 (YYYY-MM-DD)"),
    target_type: Optional[str] = Query(None, description="대상 유형 (husband/son/...)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    일간 이벤트 목록 조회 (태그 필터링 지원)

    Args:
        event_type: 이벤트 타입 필터 (alarm/event/memory)
        tags: 쉼표로 구분된 태그 필터
        start_date: 시작 날짜
        end_date: 종료 날짜
        target_type: 대상 유형 필터
        db: Database session
        current_user: Current authenticated user

    Returns:
        일간 이벤트 목록 및 사용 가능한 태그
    """
    try:
        # 태그 파싱
        tag_list = None
        if tags:
            tag_list = [tag.strip() for tag in tags.split(",") if tag.strip()]

        # 이벤트 조회
        events = get_daily_events(
            db,
            current_user.ID,
            event_type=event_type,
            tags=tag_list,
            start_date=start_date,
            end_date=end_date,
            target_type=target_type,
        )

        # 사용 가능한 태그 조회
        popular_tags = get_popular_tags(db, current_user.ID)

        response = DailyEventsListResponse(
            daily_events=[DailyEventResponse.from_orm(event) for event in events],
            total_count=len(events),
            available_tags=popular_tags,
        )

        # 디버깅: 첫 번째 이벤트의 JSON 출력
        if events:
            first_event_json = DailyEventResponse.from_orm(events[0]).model_dump(by_alias=True, mode='json')
            print(f"[DEBUG] First event JSON (as JSON): {first_event_json}")

        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"조회 실패: {str(e)}")


@router.get("/weekly", response_model=WeeklyEventsListResponse)
async def list_weekly_events(
    tags: Optional[str] = Query(
        None, description="쉼표로 구분된 태그 (예: #남편,#약속)"
    ),
    start_date: Optional[date] = Query(None, description="시작 날짜 (YYYY-MM-DD)"),
    end_date: Optional[date] = Query(None, description="종료 날짜 (YYYY-MM-DD)"),
    target_type: Optional[str] = Query(None, description="대상 유형 (husband/son/...)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    주간 이벤트 목록 조회 (태그 필터링 지원)

    Args:
        tags: 쉼표로 구분된 태그 필터
        start_date: 시작 날짜
        end_date: 종료 날짜
        target_type: 대상 유형 필터
        db: Database session
        current_user: Current authenticated user

    Returns:
        주간 이벤트 목록
    """
    try:
        # 태그 파싱
        tag_list = None
        if tags:
            tag_list = [tag.strip() for tag in tags.split(",") if tag.strip()]

        # 이벤트 조회
        events = get_weekly_events(
            db,
            current_user.ID,
            tags=tag_list,
            start_date=start_date,
            end_date=end_date,
            target_type=target_type,
        )

        return WeeklyEventsListResponse(
            weekly_events=[WeeklyEventResponse.from_orm(event) for event in events],
            total_count=len(events),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"조회 실패: {str(e)}")


@router.get("/tags/popular", response_model=PopularTagsResponse)
async def get_popular_tags_endpoint(
    limit: int = Query(20, description="카테고리별 최대 태그 수"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    자주 사용되는 태그 목록 조회

    Args:
        limit: 카테고리별 최대 태그 수
        db: Database session
        current_user: Current authenticated user

    Returns:
        카테고리별 인기 태그
    """
    try:
        tags = get_popular_tags(db, current_user.ID, limit=limit)
        return PopularTagsResponse(**tags)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"태그 조회 실패: {str(e)}")


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "service": "target-events"}

