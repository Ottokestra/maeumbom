"""감정 분석 API에 사용되는 스키마 정의."""

from pydantic import BaseModel


class TextEmotionRequest(BaseModel):
    """텍스트 감정 분석 요청 본문."""

    text: str


class EmotionScores(BaseModel):
    """7가지 기본 감정 라벨에 대한 스코어."""

    화남: float
    역겨움: float
    두려움: float
    기쁨: float
    슬픔: float
    놀람: float
    아무생각없음: float


class ImageEmotionResponse(BaseModel):
    """이미지 감정 분석 응답."""

    emotion_label: str
    emotion_index: int
    scores: EmotionScores


class TextEmotionResponse(BaseModel):
    """텍스트 감정 분석 응답."""

    emotion_label: str
    scores: EmotionScores


class AudioEmotionResponse(BaseModel):
    """오디오(STT 포함) 감정 분석 응답."""

    transcript: str
    summary: str
    emotion_label: str
    scores: EmotionScores
