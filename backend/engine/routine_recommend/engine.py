"""
Routine Recommendation Engine (RAG + LLM)
감정 분석 결과를 기반으로 루틴을 추천하는 최종 엔진
"""

from typing import List, Optional, Dict
import random

from .models.schemas import (
    EmotionAnalysisResult,
    RoutineRecommendationItem,
    RoutineCandidate,  # ✅ 후보 타입도 같이 사용
)
from .routine_rag import retrieve_candidates
from .llm_selector import select_and_explain_routines

# 날씨 서비스 import
import sys
from pathlib import Path

# backend 경로를 sys.path에 추가 (app 모듈 import를 위해)
backend_path = Path(__file__).parent.parent.parent
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

from app.weather.service import get_current_weather_info


# 개인화 시간 슬롯 -> time_tag / 카테고리 매핑
PERSONAL_SLOT_TO_TIME_TAGS = {
    "morning": ["morning"],
    "day": ["day"],
    "evening": ["evening"],
    "sleep_prep": ["pre_sleep"],
}

PERSONAL_SLOT_TO_TIME_CATEGORIES = {
    "morning": ["TIME_MORNING"],
    "day": ["TIME_DAY"],
    "evening": ["TIME_EVENING"],
    # 취침 준비 전용 카테고리가 없다면, pre_sleep 태그를 가진 루틴 중심으로 필터
    "sleep_prep": ["TIME_EVENING"],
}

# 🌦️ 날씨에 따라 막을 야외 태그/키워드
OUTDOOR_TAGS = {"light_walk", "nature", "outdoor"}
OUTDOOR_KEYWORDS_KO = {"산책", "걷기", "외출", "야외"}


class RoutineRecommendFromEmotionEngine:
    """
    감정 분석 결과를 기반으로 루틴을 추천하는 엔진

    프로세스:
    1. RAG를 사용하여 ChromaDB에서 관련 루틴 후보 15~20개 검색
    2. (선택) 날씨 정보 조회 후, 비/눈/뇌우일 때 야외 루틴 후보 제거
    3. 후보를 셔플한 뒤, 일부를 LLM에 전달해 reason/ui_message 생성
    4. 시간대 기준으로 TIME 루틴 최대 1개만 유지
    5. 카테고리(감정/신체/시간대)별로 섞어서,
       비슷한 것 겹치지 않게 랜덤 샘플링으로
       → 3개씩 3세트(최대 9개) 반환
    """

    def __init__(self):
        """엔진 초기화"""
        pass

    async def recommend(
        self,
        emotion: EmotionAnalysisResult,
        *,
        max_recommend: int = 3,          # 한 세트 당 3개
        rag_top_k: int = 20,             # ✅ 15~20개 넉넉히 뽑기 (기본 20)
        hours_since_wake: Optional[float] = None,
        hours_to_sleep: Optional[float] = None,
        city: Optional[str] = None,      # 🌦️ 날씨 정보를 위한 도시 이름
        country: str = "KR",             # 🌦️ 국가 코드
    ) -> List[RoutineRecommendationItem]:
        """
        감정 분석 결과를 기반으로 루틴을 추천합니다.

        Args:
            emotion: 감정 분석 결과
            max_recommend: 한 세트의 추천 개수 (기본 3개)
            rag_top_k: RAG에서 가져올 후보 수 (15~20 권장)
            hours_since_wake: 기상 후 경과 시간 (예: 2.5)
            hours_to_sleep: 예상 취침까지 남은 시간 (선택)
            city: 날씨 정보를 조회할 도시 이름 (선택, 예: "Seoul")
            country: 국가 코드 (기본 "KR")

        Returns:
            추천된 루틴 리스트 (reason, ui_message 포함)
            - 최대 9개 (3개 × 3세트)
            - 프론트에서 3개씩 슬라이스해서 사용
        """
        # 🌦️ 0) 날씨 정보 조회 (city가 제공된 경우)
        weather_info = None
        weather_tag = None

        if city:
            try:
                print(f"날씨 정보 조회 중... (city={city}, country={country})")
                weather_info = await get_current_weather_info(city=city, country=country)
                # ✅ 필드 이름 수정: temperature_c
                print(f"날씨 조회 완료: {weather_info.condition}, {weather_info.temperature_c}°C")

                # 날씨 condition을 태그로 변환 (예: clear → weather_clear)
                weather_tag = f"weather_{weather_info.condition}"

                # emotion 객체의 recommended_routine_tags에 날씨 태그 추가 (검색 힌트)
                if hasattr(emotion, "recommended_routine_tags"):
                    if emotion.recommended_routine_tags is None:
                        emotion.recommended_routine_tags = []
                    if weather_tag not in emotion.recommended_routine_tags:
                        emotion.recommended_routine_tags.append(weather_tag)
                        print(f"날씨 태그 추가됨: {weather_tag}")

            except Exception as e:
                print(f"날씨 정보 조회 실패 (무시하고 계속): {e}")
                # 날씨 조회 실패해도 루틴 추천은 계속 진행

        # 1) 현재 개인화 시간 슬롯 계산
        slot = self._infer_personal_time_slot(
            hours_since_wake=hours_since_wake,
            hours_to_sleep=hours_to_sleep,
        )
        print(f"개인화 시간 슬롯: {slot}")

        # 2) RAG로 후보 검색 (15~20개 정도 넉넉하게)
        print("RAG 검색 중...")
        candidates = retrieve_candidates(emotion, top_k=rag_top_k)
        print(f"후보 {len(candidates)}개 검색 완료")

        if not candidates:
            print("RAG 후보가 없어 추천을 생성할 수 없습니다.")
            return []

        # 🌦️ 2-1) 날씨 기반 야외 루틴 필터링
        if weather_info is not None:
            before_count = len(candidates)
            candidates = self._filter_candidates_by_weather(
                candidates=candidates,
                weather=weather_info,
            )
            after_count = len(candidates)
            print(
                f"날씨 필터 적용: {before_count} → {after_count}개 "
                f"(condition={weather_info.condition}, is_rainy={weather_info.is_rainy})"
            )

        if not candidates:
            print("날씨 필터 후 후보가 없어 추천을 생성할 수 없습니다.")
            return []

        # 후보 순서를 먼저 셔플해서 항상 같은 조합만 나오지 않게
        random.shuffle(candidates)

        # 3) LLM에 넘길 후보 수 제한
        #    - 너무 많으면 느려지니, 최종 추천의 2~3배 정도만 사용
        llm_max_recommend = max_recommend * 3          # LLM이 최대 9개 정도 골라보게 (fallback용)
        max_for_llm = min(len(candidates), max_recommend * 9)  # 입력 후보는 최대 27개 정도
        candidates_for_llm = candidates[:max_for_llm]

        print(
            f"LLM으로 최종 추천 생성 중... "
            f"(LLM 입력 후보 {len(candidates_for_llm)}개, "
            f"LLM 최대 추천 {llm_max_recommend}개)"
        )

        # 4) LLM으로 1차 추천 + reason/ui_message 생성
        recommendations = select_and_explain_routines(
            emotion=emotion,
            candidates=candidates_for_llm,
            max_recommend=llm_max_recommend,
        )
        print(f"LLM 1차 추천 {len(recommendations)}개 생성 완료")

        if not recommendations:
            return []

        # 5) 시간대 제약 적용 (TIME_* 루틴은 현재 슬롯과 맞는 것만 + 최대 1개)
        recommendations = self._apply_time_slot_constraints(
            recommendations=recommendations,
            slot=slot,
        )
        print(f"시간대 제약 적용 후 {len(recommendations)}개")

        if not recommendations:
            return []

        # 6) 카테고리별로 섞고, 비슷한 것 안 겹치게
        #    3개씩 3세트(최대 9개) 뽑기
        all_sets: List[List[RoutineRecommendationItem]] = []
        pool = recommendations[:]  # 작업용 리스트 복사

        for set_idx in range(3):  # 최대 3세트
            if not pool:
                break

            picked = self._pick_diverse_routines(
                recommendations=pool,
                max_recommend=max_recommend,  # 한 세트당 3개
            )

            if not picked:
                break

            all_sets.append(picked)

            # 이번에 뽑힌 루틴은 다음 세트에서 제외
            picked_ids = {item.routine_id for item in picked}
            pool = [item for item in pool if item.routine_id not in picked_ids]

        # 세트들을 하나로 이어붙이기
        final: List[RoutineRecommendationItem] = [
            item for one_set in all_sets for item in one_set
        ]
        # 🔥 우선순위 기준으로 정렬 (1,2,3,... 순)
        final.sort(key=lambda x: x.priority)

        print(
            f"카테고리 다양성 적용 후 최종 {len(final)}개 "
            f"({len(all_sets)} 세트, 세트별 개수: {[len(s) for s in all_sets]})"
        )

        return final

    # ------------------------------------------------------------------
    # 🌦️ 날씨 기반 후보 필터링
    # ------------------------------------------------------------------
    def _filter_candidates_by_weather(
        self,
        candidates: List[RoutineCandidate],
        weather,
    ) -> List[RoutineCandidate]:
        """
        날씨에 따라 야외/산책 계열 루틴을 걸러냅니다.

        - 비/눈/뇌우 등일 때:
          tags나 제목/설명에 산책/야외 관련이 있는 후보는 제외.
        - 맑음/구름 정도면 그대로 둠.
        """
        # 비/눈/뇌우 계열이면 야외 루틴 제한
        bad_for_outdoor = bool(
            getattr(weather, "is_rainy", False)
            or getattr(weather, "condition", "") in {"rain", "drizzle", "thunderstorm", "snow"}
        )

        if not bad_for_outdoor:
            # 날씨 괜찮으면 필터링 안 함
            return candidates

        filtered: List[RoutineCandidate] = []
        for c in candidates:
            tags = set(c.tags or [])
            text_for_check = (c.title or "") + " " + (c.description or "")

            has_outdoor_tag = bool(tags & OUTDOOR_TAGS)
            has_outdoor_keyword = any(k in text_for_check for k in OUTDOOR_KEYWORDS_KO)

            # 야외/산책 루틴이면 제외
            if has_outdoor_tag or has_outdoor_keyword:
                print(f"  - 날씨 때문에 제외: {c.id} ({c.title})")
                continue

            filtered.append(c)

        return filtered

    # ------------------------------------------------------------------
    # 개인화 시간 슬롯 판별
    # ------------------------------------------------------------------
    def _infer_personal_time_slot(
        self,
        *,
        hours_since_wake: Optional[float],
        hours_to_sleep: Optional[float],
    ) -> Optional[str]:
        """
        개인화 시간 슬롯을 판별합니다.

        - 개인화 아침: 기상 후 2~3시간  → "morning"
        - 개인화 낮:   기상 후 3~10시간 → "day"
        - 개인화 저녁: 취침 전 2~3시간  → "evening"
        - 취침 준비 시간: 안정 루틴 실행 시점 → "sleep_prep"

        hours_since_wake, hours_to_sleep가 없으면 None 리턴
        """
        # 취침 관련 정보 우선
        if hours_to_sleep is not None:
            # 취침 0~2.5시간 전 → 취침 준비
            if 0 <= hours_to_sleep <= 2.5:
                return "sleep_prep"
            # 취침 2.5~3.5시간 전 → 개인화 저녁
            if 2.5 < hours_to_sleep <= 3.5:
                return "evening"

        if hours_since_wake is None:
            return None

        # 기상 후 기준
        if 0 <= hours_since_wake <= 3:
            return "morning"
        if 3 < hours_since_wake <= 10:
            return "day"

        # 그 외는 기본적으로 저녁으로 간주
        return "evening"

    # ------------------------------------------------------------------
    # 시간대 루틴 필터링 (이전 로직 유지)
    # ------------------------------------------------------------------
    def _apply_time_slot_constraints(
        self,
        recommendations: List[RoutineRecommendationItem],
        slot: Optional[str],
    ) -> List[RoutineRecommendationItem]:
        """
        - TIME_* 카테고리 루틴은 개인화 시간 슬롯과 맞는 것만 남긴다.
        - 그 중에서도 최대 1개만 유지한다.
        - 감정/신체 루틴은 그대로 둔다.
        """
        if slot is None:
            # 개인화 정보가 없으면 필터링하지 않음
            return recommendations

        allowed_time_categories = PERSONAL_SLOT_TO_TIME_CATEGORIES.get(slot, [])
        allowed_time_tags = PERSONAL_SLOT_TO_TIME_TAGS.get(slot, [])

        time_routines: List[RoutineRecommendationItem] = []
        other_routines: List[RoutineRecommendationItem] = []

        for item in recommendations:
            if self._is_time_routine(item):
                if self._match_slot(item, allowed_time_categories, allowed_time_tags):
                    time_routines.append(item)
                # 슬롯과 안 맞는 TIME_* 루틴은 버림
            else:
                other_routines.append(item)

        # 시간대 루틴은 최대 1개만 사용
        chosen_time: List[RoutineRecommendationItem] = []
        if time_routines:
            # 이미 LLM에서 중요도 순으로 준 거라고 가정하고 첫 번째만 사용
            chosen_time.append(time_routines[0])

        final: List[RoutineRecommendationItem] = []
        final.extend(other_routines)
        final.extend(chosen_time)

        return final

    def _is_time_routine(self, item: RoutineRecommendationItem) -> bool:
        """
        RoutineRecommendationItem이 시간대 루틴(TIME_*)인지 판단
        """
        category = getattr(item, "category", "")
        return isinstance(category, str) and category.startswith("TIME_")

    def _match_slot(
        self,
        item: RoutineRecommendationItem,
        allowed_categories: List[str],
        allowed_time_tags: List[str],
    ) -> bool:
        """
        개인화 시간 슬롯과 루틴이 매칭되는지 확인
        - category가 TIME_MORNING / TIME_DAY / TIME_EVENING 중 하나인지
        - 또는 time_tags에 morning/day/evening/pre_sleep가 포함되어 있는지
        """
        category = getattr(item, "category", None)
        if category in allowed_categories:
            return True

        # RoutineRecommendationItem 안에 time_tags 필드가 있다고 가정
        time_tags = getattr(item, "time_tags", None) or []
        return any(tag in allowed_time_tags for tag in time_tags)

    # ------------------------------------------------------------------
    # 카테고리 다양성 확보 (비슷한 것 안 겹치게 섞기)
    # ------------------------------------------------------------------
    def _pick_diverse_routines(
        self,
        recommendations: List[RoutineRecommendationItem],
        max_recommend: int,
    ) -> List[RoutineRecommendationItem]:
        """
        - EMOTION_*, BODY_*, TIME_* 카테고리를 섞어서
          최대한 다양한 조합으로 max_recommend개 선택
        - 기본 전략:
          1) emotion, body, time, other 그룹으로 분리
          2) 우선순위: emotion → body → time → other
          3) 각 그룹에서 랜덤으로 1개씩 뽑고, 남는 슬롯은 전체에서 랜덤 채우기
        """
        groups: Dict[str, List[RoutineRecommendationItem]] = {
            "emotion": [],
            "body": [],
            "time": [],
            "other": [],
        }

        for item in recommendations:
            g = self._category_group(item)
            groups[g].append(item)

        # 각 그룹 내부 셔플
        for g in groups:
            random.shuffle(groups[g])

        final: List[RoutineRecommendationItem] = []

        # 1) 그룹별로 1개씩 우선적으로 채우기 (emotion → body → time → other)
        priority_order = ["emotion", "body", "time", "other"]
        for g in priority_order:
            if len(final) >= max_recommend:
                break
            if groups[g]:
                final.append(groups[g].pop(0))

        if len(final) >= max_recommend:
            return final[:max_recommend]

        # 2) 아직 슬롯이 남았다면, 남은 모든 아이템을 한데 모아서 랜덤 채우기
        remaining: List[RoutineRecommendationItem] = []
        for g in groups:
            remaining.extend(groups[g])

        random.shuffle(remaining)

        for item in remaining:
            if len(final) >= max_recommend:
                break
            final.append(item)

        return final[:max_recommend]

    def _category_group(self, item: RoutineRecommendationItem) -> str:
        """
        카테고리를 크게 4그룹으로 나눈다:
        - EMOTION_* → "emotion"
        - BODY_*    → "body"
        - TIME_*    → "time"
        - 그 외     → "other"
        """
        category = getattr(item, "category", "") or ""

        if category.startswith("EMOTION_"):
            return "emotion"
        if category.startswith("BODY_"):
            return "body"
        if category.startswith("TIME_"):
            return "time"
        return "other"
