from pathlib import Path

from base import BaseTTSEngine


class CuteTTSEngine(BaseTTSEngine):
    name = "cute_bomi"

    def __init__(self):
        # TODO: 실제 커스텀 TTS 엔진 초기화 (API 키, 모델 로딩 등)
        ...

    def synthesize_to_wav(
        self,
        text: str,
        voice_id: str | None = None,
        emotion: str | None = None,
    ) -> Path:
        """
        TODO:
        - 외부 TTS API 또는 로컬 엔진을 호출해서 귀여운 봄이 목소리로 wav 생성
        - 임시로는 MeloTTS를 재사용하거나, dummy wav 파일을 생성하도록 구현해도 된다.
        """
        ...
