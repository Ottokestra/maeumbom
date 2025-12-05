"""Provider registry for text-to-speech engines."""
from __future__ import annotations

import os
from typing import Dict, Type

from providers.melo_tts_provider import MeloTtsProvider
from tts_base import TextToSpeechProvider

PROVIDERS: Dict[str, Type[TextToSpeechProvider]] = {
    "melo": MeloTtsProvider,
}

_provider_instances: Dict[str, TextToSpeechProvider] = {}


def get_tts_provider(provider_name: str | None = None) -> TextToSpeechProvider:
    """Return a configured TTS provider instance.

    Selection priority:
    1. Explicit ``provider_name`` argument.
    2. ``TTS_PROVIDER`` environment variable.
    3. Fallback to "melo".
    """

    selected = (provider_name or os.getenv("TTS_PROVIDER", "melo")).lower()
    provider_cls = PROVIDERS.get(selected)
    if provider_cls is None:
        raise ValueError(f"Unsupported TTS provider: {selected}")

    if selected not in _provider_instances:
        _provider_instances[selected] = provider_cls()
    return _provider_instances[selected]

