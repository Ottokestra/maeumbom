"""
대상별 이벤트 비즈니스 로직
Business logic for target-specific event analysis and management
"""
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
from datetime import date, timedelta, datetime
from typing import List, Optional, Dict, Any

from app.db.models import DailyTargetEvent, WeeklyTargetEvent, Conversation
from .analyzer import TargetEventAnalyzer
from .constants import TARGET_TAGS


def analyze_daily_events(
    db: Session, user_id: int, target_date: date, created_by: Optional[int] = None
) -> List[DailyTargetEvent]:
    """
    일일 대화 분석 및 이벤트 저장

    Args:
        db: Database session
        user_id: User ID
        target_date: Target date to analyze
        created_by: Creator user ID (optional)

    Returns:
        List of created DailyTargetEvent objects
    """
    # 1. 해당 날짜의 대화 조회 (삭제되지 않은 것만)
    start_datetime = datetime.combine(target_date, datetime.min.time())
    end_datetime = datetime.combine(target_date, datetime.max.time())

    conversations = (
        db.query(Conversation)
        .filter(
            and_(
                Conversation.USER_ID == user_id,
                Conversation.CREATED_AT >= start_datetime,
                Conversation.CREATED_AT <= end_datetime,
            )
        )
        .order_by(Conversation.CREATED_AT)
        .all()
    )

    if not conversations:
        print(f"[INFO] No conversations found for user {user_id} on {target_date}")
        return []

    # 2. 대화를 딕셔너리 형태로 변환
    conversation_dicts = [
        {
            "id": conv.ID,
            "content": conv.CONTENT,
            "speaker_type": conv.SPEAKER_TYPE,
            "created_at": conv.CREATED_AT,
        }
        for conv in conversations
    ]

    # 3. LLM 분석
    analyzer = TargetEventAnalyzer()
    extracted_events = analyzer.analyze_daily_conversations(
        conversation_dicts, target_date
    )

    if not extracted_events:
        print(f"[INFO] No events extracted for user {user_id} on {target_date}")
        return []

    # 4. 기존 이벤트 삭제 (같은 날짜, 같은 사용자)
    db.query(DailyTargetEvent).filter(
        and_(
            DailyTargetEvent.USER_ID == user_id,
            DailyTargetEvent.EVENT_DATE == target_date,
        )
    ).delete()

    # 5. DB 저장
    created_events = []
    for event_data in extracted_events:
        event_type = event_data.get("event_type", "event")
        target_type = event_data.get("target_type", "SELF")
        
        # 알람은 무조건 SELF로 설정
        if event_type == "alarm":
            target_type = "SELF"
        
        event = DailyTargetEvent(
            USER_ID=user_id,
            EVENT_DATE=target_date,  # 무조건 분석 날짜로 저장
            EVENT_TYPE=event_type,
            TARGET_TYPE=target_type,
            EVENT_SUMMARY=event_data.get("event_summary", ""),
            EVENT_TIME=event_data.get("event_time"),
            IMPORTANCE=event_data.get("importance", 3),
            IS_FUTURE_EVENT=event_data.get("is_future_event", False),
            TAGS=event_data.get("tags", []),
            RAW_CONVERSATION_IDS=event_data.get("conversation_ids", []),
            CREATED_BY=created_by or user_id,
        )
        db.add(event)
        created_events.append(event)

    db.commit()

    # Refresh to get IDs
    for event in created_events:
        db.refresh(event)

    print(
        f"[INFO] Created {len(created_events)} events for user {user_id} on {target_date}"
    )
    return created_events


def analyze_weekly_events(
    db: Session,
    user_id: int,
    week_start: date,
    created_by: Optional[int] = None,
) -> List[WeeklyTargetEvent]:
    """
    주간 이벤트 요약 및 저장

    Args:
        db: Database session
        user_id: User ID
        week_start: Week start date (Monday)
        created_by: Creator user ID (optional)

    Returns:
        List of created WeeklyTargetEvent objects
    """
    # 1. 주 종료일 계산 (일요일)
    week_end = week_start + timedelta(days=6)

    # 2. 해당 주의 일간 이벤트 조회
    daily_events = (
        db.query(DailyTargetEvent)
        .filter(
            and_(
                DailyTargetEvent.USER_ID == user_id,
                DailyTargetEvent.EVENT_DATE >= week_start,
                DailyTargetEvent.EVENT_DATE <= week_end,
                DailyTargetEvent.IS_DELETED == False,
            )
        )
        .order_by(DailyTargetEvent.EVENT_DATE)
        .all()
    )

    if not daily_events:
        print(
            f"[INFO] No daily events found for user {user_id} for week {week_start}"
        )
        return []

    # 3. 대상별로 그룹화
    events_by_target = {}
    for event in daily_events:
        target_type = event.TARGET_TYPE
        if target_type not in events_by_target:
            events_by_target[target_type] = []
        events_by_target[target_type].append(event)

    # 4. 기존 주간 이벤트 삭제
    db.query(WeeklyTargetEvent).filter(
        and_(
            WeeklyTargetEvent.USER_ID == user_id,
            WeeklyTargetEvent.WEEK_START == week_start,
        )
    ).delete()

    # 5. 대상별로 LLM 요약 및 저장
    analyzer = TargetEventAnalyzer()
    created_summaries = []

    for target_type, events in events_by_target.items():
        # 이벤트를 딕셔너리로 변환
        event_dicts = [
            {
                "event_date": event.EVENT_DATE.isoformat(),
                "event_summary": event.EVENT_SUMMARY,
                "event_time": (
                    event.EVENT_TIME.isoformat() if event.EVENT_TIME else None
                ),
                "importance": event.IMPORTANCE,
                "tags": event.TAGS or [],
            }
            for event in events
        ]

        # LLM 요약
        summary_data = analyzer.summarize_weekly_events(
            event_dicts, target_type, week_start
        )

        # DB 저장
        weekly_event = WeeklyTargetEvent(
            USER_ID=user_id,
            WEEK_START=week_start,
            WEEK_END=week_end,
            TARGET_TYPE=target_type,
            EVENTS_SUMMARY=summary_data.get("events_summary", []),
            TOTAL_EVENTS=summary_data.get("total_events", 0),
            TAGS=summary_data.get("tags", []),
            CREATED_BY=created_by or user_id,
        )
        db.add(weekly_event)
        created_summaries.append(weekly_event)

    db.commit()

    # Refresh to get IDs
    for summary in created_summaries:
        db.refresh(summary)

    print(
        f"[INFO] Created {len(created_summaries)} weekly summaries for user {user_id} for week {week_start}"
    )
    return created_summaries


def get_daily_events(
    db: Session,
    user_id: int,
    event_type: Optional[str] = None,
    tags: Optional[List[str]] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    target_type: Optional[str] = None,
) -> List[DailyTargetEvent]:
    """
    일간 이벤트 조회 (태그 필터링 지원)

    Args:
        db: Database session
        user_id: User ID
        event_type: Event type filter (alarm/event/memory) (optional)
        tags: Tag filters (optional)
        start_date: Start date (optional)
        end_date: End date (optional)
        target_type: Target type filter (optional)

    Returns:
        List of DailyTargetEvent objects
    """
    query = db.query(DailyTargetEvent).filter(
        and_(
            DailyTargetEvent.USER_ID == user_id,
            DailyTargetEvent.IS_DELETED == False,
        )
    )

    # 이벤트 타입 필터
    if event_type:
        query = query.filter(DailyTargetEvent.EVENT_TYPE == event_type)

    # 날짜 필터
    if start_date:
        query = query.filter(DailyTargetEvent.EVENT_DATE >= start_date)
    if end_date:
        query = query.filter(DailyTargetEvent.EVENT_DATE <= end_date)

    # 대상 필터
    if target_type:
        query = query.filter(DailyTargetEvent.TARGET_TYPE == target_type)

    # 태그 필터 (JSON 컬럼 검색)
    if tags:
        # PostgreSQL/MySQL JSON 검색
        tag_conditions = []
        for tag in tags:
            # JSON_CONTAINS 또는 JSON_SEARCH 사용
            # SQLite는 JSON 함수 제한적이므로 Python에서 필터링
            tag_conditions.append(
                func.json_contains(DailyTargetEvent.TAGS, f'"{tag}"')
            )
        if tag_conditions:
            query = query.filter(or_(*tag_conditions))

    query = query.order_by(DailyTargetEvent.EVENT_DATE.desc())

    events = query.all()

    # SQLite 등에서 JSON 필터링이 안 되는 경우 Python에서 필터링
    if tags:
        filtered_events = []
        for event in events:
            if event.TAGS:
                event_tags = event.TAGS if isinstance(event.TAGS, list) else []
                if any(tag in event_tags for tag in tags):
                    filtered_events.append(event)
        events = filtered_events

    return events


def get_weekly_events(
    db: Session,
    user_id: int,
    tags: Optional[List[str]] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    target_type: Optional[str] = None,
) -> List[WeeklyTargetEvent]:
    """
    주간 이벤트 조회 (태그 필터링 지원)

    Args:
        db: Database session
        user_id: User ID
        tags: Tag filters (optional)
        start_date: Start date (optional)
        end_date: End date (optional)
        target_type: Target type filter (optional)

    Returns:
        List of WeeklyTargetEvent objects
    """
    query = db.query(WeeklyTargetEvent).filter(
        and_(
            WeeklyTargetEvent.USER_ID == user_id,
            WeeklyTargetEvent.IS_DELETED == False,
        )
    )

    # 날짜 필터
    if start_date:
        query = query.filter(WeeklyTargetEvent.WEEK_START >= start_date)
    if end_date:
        query = query.filter(WeeklyTargetEvent.WEEK_START <= end_date)

    # 대상 필터
    if target_type:
        query = query.filter(WeeklyTargetEvent.TARGET_TYPE == target_type)

    query = query.order_by(WeeklyTargetEvent.WEEK_START.desc())

    events = query.all()

    # 태그 필터 (Python에서 처리)
    if tags:
        filtered_events = []
        for event in events:
            if event.TAGS:
                event_tags = event.TAGS if isinstance(event.TAGS, list) else []
                if any(tag in event_tags for tag in tags):
                    filtered_events.append(event)
        events = filtered_events

    return events


def get_popular_tags(
    db: Session, user_id: int, limit: int = 20
) -> Dict[str, List[str]]:
    """
    자주 사용되는 태그 목록 조회

    Args:
        db: Database session
        user_id: User ID
        limit: Maximum number of tags per category

    Returns:
        Dictionary of popular tags by category
    """
    # 최근 30일 이벤트 조회
    thirty_days_ago = date.today() - timedelta(days=30)

    events = (
        db.query(DailyTargetEvent)
        .filter(
            and_(
                DailyTargetEvent.USER_ID == user_id,
                DailyTargetEvent.EVENT_DATE >= thirty_days_ago,
                DailyTargetEvent.IS_DELETED == False,
            )
        )
        .all()
    )

    # 태그 빈도 계산
    tag_counts = {}
    for event in events:
        if event.TAGS:
            tags = event.TAGS if isinstance(event.TAGS, list) else []
            for tag in tags:
                tag_counts[tag] = tag_counts.get(tag, 0) + 1

    # 빈도순 정렬
    sorted_tags = sorted(tag_counts.items(), key=lambda x: x[1], reverse=True)

    # 카테고리별 분류
    target_tags = []
    event_type_tags = []
    time_tags = []
    importance_tags = []
    other_tags = []

    for tag, count in sorted_tags[:limit * 2]:  # 여유있게 가져오기
        if tag in TARGET_TAGS.values():
            target_tags.append(tag)
        elif tag in ["#약속", "#픽업", "#만남", "#식사", "#통화예정", "#기념일", "#알림요청", "#중요대화"]:
            event_type_tags.append(tag)
        elif tag in ["#오늘", "#내일", "#이번주", "#다음주", "#이번달", "#과거"]:
            time_tags.append(tag)
        elif tag in ["#매우중요", "#중요", "#보통"]:
            importance_tags.append(tag)
        else:
            other_tags.append(tag)

    return {
        "target": target_tags[:limit],
        "event_type": event_type_tags[:limit],
        "time": time_tags[:limit],
        "importance": importance_tags[:limit],
        "other": other_tags[:limit],
        "all": [tag for tag, _ in sorted_tags[:limit]],
    }

