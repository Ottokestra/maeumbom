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

<<<<<<< HEAD
    out_dir = Path("outputs")
=======
    # 감정/톤 + 속도에 따라 최종 파라미터 구성
    cfg = _resolve_preset(tone=tone, speed=speed)

    # 출력 폴더 (backend/engine/text-to-speech/outputs/ 로 고정)
    # 현재 파일 위치: backend/engine/text-to-speech/tts_model.py
    # parent -> backend/engine/text-to-speech 디렉토리
    current_dir = Path(__file__).resolve().parent
    out_dir = current_dir / "outputs"
>>>>>>> dev
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{uuid4().hex}.wav"
    out_path.write_bytes(audio_bytes)
    return out_path

