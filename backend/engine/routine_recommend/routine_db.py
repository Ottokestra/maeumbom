"""
Routine Database
감정/시간대/운동별 루틴 데이터베이스

각 루틴은 dict 형태로 정의되며, 다음 필드를 포함:
- id: 고유 식별자 (예: "POS_001", "DEP_003")
- title: 루틴 제목
- category: 카테고리 (EMOTION_*, TIME_*, BODY_*)
- tags: 감정/상황 태그 리스트
- time_tags: 추천 시간대 리스트 (선택사항: "morning", "day", "evening", "pre_sleep")
- body_part: 신체 부위 (선택사항: "neck", "shoulder", "back", "leg", 등)
"""

from typing import List, Dict, Any, Optional

# ============================================================================
# 루틴 데이터베이스 (현재 60개)
# ============================================================================

ROUTINES: List[Dict[str, Any]] = [
    # ========================================================================
    # 1. 감정 기반 루틴 - 긍정 감정 (EMOTION_POSITIVE)
    # 목표: 긍정적 상태 유지 및 강화
    # ========================================================================
    {
        "id": "POS_001",
        "title": "감사 일기 쓰기",
        "category": "EMOTION_POSITIVE",
        "tags": ["maintain_positive", "gratitude", "journaling"],
        "time_tags": ["morning", "evening"],
        "body_part": None,
    },
    {
        "id": "POS_002",
        "title": "긍정 확언 반복하기",
        "category": "EMOTION_POSITIVE",
        "tags": ["maintain_positive", "self_compassion"],
        "time_tags": ["morning"],
        "body_part": None,
    },
    {
        "id": "POS_003",
        "title": "좋아하는 음악 듣기",
        "category": "EMOTION_POSITIVE",
        "tags": ["maintain_positive", "music", "relaxation"],
        "time_tags": ["day", "evening"],
        "body_part": None,
    },
    {
        "id": "POS_004",
        "title": "친구와 통화하기",
        "category": "EMOTION_POSITIVE",
        "tags": ["maintain_positive", "social_activity", "connection"],
        "time_tags": ["day", "evening"],
        "body_part": None,
    },
    {
        "id": "POS_005",
        "title": "취미 활동 즐기기",
        "category": "EMOTION_POSITIVE",
        "tags": ["maintain_positive", "hobby", "creative"],
        "time_tags": ["day", "evening"],
        "body_part": None,
    },

    # ========================================================================
    # 2. 감정 기반 루틴 - 슬픔 (EMOTION_SADNESS)
    # 목표: 에너지를 낮추지 않으면서 부드러운 위로 제공
    # ========================================================================
    {
        "id": "SAD_001",
        "title": "가벼운 산책하기",
        "category": "EMOTION_SADNESS",
        "tags": ["sadness", "low_energy", "light_walk", "nature"],
        "time_tags": ["morning", "day"],
        "body_part": None,
    },
    {
        "id": "SAD_002",
        "title": "따뜻한 차 마시며 휴식하기",
        "category": "EMOTION_SADNESS",
        "tags": ["sadness", "self_care", "relaxation"],
        "time_tags": ["day", "evening"],
        "body_part": None,
    },
    {
        "id": "SAD_003",
        "title": "감정 일기 쓰기",
        "category": "EMOTION_SADNESS",
        "tags": ["sadness", "journaling", "self_compassion"],
        "time_tags": ["evening", "pre_sleep"],
        "body_part": None,
    },
    {
        "id": "SAD_004",
        "title": "부드러운 스트레칭",
        "category": "EMOTION_SADNESS",
        "tags": ["sadness", "low_energy", "stretching"],
        "time_tags": ["morning", "day"],
        "body_part": None,
    },
    {
        "id": "SAD_005",
        "title": "따뜻한 목욕하기",
        "category": "EMOTION_SADNESS",
        "tags": ["sadness", "self_care", "relaxation"],
        "time_tags": ["evening", "pre_sleep"],
        "body_part": None,
    },

    # ========================================================================
    # 3. 감정 기반 루틴 - 화/분노 (EMOTION_ANGER)
    # 목표: 에너지를 해소하고 이완 유도
    # ========================================================================
    {
        "id": "ANG_001",
        "title": "심호흡 명상",
        "category": "EMOTION_ANGER",
        "tags": ["anger", "breathing", "meditation", "calm"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": None,
    },
    {
        "id": "ANG_002",
        "title": "격렬한 운동 (펀칭, 달리기 등)",
        "category": "EMOTION_ANGER",
        "tags": ["anger", "high_energy", "exercise", "release"],
        "time_tags": ["morning", "day"],
        "body_part": None,
    },
    {
        "id": "ANG_003",
        "title": "차분한 음악 듣기",
        "category": "EMOTION_ANGER",
        "tags": ["anger", "music", "calm", "relaxation"],
        "time_tags": ["day", "evening"],
        "body_part": None,
    },
    {
        "id": "ANG_004",
        "title": "감정 일기 쓰기",
        "category": "EMOTION_ANGER",
        "tags": ["anger", "journaling", "self_compassion"],
        "time_tags": ["evening"],
        "body_part": None,
    },
    {
        "id": "ANG_005",
        "title": "프로그레시브 근육 이완법",
        "category": "EMOTION_ANGER",
        "tags": ["anger", "relaxation", "meditation"],
        "time_tags": ["day", "evening"],
        "body_part": None,
    },

    # ========================================================================
    # 4. 감정 기반 루틴 - 불안/공포 (EMOTION_FEAR)
    # 목표: 즉각적인 진정 및 그라운딩
    # ========================================================================
    {
        "id": "FEA_001",
        "title": "4-7-8 호흡법",
        "category": "EMOTION_FEAR",
        "tags": ["anxiety", "fear", "breathing", "calm"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": None,
    },
    {
        "id": "FEA_002",
        "title": "그라운딩 기법 (5-4-3-2-1)",
        "category": "EMOTION_FEAR",
        "tags": ["anxiety", "fear", "mindfulness", "grounding"],
        "time_tags": ["day", "evening"],
        "body_part": None,
    },
    {
        "id": "FEA_003",
        "title": "가벼운 요가",
        "category": "EMOTION_FEAR",
        "tags": ["anxiety", "fear", "yoga", "calm"],
        "time_tags": ["morning", "day"],
        "body_part": None,
    },
    {
        "id": "FEA_004",
        "title": "안전한 공간 상상하기",
        "category": "EMOTION_FEAR",
        "tags": ["anxiety", "fear", "visualization", "calm"],
        "time_tags": ["day", "evening", "pre_sleep"],
        "body_part": None,
    },
    {
        "id": "FEA_005",
        "title": "부드러운 스트레칭",
        "category": "EMOTION_FEAR",
        "tags": ["anxiety", "fear", "stretching", "relaxation"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": None,
    },

    # ========================================================================
    # 5. 시간대 기반 루틴 - 아침 (TIME_MORNING)
    # 목표: 활력 증진 및 하루 계획
    # ========================================================================
    {
        "id": "MOR_001",
        "title": "아침 햇빛 받기",
        "category": "TIME_MORNING",
        "tags": ["morning", "nature", "energy"],
        "time_tags": ["morning"],
        "body_part": None,
    },
    {
        "id": "MOR_002",
        "title": "아침 스트레칭",
        "category": "TIME_MORNING",
        "tags": ["morning", "stretching", "wake_up"],
        "time_tags": ["morning"],
        "body_part": None,
    },
    {
        "id": "MOR_003",
        "title": "아침 명상",
        "category": "TIME_MORNING",
        "tags": ["morning", "meditation", "mindfulness"],
        "time_tags": ["morning"],
        "body_part": None,
    },
    {
        "id": "MOR_004",
        "title": "아침 산책",
        "category": "TIME_MORNING",
        "tags": ["morning", "light_walk", "nature"],
        "time_tags": ["morning"],
        "body_part": None,
    },
    {
        "id": "MOR_005",
        "title": "아침 감사 일기",
        "category": "TIME_MORNING",
        "tags": ["morning", "gratitude", "journaling"],
        "time_tags": ["morning"],
        "body_part": None,
    },

    # ========================================================================
    # 6. 시간대 기반 루틴 - 낮 (TIME_DAY)
    # 목표: 집중력 유지 및 에너지 보충
    # ========================================================================
    {
        "id": "DAY_001",
        "title": "점심 후 가벼운 산책",
        "category": "TIME_DAY",
        "tags": ["day", "light_walk", "digestion"],
        "time_tags": ["day"],
        "body_part": None,
    },
    {
        "id": "DAY_002",
        "title": "오후 스트레칭",
        "category": "TIME_DAY",
        "tags": ["day", "stretching", "energy"],
        "time_tags": ["day"],
        "body_part": None,
    },
    {
        "id": "DAY_003",
        "title": "오후 차 마시며 휴식",
        "category": "TIME_DAY",
        "tags": ["day", "relaxation", "self_care"],
        "time_tags": ["day"],
        "body_part": None,
    },
    {
        "id": "DAY_004",
        "title": "오후 독서",
        "category": "TIME_DAY",
        "tags": ["day", "reading", "mindfulness"],
        "time_tags": ["day"],
        "body_part": None,
    },
    {
        "id": "DAY_005",
        "title": "오후 음악 감상",
        "category": "TIME_DAY",
        "tags": ["day", "music", "relaxation"],
        "time_tags": ["day"],
        "body_part": None,
    },

    # ========================================================================
    # 7. 시간대 기반 루틴 - 저녁 (TIME_EVENING)
    # 목표: 하루 마무리 및 이완
    # ========================================================================
    {
        "id": "EVE_001",
        "title": "저녁 산책",
        "category": "TIME_EVENING",
        "tags": ["evening", "light_walk", "relaxation"],
        "time_tags": ["evening"],
        "body_part": None,
    },
    {
        "id": "EVE_002",
        "title": "저녁 명상",
        "category": "TIME_EVENING",
        "tags": ["evening", "meditation", "calm"],
        "time_tags": ["evening"],
        "body_part": None,
    },
    {
        "id": "EVE_003",
        "title": "저녁 일기 쓰기",
        "category": "TIME_EVENING",
        "tags": ["evening", "journaling", "reflection"],
        "time_tags": ["evening"],
        "body_part": None,
    },
    {
        "id": "EVE_004",
        "title": "저녁 스트레칭",
        "category": "TIME_EVENING",
        "tags": ["evening", "stretching", "relaxation"],
        "time_tags": ["evening"],
        "body_part": None,
    },
    {
        "id": "EVE_005",
        "title": "저녁 따뜻한 목욕",
        "category": "TIME_EVENING",
        "tags": ["evening", "self_care", "relaxation"],
        "time_tags": ["evening"],
        "body_part": None,
    },

    # ========================================================================
    # 8. 신체 부위 기반 루틴 - 목/어깨 (BODY_NECK_SHOULDER)
    # 목표: 긴장 완화 및 통증 해소
    # ========================================================================
    {
        "id": "NEC_001",
        "title": "목 돌리기 스트레칭",
        "category": "BODY_NECK_SHOULDER",
        "tags": ["stretching", "tension_release"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "neck",
    },
    {
        "id": "NEC_002",
        "title": "어깨 돌리기 운동",
        "category": "BODY_NECK_SHOULDER",
        "tags": ["stretching", "tension_release"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "shoulder",
    },
    {
        "id": "NEC_003",
        "title": "목 옆으로 기울이기",
        "category": "BODY_NECK_SHOULDER",
        "tags": ["stretching", "tension_release"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "neck",
    },
    {
        "id": "NEC_004",
        "title": "어깨 들어올리기",
        "category": "BODY_NECK_SHOULDER",
        "tags": ["stretching", "tension_release"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "shoulder",
    },
    {
        "id": "NEC_005",
        "title": "목과 어깨 통합 스트레칭",
        "category": "BODY_NECK_SHOULDER",
        "tags": ["stretching", "tension_release"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "neck",
    },

    # ========================================================================
    # 9. 신체 부위 기반 루틴 - 허리 (BODY_LOWER_BACK)
    # 목표: 허리 통증 완화 및 유연성 증가
    # ========================================================================
    {
        "id": "BAC_001",
        "title": "고양이-소 자세",
        "category": "BODY_LOWER_BACK",
        "tags": ["stretching", "yoga", "back_pain"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "back",
    },
    {
        "id": "BAC_002",
        "title": "무릎 가슴 당기기",
        "category": "BODY_LOWER_BACK",
        "tags": ["stretching", "back_pain"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "back",
    },
    {
        "id": "BAC_003",
        "title": "허리 옆으로 기울이기",
        "category": "BODY_LOWER_BACK",
        "tags": ["stretching", "back_pain"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "back",
    },
    {
        "id": "BAC_004",
        "title": "허리 뒤로 젖히기",
        "category": "BODY_LOWER_BACK",
        "tags": ["stretching", "back_pain"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "back",
    },
    {
        "id": "BAC_005",
        "title": "허리 회전 운동",
        "category": "BODY_LOWER_BACK",
        "tags": ["stretching", "back_pain"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "back",
    },

    # ========================================================================
    # 10. 신체 부위 기반 루틴 - 다리 (BODY_LEG)
    # 목표: 혈액 순환 및 피로 해소
    # ========================================================================
    {
        "id": "LEG_001",
        "title": "종아리 스트레칭",
        "category": "BODY_LEG",
        "tags": ["stretching", "circulation"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "leg",
    },
    {
        "id": "LEG_002",
        "title": "허벅지 앞쪽 스트레칭",
        "category": "BODY_LEG",
        "tags": ["stretching"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "leg",
    },
    {
        "id": "LEG_003",
        "title": "허벅지 뒤쪽 스트레칭",
        "category": "BODY_LEG",
        "tags": ["stretching"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "leg",
    },
    {
        "id": "LEG_004",
        "title": "발목 돌리기",
        "category": "BODY_LEG",
        "tags": ["stretching", "circulation"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "leg",
    },
    {
        "id": "LEG_005",
        "title": "다리 올리기 운동",
        "category": "BODY_LEG",
        "tags": ["stretching", "circulation"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "leg",
    },

    # ========================================================================
    # 11. 신체 부위 기반 루틴 - 순환 (BODY_CIRCULATION)
    # 목표: 전신 혈액 순환 및 활성화
    # ========================================================================
    {
        "id": "CIR_001",
        "title": "가벼운 유산소 운동",
        "category": "BODY_CIRCULATION",
        "tags": ["exercise", "circulation", "energy"],
        "time_tags": ["morning", "day"],
        "body_part": None,
    },
    {
        "id": "CIR_002",
        "title": "제자리 걷기",
        "category": "BODY_CIRCULATION",
        "tags": ["exercise", "circulation", "light_walk"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": None,
    },
    {
        "id": "CIR_003",
        "title": "다리 펌프 운동",
        "category": "BODY_CIRCULATION",
        "tags": ["exercise", "circulation"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "leg",
    },
    {
        "id": "CIR_004",
        "title": "팔 원형 운동",
        "category": "BODY_CIRCULATION",
        "tags": ["exercise", "circulation"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": "shoulder",
    },
    {
        "id": "CIR_005",
        "title": "가벼운 점프 운동",
        "category": "BODY_CIRCULATION",
        "tags": ["exercise", "circulation", "energy"],
        "time_tags": ["morning", "day"],
        "body_part": None,
    },

    # ========================================================================
    # 12. 신체 부위 기반 루틴 - 균형 (BODY_BALANCE)
    # 목표: 균형 감각 및 안정성 향상
    # ========================================================================
    {
        "id": "BAL_001",
        "title": "한 발 서기",
        "category": "BODY_BALANCE",
        "tags": ["balance", "stability"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": None,
    },
    {
        "id": "BAL_002",
        "title": "나무 자세",
        "category": "BODY_BALANCE",
        "tags": ["balance", "yoga", "stability"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": None,
    },
    {
        "id": "BAL_003",
        "title": "발가락-발뒤꿈치 걷기",
        "category": "BODY_BALANCE",
        "tags": ["balance", "stability"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": None,
    },
    {
        "id": "BAL_004",
        "title": "균형 스트레칭",
        "category": "BODY_BALANCE",
        "tags": ["balance", "stretching", "stability"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": None,
    },
    {
        "id": "BAL_005",
        "title": "의자에 앉아 균형 운동",
        "category": "BODY_BALANCE",
        "tags": ["balance", "stability", "safe"],
        "time_tags": ["morning", "day", "evening"],
        "body_part": None,
    },
]

# ============================================================================
# 유틸리티 함수
# ============================================================================

def get_routine_by_id(routine_id: str) -> Optional[Dict[str, Any]]:
    """
    ID로 루틴 조회

    Args:
        routine_id: 루틴 ID

    Returns:
        루틴 dict 또는 None
    """
    for routine in ROUTINES:
        if routine["id"] == routine_id:
            return routine
    return None


def get_routines_by_category(category: str) -> List[Dict[str, Any]]:
    """
    카테고리로 루틴 조회

    Args:
        category: 카테고리 (예: "EMOTION_POSITIVE", "TIME_MORNING")

    Returns:
        해당 카테고리의 루틴 리스트
    """
    return [r for r in ROUTINES if r["category"] == category]


def get_routines_by_tag(tag: str) -> List[Dict[str, Any]]:
    """
    태그로 루틴 조회

    Args:
        tag: 태그 (예: "sadness", "morning", "stretching")

    Returns:
        해당 태그를 가진 루틴 리스트
    """
    return [r for r in ROUTINES if tag in r.get("tags", [])]


def get_routines_by_time_tag(time_tag: str) -> List[Dict[str, Any]]:
    """
    시간대 태그로 루틴 조회

    Args:
        time_tag: 시간대 태그 ("morning", "day", "evening", "pre_sleep")

    Returns:
        해당 시간대에 추천되는 루틴 리스트
    """
    return [r for r in ROUTINES if time_tag in r.get("time_tags", [])]


def get_routines_by_body_part(body_part: str) -> List[Dict[str, Any]]:
    """
    신체 부위로 루틴 조회

    Args:
        body_part: 신체 부위 ("neck", "shoulder", "back", "leg", 등)

    Returns:
        해당 신체 부위 루틴 리스트
    """
    return [r for r in ROUTINES if r.get("body_part") == body_part]