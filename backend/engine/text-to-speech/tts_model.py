# tts_model.py
"""마음봄 · TTS 모듈 (한국어 전용, 감정 프리셋 지원)

- MeloTTS 한국어(KR) 모델만 사용
- tone 인자를 통해 감정/톤 프리셋을 선택할 수 있다.
- engine 인자는 인터페이스 호환성을 위해 받지만,
  현재는 'melo'만 사용한다.
"""

from pathlib import Path
from uuid import uuid4
from typing import Optional, Dict

import torch
from melo.api import TTS

# ----------------------------------------------------------------------
# 기본 설정
# ----------------------------------------------------------------------

LANGUAGE = "KR"  # 한국어 전용

# GPU가 있으면 cuda:0, 없으면 cpu 사용
_device = "cuda:0" if torch.cuda.is_available() else "cpu"

# 전역 캐시 (모델은 한 번만 로드)
_tts: Optional[TTS] = None
_speaker_id: Optional[int] = None

# ----------------------------------------------------------------------
# 감정/톤 프리셋 설정
# ----------------------------------------------------------------------
# MeloTTS tts_to_file 기본값을 기준으로 한 베이스 값
BASE_PRESET: Dict[str, float] = {
    "sdp_ratio": 0.2,
    "noise_scale": 0.6,
    "noise_scale_w": 0.8,
    "speed": 1.0,
}

# 감정(또는 톤)별로 약간씩 다른 값 부여
# 실제 값은 프로젝트 진행하면서 청감 테스트를 통해 조정 가능
EMOTION_PRESETS: Dict[str, Dict[str, float]] = {
    # "기본" 갱년기 어머니 상담 톤
    "senior_calm": {
        "sdp_ratio": 0.25,
        "noise_scale": 0.55,
        "noise_scale_w": 0.75,
        "speed": 0.95,
    },
    # 우울/힘든 감정 → 조금 느리고 부드럽게
    "sad": {
        "sdp_ratio": 0.3,
        "noise_scale": 0.5,
        "noise_scale_w": 0.7,
        "speed": 0.9,
    },
    # 화남/분노 → 속도는 비슷, 에너지는 약간 올라간 느낌
    "angry": {
        "sdp_ratio": 0.15,
        "noise_scale": 0.65,
        "noise_scale_w": 0.9,
        "speed": 1.02,
    },
    # 기쁨/안정 → 약간 빠르고 밝은 느낌
    "happy": {
        "sdp_ratio": 0.18,
        "noise_scale": 0.62,
        "noise_scale_w": 0.9,
        "speed": 1.05,
    },
    # 별도 감정 태깅이 없을 때
    "neutral": {
        "sdp_ratio": 0.2,
        "noise_scale": 0.6,
        "noise_scale_w": 0.8,
        "speed": 1.0,
    },
}


def _resolve_preset(tone: Optional[str], speed: Optional[float]) -> Dict[str, float]:
    """tone/감정 값과 speed를 받아 최종 TTS 파라미터를 결정한다.

    Parameters
    ----------
    tone : str | None
        감정/톤 라벨. 예: "sad", "happy", "angry", "neutral", "senior_calm" ...
        (3-4 감정분석 결과와 매핑해서 사용)
    speed : float | None
        외부에서 직접 지정한 말하기 속도. None 이면 프리셋 값 사용.

    Returns
    -------
    Dict[str, float]
        TTS.tts_to_file 에 그대로 넘길 수 있는 파라미터 딕셔너리.
    """
    key = (tone or "").lower()

    # 감정분석 모듈에서 넘어오는 값과 맞춰서 사용
    preset = EMOTION_PRESETS.get(key)
    if preset is None:
        # 지정되지 않은 값이면 neutral 로 처리
        preset = EMOTION_PRESETS["neutral"]

    # BASE_PRESET 위에 감정 프리셋을 덮어쓰기
    cfg: Dict[str, float] = {**BASE_PRESET, **preset}

    # speed 를 직접 지정한 경우 최종 속도로 override
    if speed is not None:
        try:
            cfg["speed"] = float(speed)
        except (TypeError, ValueError):
            # 숫자로 변환할 수 없으면 무시하고 프리셋 속도를 사용
            pass

    return cfg


# ----------------------------------------------------------------------
# 내부: MeloTTS 초기화
# ----------------------------------------------------------------------
def _init_tts() -> None:
    """MeloTTS 한국어 모델을 한 번만 로드해서 전역 캐시에 올린다."""
    global _tts, _speaker_id

    if _tts is not None:
        # 이미 로드되어 있으면 바로 리턴
        return

    print(f"[MeloTTS] loading language={LANGUAGE}, device={_device}")
    _tts = TTS(language=LANGUAGE, device=_device)

    # 예: {'KR': 0} 같은 dict
    speakers = _tts.hps.data.spk2id
    print("[MeloTTS] speakers:", speakers)

    # LANGUAGE 키가 있으면 그걸 쓰고, 없으면 첫 번째 값 사용
    if LANGUAGE in speakers:
        _speaker_id = speakers[LANGUAGE]
    else:
        # 혹시라도 키 이름이 다를 때 대비
        _speaker_id = next(iter(speakers.values()))

    print(f"[MeloTTS] selected speaker id = {_speaker_id}")


# ----------------------------------------------------------------------
# 외부 API: 텍스트 → WAV
# ----------------------------------------------------------------------
def synthesize_to_wav(
    text: str,
    speed: Optional[float] = None,
    tone: Optional[str] = None,
    engine: Optional[str] = None,
) -> Path:
    """한국어 텍스트를 wav 파일로 저장하고 파일 경로를 반환한다.

    Parameters
    ----------
    text : str
        입력 텍스트 (한국어)
    speed : float | None
        말하기 속도. None 이면 프리셋 값 사용.
    tone : str | None
        감정/톤 라벨. 예: "sad", "happy", "angry", "neutral", "senior_calm" ...
        3-4 감정분석 모듈의 결과와 매핑해서 사용하면 된다.
    engine : str | None
        인터페이스 호환성용 인자. 현재는 'melo'만 사용하며, 다른 값은 무시한다.

    Returns
    -------
    Path
        생성된 wav 파일 경로
    """
    if not text or not text.strip():
        raise ValueError("text is empty")

    # MeloTTS 모델/화자 초기화
    _init_tts()

    # 감정/톤 + 속도에 따라 최종 파라미터 구성
    cfg = _resolve_preset(tone=tone, speed=speed)

    # 출력 폴더 (backend 실행 기준으로 backend/outputs/)
    out_dir = Path("outputs")
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{uuid4().hex}.wav"

    # 한국어 기본 화자로 합성 (감정 프리셋 적용)
    _tts.tts_to_file(
        text.strip(),
        _speaker_id,
        str(out_path),
        sdp_ratio=cfg["sdp_ratio"],
        noise_scale=cfg["noise_scale"],
        noise_scale_w=cfg["noise_scale_w"],
        speed=cfg["speed"],
    )

    return out_path
