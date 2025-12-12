from __future__ import annotations

import sys
import types
from pathlib import Path

import pytest


class DummyTTS:
    def __init__(self, language: str | None = None, device: str | None = None):
        self.hps = types.SimpleNamespace(data=types.SimpleNamespace(spk2id={language or "KR": 0}))

    def tts_to_file(self, text: str, speaker_id: int, path: str, **kwargs) -> None:
        Path(path).write_bytes(b"dummy audio")


# Stub heavy dependencies before importing provider modules
sys.modules.setdefault("torch", types.SimpleNamespace(cuda=types.SimpleNamespace(is_available=lambda: False)))
sys.modules.setdefault("melo", types.SimpleNamespace())
sys.modules["melo.api"] = types.SimpleNamespace(TTS=DummyTTS)
sys.modules["melo"].api = sys.modules["melo.api"]

# Ensure TTS modules are importable
TTS_DIR = Path(__file__).resolve().parents[2] / "engine" / "text-to-speech"
if str(TTS_DIR) not in sys.path:
    sys.path.insert(0, str(TTS_DIR))

import provider_registry  # noqa: E402
from providers import melo_tts_provider  # noqa: E402


@pytest.fixture(autouse=True)
def reset_registry(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(provider_registry, "_provider_instances", {})
    monkeypatch.setenv("TTS_PROVIDER", "melo")


@pytest.fixture
def patch_melo(monkeypatch: pytest.MonkeyPatch) -> None:
    dummy_torch = types.SimpleNamespace(cuda=types.SimpleNamespace(is_available=lambda: False))
    monkeypatch.setattr(melo_tts_provider, "torch", dummy_torch)
    monkeypatch.setattr(melo_tts_provider, "TTS", DummyTTS)


def test_melo_provider_synthesize_returns_bytes(patch_melo: None) -> None:
    provider = melo_tts_provider.MeloTtsProvider()
    audio = provider.synthesize(text="테스트", emotion="happy", speed=1.0)

    assert isinstance(audio, (bytes, bytearray))
    assert audio == b"dummy audio"


def test_get_tts_provider_returns_singleton(patch_melo: None) -> None:
    provider = provider_registry.get_tts_provider()
    provider_again = provider_registry.get_tts_provider("melo")

    assert provider is provider_again
