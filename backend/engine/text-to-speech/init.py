from base import BaseTTSEngine
from melo_engine import MeloTTSEngine
from cute_engine import CuteTTSEngine

_TTS_ENGINES: dict[str, BaseTTSEngine] | None = None


def get_tts_engine(engine_name: str | None) -> BaseTTSEngine:
    """
    engine_name 이 None 이거나 등록되지 않은 값이면 기본값 'cute_bomi' 를 사용한다.
    """
    global _TTS_ENGINES
    if _TTS_ENGINES is None:
        _TTS_ENGINES = {
            "melo": MeloTTSEngine(),
            "cute_bomi": CuteTTSEngine(),
        }

    if not engine_name:
        engine_name = "cute_bomi"

    return _TTS_ENGINES.get(engine_name, _TTS_ENGINES["cute_bomi"])
