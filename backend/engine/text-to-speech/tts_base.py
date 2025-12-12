"""Text-to-speech provider abstractions.

새 TTS 모델 교체 시 이 인터페이스만 구현하면 됨.
"""
from __future__ import annotations

import abc


class TextToSpeechProvider(abc.ABC):
    """Abstract base class for TTS providers."""

    @abc.abstractmethod
    def synthesize(
        self,
        text: str,
        speaker: str | None = None,
        emotion: str | None = None,
        speed: float | None = None,
    ) -> bytes:
        """Synthesize the given text into audio bytes.

        Args:
            text: Input text to synthesize.
            speaker: Optional speaker identifier (provider specific).
            emotion: Optional emotion/tone label.
            speed: Optional speech speed override.

        Returns:
            Raw audio bytes (e.g., WAV/MP3) produced by the provider.
        """

