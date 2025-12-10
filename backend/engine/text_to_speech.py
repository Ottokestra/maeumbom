"""Compatibility wrapper for TTS engine registry.

This module exposes the text-to-speech engine registry while keeping
implementation files in the existing `text-to-speech` directory.
"""
from pathlib import Path
import sys


_tts_dir = Path(__file__).parent / "text-to-speech"
if str(_tts_dir) not in sys.path:
    sys.path.insert(0, str(_tts_dir))

from init import get_tts_engine  # type: ignore  # noqa: E402,F401
from base import BaseTTSEngine  # type: ignore  # noqa: E402,F401
from melo_engine import MeloTTSEngine  # type: ignore  # noqa: E402,F401
from cute_engine import CuteTTSEngine  # type: ignore  # noqa: E402,F401

__all__ = [
    "BaseTTSEngine",
    "MeloTTSEngine",
    "CuteTTSEngine",
    "get_tts_engine",
]
