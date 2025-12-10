"""Legacy TTS helper built on top of provider abstraction."""
from __future__ import annotations

from pathlib import Path
from uuid import uuid4

from provider_registry import get_tts_provider


def synthesize_to_wav(
    text: str,
    speed: float | None = None,
    tone: str | None = None,
    engine: str | None = None,
) -> Path:
    """Synthesize text to a WAV file using the configured provider.

    This helper keeps backward compatibility for callers expecting a file path
    while routing actual synthesis through the provider abstraction.
    """

    provider = get_tts_provider(engine)
    audio_bytes = provider.synthesize(text=text, speaker=None, emotion=tone, speed=speed)

    out_dir = Path("outputs")
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{uuid4().hex}.wav"
    out_path.write_bytes(audio_bytes)
    return out_path

