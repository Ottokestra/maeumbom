"""추천/생성 서비스 스텁 구현."""

from __future__ import annotations

from typing import List

from .schemas import QuoteItem


async def generate_quotes(emotion_label: str, language: str) -> List[QuoteItem]:
    """감정 라벨과 언어에 맞춰 명언을 생성/추천한다."""

    templates = {
        "기쁨": {
            "ko": ["행복은 전염성이 있어요. 당신의 미소가 세상을 밝힙니다."],
            "en": ["Joy shared is joy doubled."],
        },
        "슬픔": {
            "ko": ["눈물은 마음을 씻어주는 비와 같다."],
            "en": ["Tears are the silent language of grief."],
        },
        "두려움": {
            "ko": ["용기는 두려움을 딛고 한 걸음 내딛는 것."],
            "en": [
                "Courage is resistance to fear, mastery of fear—not absence of fear."
            ],
        },
    }

    messages = templates.get(emotion_label, templates.get("기쁨"))
    selected = messages.get(language, messages.get("ko", []))

    return [QuoteItem(text=quote, source="AI_GENERATED") for quote in selected]


async def recommend_music(emotion_label: str, duration: int) -> str:
    """감정 라벨과 길이에 맞춰 음악 URL을 반환한다."""

    return f"https://dummy.maeumbom/music/{emotion_label}-{duration}.wav"


async def generate_image(prompt: str, emotion_label: str | None) -> str:
    """텍스트 프롬프트 기반으로 이미지를 생성한다."""

    suffix = emotion_label or "default"
    return f"https://dummy.maeumbom/images/{suffix}-1.png"
