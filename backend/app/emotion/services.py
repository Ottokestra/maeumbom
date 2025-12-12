"""감정 분석 서비스 스텁 구현."""

from __future__ import annotations

from typing import Dict, List

from fastapi import UploadFile

EMOTION_LABELS: List[str] = [
    "화남",
    "역겨움",
    "두려움",
    "기쁨",
    "슬픔",
    "놀람",
    "아무생각없음",
]


def _generate_scores(seed: str) -> Dict[str, float]:
    """입력 시드를 기반으로 감정 스코어를 생성한다."""

    base_values = []
    for index, label in enumerate(EMOTION_LABELS):
        raw_value = abs(hash(f"{seed}:{label}:{index}")) % 100 + 1
        base_values.append(float(raw_value))

    total = sum(base_values)
    return {label: round(value / total, 4) for label, value in zip(EMOTION_LABELS, base_values)}


def _top_emotion(scores: Dict[str, float]) -> str:
    """가장 높은 스코어를 가진 감정 라벨을 반환한다."""

    return max(scores.items(), key=lambda item: item[1])[0]


async def analyze_image_emotion(file: UploadFile) -> Dict[str, object]:
    """이미지 기반 감정 분석을 수행한다.

    감정 인덱스는 0부터 시작하는 기준으로 반환된다.
    """

    seed = file.filename or file.content_type or "image"
    scores = _generate_scores(seed)
    top_label = _top_emotion(scores)
    emotion_index = EMOTION_LABELS.index(top_label)

    return {
        "emotion_label": top_label,
        "emotion_index": emotion_index,
        "scores": scores,
    }


async def stt_transcribe_audio(file: UploadFile) -> str:
    """업로드된 오디오 파일을 STT로 변환한다."""

    # TODO: Whisper 기반 STT 모델 연동
    return "오늘 하루가 좀 힘들었어요..."


async def summarize_text(text: str) -> str:
    """텍스트 요약을 수행한다."""

    # TODO: 요약 모델 연동
    return "하루 동안 스트레스를 많이 느낌"


async def analyze_text_emotion(text: str) -> Dict[str, object]:
    """텍스트 기반 감정 분석을 수행한다."""

    seed = text.strip() or "text"
    scores = _generate_scores(seed)
    top_label = _top_emotion(scores)

    return {
        "emotion_label": top_label,
        "scores": scores,
    }
