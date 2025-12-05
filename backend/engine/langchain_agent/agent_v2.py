from typing import Any, Optional

from pydantic import BaseModel

from .agent import run_ai_bomi_from_text


class CharacterInfo(BaseModel):
    id: str
    emotion_label: str


def select_character_from_emotion(emotion_result: dict[str, Any]) -> tuple[str, str]:
    """
    emotion_result 에서 주요 감정/클러스터를 읽어서 캐릭터 ID와 감정 라벨을 결정한다.

    반환값:
        (character_id, emotion_label)
    예:
        ("sunny_flower", "JOY")
        ("sad_cloud", "SADNESS")
    """
    primary = (
        emotion_result.get("primary_emotion")
        or emotion_result.get("cluster")
        or "NEUTRAL"
    )

    mapping = {
        "JOY": "sunny_flower",  # 해바라기
        "HAPPINESS": "sunny_flower",
        "LOVE": "heart_cat",  # 하트눈 고양이
        "HOPE": "star_friend",  # 별
        "INSIGHT": "idea_bulb",  # 전구
        "ANGER": "fire_spirit",  # 불
        "SADNESS": "rain_cloud",  # 우는 구름
        "FEAR": "ghost_white",  # 유령
        "ANXIETY": "stone_gray",  # 돌
        "TIRED": "sloth_bear",  # 나무늘보
        "STRESS": "devil_red",  # 악마
        "CONFUSION": "alien_green",  # 외계인
        # 기본값
        "NEUTRAL": "cloud_white",
    }

    normalized = str(primary).upper()
    character_id = mapping.get(normalized, "cloud_white")
    return character_id, normalized


def run_ai_bomi_from_text_v2(
    user_text: str,
    session_id: str = "default",
    stt_quality: str = "success",
    speaker_id: Optional[str] = None,
) -> dict[str, Any]:
    """텍스트 입력 기반 AI 봄이 실행 (v2: 캐릭터 정보 포함)"""

    base_result = run_ai_bomi_from_text(
        user_text=user_text,
        session_id=session_id,
        stt_quality=stt_quality,
        speaker_id=speaker_id,
    )

    emotion_result = {}
    if isinstance(base_result.get("emotion_result"), dict):
        emotion_result = base_result.get("emotion_result", {})

    character_id, emotion_label = select_character_from_emotion(emotion_result)

    meta = base_result.get("meta") or {}

    return {
        **base_result,
        "character": {
            "id": character_id,
            "emotion_label": emotion_label,
        },
        "meta": {
            **meta,
            "tts_engine_default": "cute_bomi",
        },
    }
