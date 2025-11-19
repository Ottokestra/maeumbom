"""
Routine Catalog
루틴 카탈로그 데이터 정의

이 파일은 이미 구현되어 있다고 가정합니다.
RoutineItem dataclass와 EMOTION_ROUTINES, TIME_ROUTINES, EXERCISE_ROUTINES, ALL_ROUTINES가 정의되어 있습니다.
"""
from dataclasses import dataclass
from typing import List, Optional

# RoutineItem dataclass 정의
@dataclass
class RoutineItem:
    """루틴 아이템 데이터 클래스"""
    id: str
    title: str
    description: str
    group: str  # 예: "EMOTION_POSITIVE", "TIME_MORNING", "EXERCISE_NECK"
    sub_group: str  # 예: "positive", "morning", "neck"
    tags: List[str]  # 예: ["maintain_positive", "gratitude", "social_activity"]


# 예시 루틴 데이터 (실제로는 더 많은 루틴이 있을 것으로 가정)
EMOTION_ROUTINES: List[RoutineItem] = [
    RoutineItem(
        id="EMO_001",
        title="감사 일기 쓰기",
        description="하루 중 감사했던 일들을 3가지 이상 적어보는 루틴입니다. 긍정적인 감정을 유지하고 강화하는 데 도움이 됩니다.",
        group="EMOTION_POSITIVE",
        sub_group="positive",
        tags=["maintain_positive", "gratitude", "journaling"]
    ),
    RoutineItem(
        id="EMO_002",
        title="가벼운 산책하기",
        description="10-15분 정도의 가벼운 산책으로 몸과 마음을 이완시켜보세요. 자연과 접촉하면 기분 전환에 도움이 됩니다.",
        group="EMOTION_SADNESS",
        sub_group="sadness",
        tags=["sadness", "low_energy", "light_walk", "nature"]
    ),
    RoutineItem(
        id="EMO_003",
        title="심호흡 명상",
        description="5분간 심호흡을 통해 마음을 진정시키는 루틴입니다. 화나 불안한 감정을 완화하는 데 효과적입니다.",
        group="EMOTION_ANGER",
        sub_group="anger",
        tags=["anger", "breathing", "meditation", "calm"]
    ),
    RoutineItem(
        id="EMO_004",
        title="4-7-8 호흡법",
        description="4초 들이쉬고, 7초 멈추고, 8초 내쉬는 호흡법으로 불안과 공포를 완화합니다.",
        group="EMOTION_FEAR",
        sub_group="fear",
        tags=["anxiety", "fear", "breathing", "calm"]
    ),
]

TIME_ROUTINES: List[RoutineItem] = [
    RoutineItem(
        id="TIME_001",
        title="아침 햇빛 받기",
        description="아침에 10분 정도 햇빛을 받으며 상쾌한 하루를 시작하는 루틴입니다.",
        group="TIME_MORNING",
        sub_group="morning",
        tags=["morning", "nature", "energy"]
    ),
    RoutineItem(
        id="TIME_002",
        title="점심 후 가벼운 산책",
        description="점심 식사 후 소화를 돕고 오후 에너지를 충전하는 가벼운 산책 루틴입니다.",
        group="TIME_DAY",
        sub_group="day",
        tags=["day", "light_walk", "digestion"]
    ),
    RoutineItem(
        id="TIME_003",
        title="저녁 명상",
        description="하루를 마무리하며 마음을 차분하게 정리하는 저녁 명상 루틴입니다.",
        group="TIME_EVENING",
        sub_group="evening",
        tags=["evening", "meditation", "calm"]
    ),
]

EXERCISE_ROUTINES: List[RoutineItem] = [
    RoutineItem(
        id="EXE_001",
        title="목 돌리기 스트레칭",
        description="목과 어깨의 긴장을 풀어주는 간단한 스트레칭 루틴입니다.",
        group="BODY_NECK_SHOULDER",
        sub_group="neck",
        tags=["stretching", "tension_release"]
    ),
    RoutineItem(
        id="EXE_002",
        title="고양이-소 자세",
        description="허리와 척추를 부드럽게 움직여주는 요가 자세입니다.",
        group="BODY_LOWER_BACK",
        sub_group="back",
        tags=["stretching", "yoga", "back_pain"]
    ),
    RoutineItem(
        id="EXE_003",
        title="가벼운 유산소 운동",
        description="혈액 순환을 개선하는 가벼운 유산소 운동 루틴입니다.",
        group="BODY_CIRCULATION",
        sub_group="circulation",
        tags=["exercise", "circulation", "energy"]
    ),
]

# 모든 루틴 통합
ALL_ROUTINES: List[RoutineItem] = EMOTION_ROUTINES + TIME_ROUTINES + EXERCISE_ROUTINES

