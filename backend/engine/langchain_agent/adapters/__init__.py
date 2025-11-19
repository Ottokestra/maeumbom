"""
LangChain Agent용 어댑터 모듈

기존 엔진들을 LangChain Agent에서 사용할 수 있도록 래핑합니다.
v1.1 최적화: Client 클래스 제거, 핵심 함수만 export
"""
from .stt_adapter import run_speech_to_text
from .emotion_adapter import run_emotion_analysis, EmotionResult
from .routine_adapter import run_routine_recommend

__all__ = [
    # STT
    "run_speech_to_text",
    # Emotion Analysis
    "run_emotion_analysis",
    "EmotionResult",
    # Routine Recommend
    "run_routine_recommend",
]

