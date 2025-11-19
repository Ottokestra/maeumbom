"""
LangChain Agent용 어댑터 모듈

기존 엔진들을 LangChain Agent에서 사용할 수 있도록 래핑합니다.
"""
from .stt_adapter import run_speech_to_text, SpeechToTextClient, create_stt_client
from .emotion_adapter import run_emotion_analysis, EmotionAnalysisClient, create_emotion_client, EmotionResult

__all__ = [
    "run_speech_to_text",
    "SpeechToTextClient",
    "create_stt_client",
    "run_emotion_analysis",
    "EmotionAnalysisClient",
    "create_emotion_client",
    "EmotionResult",
]

