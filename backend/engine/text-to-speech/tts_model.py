# tts_model.py
"""마음봄 · TTS 모듈 (Eleven Labs v3 API)

- Eleven Labs v3 API를 사용한 한국어 TTS
- Voice ID: z8usQlwmsuMMxGSH3vnV
- Model: eleven_v3
"""

import os
from pathlib import Path
from uuid import uuid4
from typing import Optional
import httpx
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

# ----------------------------------------------------------------------
# 기본 설정
# ----------------------------------------------------------------------

# Eleven Labs API 설정
ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
VOICE_ID = "z8usQlwmsuMMxGSH3vnV"
MODEL_ID = "eleven_v3"
API_BASE_URL = "https://api.elevenlabs.io/v1"

if not ELEVENLABS_API_KEY:
    raise ValueError(
        "ELEVENLABS_API_KEY가 .env 파일에 설정되지 않았습니다. "
        ".env 파일에 ELEVENLABS_API_KEY=your_api_key를 추가하세요."
    )

# ----------------------------------------------------------------------
# 외부 API: 텍스트 → WAV
# ----------------------------------------------------------------------
async def synthesize_to_wav(
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
        말하기 속도 (Eleven Labs API에서는 미지원, 호환성을 위해 유지)
    tone : str | None
        감정/톤 라벨 (Eleven Labs API에서는 미지원, 호환성을 위해 유지)
    engine : str | None
        엔진 이름 (호환성을 위해 유지, 무시됨)

    Returns
    -------
    Path
        생성된 wav 파일 경로
    """
    if not text or not text.strip():
        raise ValueError("text is empty")

    # Eleven Labs API 요청
    url = f"{API_BASE_URL}/text-to-speech/{VOICE_ID}"
    
    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": ELEVENLABS_API_KEY
    }
    
    data = {
        "text": text.strip(),
        "model_id": MODEL_ID,
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.5
        }
    }

    try:
        # ✅ Async API 요청 (블로킹 제거!)
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=data, headers=headers)
            response.raise_for_status()
        
        # 출력 폴더 (backend/engine/text-to-speech/outputs/ 로 고정)
        current_dir = Path(__file__).resolve().parent
        out_dir = current_dir / "outputs"
        out_dir.mkdir(parents=True, exist_ok=True)
        
        # MP3로 받았지만 WAV로 저장하기 위해 변환 필요
        # 일단 MP3로 저장하고 나중에 필요시 변환할 수 있음
        # 또는 soundfile을 사용해 변환
        out_path = out_dir / f"{uuid4().hex}.mp3"
        
        # 오디오 데이터 저장
        with open(out_path, 'wb') as f:
            f.write(response.content)
        
        print(f"[Eleven Labs TTS] 오디오 생성 완료: {out_path}")
        return out_path
        
    except httpx.HTTPStatusError as e:
        error_msg = f"Eleven Labs API 오류 (HTTP {e.response.status_code}): {e.response.text}"
        print(f"[Eleven Labs TTS ERROR] {error_msg}")
        raise Exception(error_msg)
    except httpx.RequestError as e:
        error_msg = f"Eleven Labs API 요청 실패: {str(e)}"
        print(f"[Eleven Labs TTS ERROR] {error_msg}")
        raise Exception(error_msg)
    except Exception as e:
        error_msg = f"TTS 처리 중 오류 발생: {str(e)}"
        print(f"[Eleven Labs TTS ERROR] {error_msg}")
        raise Exception(error_msg)
