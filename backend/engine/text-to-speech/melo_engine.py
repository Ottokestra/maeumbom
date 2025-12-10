from pathlib import Path

from base import BaseTTSEngine
from tts_model import synthesize_to_wav as melo_synthesize


class MeloTTSEngine(BaseTTSEngine):
    name = "melo"

    def synthesize_to_wav(
        self,
        text: str,
        voice_id: str | None = None,
        emotion: str | None = None,
    ) -> Path:
        return melo_synthesize(
            text=text,
            speed=None,
            tone=emotion,
            engine=self.name,
        )
