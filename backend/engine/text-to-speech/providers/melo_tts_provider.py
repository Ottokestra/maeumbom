"""MeloTTS provider implementation."""
from __future__ import annotations

import os
import tempfile
from pathlib import Path
from typing import Dict, Optional
from uuid import uuid4

import torch
from melo.api import TTS

from tts_base import TextToSpeechProvider


class MeloTtsProvider(TextToSpeechProvider):
    """Text-to-speech provider backed by MeloTTS."""

    BASE_PRESET: Dict[str, float] = {
        "sdp_ratio": 0.2,
        "noise_scale": 0.6,
        "noise_scale_w": 0.8,
        "speed": 1.0,
    }

    EMOTION_PRESETS: Dict[str, Dict[str, float]] = {
        "senior_calm": {
            "sdp_ratio": 0.25,
            "noise_scale": 0.55,
            "noise_scale_w": 0.75,
            "speed": 0.95,
        },
        "sad": {
            "sdp_ratio": 0.3,
            "noise_scale": 0.5,
            "noise_scale_w": 0.7,
            "speed": 0.9,
        },
        "angry": {
            "sdp_ratio": 0.15,
            "noise_scale": 0.65,
            "noise_scale_w": 0.9,
            "speed": 1.02,
        },
        "happy": {
            "sdp_ratio": 0.18,
            "noise_scale": 0.62,
            "noise_scale_w": 0.9,
            "speed": 1.05,
        },
        "neutral": {
            "sdp_ratio": 0.2,
            "noise_scale": 0.6,
            "noise_scale_w": 0.8,
            "speed": 1.0,
        },
    }

    def __init__(self, language: str | None = None, device: str | None = None):
        self.language = (language or os.getenv("TTS_LANGUAGE", "KR")).upper()
        self.device = device or ("cuda:0" if torch.cuda.is_available() else "cpu")
        self._tts: Optional[TTS] = None
        self._speaker_id: Optional[int] = None

    def synthesize(
        self,
        text: str,
        speaker: str | None = None,
        emotion: str | None = None,
        speed: float | None = None,
    ) -> bytes:
        if not text or not str(text).strip():
            raise ValueError("text is empty")

        tts = self._get_tts()
        preset = self._resolve_preset(emotion=emotion, speed=speed)
        speaker_id = self._resolve_speaker(tts, speaker)

        with tempfile.TemporaryDirectory() as temp_dir:
            out_path = Path(temp_dir) / f"{uuid4().hex}.wav"
            tts.tts_to_file(
                text.strip(),
                speaker_id,
                str(out_path),
                sdp_ratio=preset["sdp_ratio"],
                noise_scale=preset["noise_scale"],
                noise_scale_w=preset["noise_scale_w"],
                speed=preset["speed"],
            )
            return out_path.read_bytes()

    def _get_tts(self) -> TTS:
        if self._tts is not None:
            return self._tts

        self._tts = TTS(language=self.language, device=self.device)
        speakers = getattr(self._tts.hps.data, "spk2id", {})
        self._speaker_id = speakers.get(self.language)
        if self._speaker_id is None and speakers:
            self._speaker_id = next(iter(speakers.values()))
        return self._tts

    def _resolve_speaker(self, tts: TTS, speaker: str | None) -> int:
        if speaker is not None:
            try:
                return int(speaker)
            except (TypeError, ValueError):
                pass
        if self._speaker_id is not None:
            return self._speaker_id

        speakers = getattr(tts.hps.data, "spk2id", {})
        if speakers:
            return next(iter(speakers.values()))
        raise ValueError("No available speaker id in MeloTTS model")

    def _resolve_preset(self, emotion: str | None, speed: float | None) -> Dict[str, float]:
        key = (emotion or "neutral").lower()
        preset = self.EMOTION_PRESETS.get(key, self.EMOTION_PRESETS["neutral"])
        merged = {**self.BASE_PRESET, **preset}
        if speed is not None:
            try:
                merged["speed"] = float(speed)
            except (TypeError, ValueError):
                pass
        return merged

