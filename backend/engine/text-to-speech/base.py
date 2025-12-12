from pathlib import Path
from abc import ABC, abstractmethod


class BaseTTSEngine(ABC):
    name: str

    @abstractmethod
    def synthesize_to_wav(
        self,
        text: str,
        voice_id: str | None = None,
        emotion: str | None = None,
    ) -> Path:
        """text를 받아 wav 파일 경로를 반환한다."""
        ...
