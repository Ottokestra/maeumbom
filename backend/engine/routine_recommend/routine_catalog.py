"""
Routine Catalog
루틴 카탈로그 데이터 정의

※ 이 파일은 routine_db.ROUTINES(60개)를 기준으로
   RoutineItem(dataclass) 리스트를 생성하는 래퍼입니다.
   👉 루틴 데이터를 추가/수정할 때는 항상 routine_db.py의 ROUTINES만 수정하면 됩니다.
"""

from dataclasses import dataclass
from typing import List, Optional

from .routine_db import ROUTINES  # 같은 패키지 안에 있으니 상대 import


@dataclass
class RoutineItem:
    """루틴 아이템 데이터 클래스"""
    id: str
    title: str
    description: str
    group: str        # 예: "EMOTION_POSITIVE", "TIME_MORNING", "BODY_NECK_SHOULDER"
    sub_group: str    # 예: "positive", "morning", "neck" 등 (보조 분류)
    tags: List[str]   # 예: ["maintain_positive", "gratitude", "social_activity"]


def _infer_sub_group(category: str, time_tags: Optional[List[str]], body_part: Optional[str]) -> str:
    """
    category / time_tags / body_part 를 보고 sub_group 대략 유추.
    - EMOTION_*  : 카테고리 뒷부분 소문자(ex. EMOTION_POSITIVE → "positive")
    - TIME_*     : time_tags가 있으면 첫 번째(ex. "morning"), 없으면 "time"
    - BODY_*     : body_part가 있으면 그대로, 없으면 "body"
    """
    if category.startswith("EMOTION_"):
        return category.split("_", 1)[1].lower()  # POSITIVE, SADNESS ...
    if category.startswith("TIME_"):
        if time_tags:
            return time_tags[0]
        return "time"
    if category.startswith("BODY_"):
        if body_part:
            return body_part
        return "body"
    # 그 외 카테고리
    return "other"


def _default_description(title: str, category: str) -> str:
    """
    routine_db에는 description이 없으니까
    기본 설명 문장을 가볍게 만들어준다.
    필요하면 나중에 개별 루틴에 맞게 교체 가능.
    """
    if category.startswith("EMOTION_"):
        return f'"{title}" 루틴은 현재 감정을 돌보고 안정시키는 데 도움이 됩니다.'
    if category.startswith("TIME_"):
        return f'"{title}" 루틴은 해당 시간대에 실천하면 하루 리듬을 정리하는 데 도움이 됩니다.'
    if category.startswith("BODY_"):
        return f'"{title}" 루틴은 몸의 긴장을 풀고 컨디션을 관리하는 데 도움이 됩니다.'
    return f'"{title}" 루틴을 지금 상황에 맞게 가볍게 실천해 보세요.'


# ---------------------------------------------------------------------------
# ROUTINES(60개)를 RoutineItem 리스트로 변환
# ---------------------------------------------------------------------------
ALL_ROUTINES: List[RoutineItem] = []

for r in ROUTINES:
    category: str = r["category"]
    tags: List[str] = list(r.get("tags", []))
    time_tags = r.get("time_tags")
    body_part = r.get("body_part")

    item = RoutineItem(
        id=r["id"],
        title=r["title"],
        description=_default_description(r["title"], category),
        group=category,
        sub_group=_infer_sub_group(category, time_tags, body_part),
        tags=tags,
    )
    ALL_ROUTINES.append(item)


# 카테고리별 편의 리스트 (원하면 사용)
EMOTION_ROUTINES: List[RoutineItem] = [
    r for r in ALL_ROUTINES if r.group.startswith("EMOTION_")
]

TIME_ROUTINES: List[RoutineItem] = [
    r for r in ALL_ROUTINES if r.group.startswith("TIME_")
]

EXERCISE_ROUTINES: List[RoutineItem] = [
    r for r in ALL_ROUTINES if r.group.startswith("BODY_")
]
