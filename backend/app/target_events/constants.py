"""
태그 카테고리 및 상수 정의
Constants for tag categories and event types
"""

# 대상 태그 (Target Tags) - TB_SCENARIOS와 동일한 형식
TARGET_TAGS = {
    "HUSBAND": "#남편",
    "CHILD": "#자녀",  # son, daughter 통합
    "FRIEND": "#친구",
    "COLLEAGUE": "#직장동료",
    "SELF": "#나",  # 봄이와 대화, 알람 등
}

# 대상 타입 역매핑 (한글 -> 영문)
TARGET_TYPE_REVERSE = {v: k for k, v in TARGET_TAGS.items()}

# 이벤트 유형 태그 (Event Type Tags)
EVENT_TYPE_TAGS = [
    "#약속",
    "#픽업",
    "#만남",
    "#식사",
    "#통화예정",
    "#기념일",
    "#알림요청",
    "#중요대화",
]

# 시간 태그 (Time Tags)
TIME_TAGS = ["#오늘", "#내일", "#이번주", "#다음주", "#이번달", "#과거"]

# 중요도 태그 (Importance Tags)
IMPORTANCE_TAGS = {
    5: "#매우중요",
    4: "#중요",
    3: "#보통",
    2: "#보통",
    1: "#보통",
}

# 감정 태그 (Emotion Tags) - 선택적
EMOTION_TAGS = ["#긍정적", "#부정적", "#걱정", "#기대"]

# 이벤트 타입 (Event Types)
EVENT_TYPES = {
    "alarm": "알람",
    "event": "일정",
    "memory": "기억"
}

EVENT_TYPE_ALARM = "alarm"  # 알람/알림 요청
EVENT_TYPE_EVENT = "event"  # 약속/일정 (기본값)
EVENT_TYPE_MEMORY = "memory"  # 일반 대화 기억

# 모든 태그 목록
ALL_TAGS = (
    list(TARGET_TAGS.values())
    + EVENT_TYPE_TAGS
    + TIME_TAGS
    + list(set(IMPORTANCE_TAGS.values()))
    + EMOTION_TAGS
)

