"""
LangChain Agent용 Speech-to-Text 어댑터

기존 speech-to-text 엔진을 LangChain Agent에서 사용할 수 있도록 래핑합니다.
"""
import sys
from pathlib import Path
from typing import Optional

# 프로젝트 경로 설정
engine_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(engine_root))


def run_speech_to_text(audio_bytes: bytes) -> str:
    """
    음성 데이터를 텍스트로 변환
    
    기존 STT 엔진을 시도하고, 실패 시 더미 구현으로 fallback합니다.
    
    Args:
        audio_bytes: 오디오 데이터 (바이트열)
        
    Returns:
        변환된 텍스트
    """
    try:
        # 기존 STT 엔진 import 시도
        from speech_to_text.faster_whisper.stt_engine import MaumBomSTT
        import numpy as np
        import io
        import wave
        
        # audio_bytes를 numpy array로 변환
        # WAV 형식이라고 가정
        try:
            with io.BytesIO(audio_bytes) as audio_io:
                with wave.open(audio_io, 'rb') as wav_file:
                    # WAV 파일 정보 읽기
                    sample_rate = wav_file.getframerate()
                    n_frames = wav_file.getnframes()
                    audio_data = wav_file.readframes(n_frames)
                    
                    # numpy array로 변환
                    audio_array = np.frombuffer(audio_data, dtype=np.int16)
                    # float32로 정규화 (-1.0 ~ 1.0)
                    audio_array = audio_array.astype(np.float32) / 32768.0
                    
            # STT 엔진 초기화 (config.yaml 경로 지정)
            config_path = engine_root / "speech-to-text" / "faster_whisper" / "config.yaml"
            if not config_path.exists():
                raise FileNotFoundError(f"Config file not found: {config_path}")
                
            stt_engine = MaumBomSTT(config_path=str(config_path))
            
            # 음성 인식 수행
            # MaumBomSTT는 실시간 스트리밍용이므로, 여기서는 간단히 처리
            # 실제로는 audio_array를 처리할 수 있는 메서드가 필요
            # TODO: MaumBomSTT의 적절한 메서드 호출로 교체
            
            # 임시: 더미 구현으로 fallback
            raise NotImplementedError("MaumBomSTT의 batch 처리 메서드가 필요합니다")
            
        except Exception as e:
            print(f"⚠️  3-3 STT 엔진 실행 중 오류: {e}")
            raise
            
    except (ImportError, FileNotFoundError, NotImplementedError) as e:
        # STT 엔진을 사용할 수 없는 경우 더미 구현
        print(f"⚠️  3-3 STT 엔진을 사용할 수 없습니다: {e}")
        print("💡 더미 STT 결과를 반환합니다.")
        
        # TODO: 실제 STT 엔진 연동
        # 현재는 v1.0 프로토타입이므로 더미 텍스트 반환
        return "오늘 하루 정말 힘들었어요. 아무것도 하기 싫고 기운이 없네요."


class SpeechToTextClient:
    """
    Speech-to-Text 클라이언트 (Protocol 스타일 인터페이스)
    
    나중에 다른 STT 엔진으로 교체 가능하도록 인터페이스를 정의합니다.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Args:
            config_path: 3-3 STT 엔진 설정 파일 경로 (선택)
        """
        self.config_path = config_path
        
    def run(self, audio_bytes: bytes) -> str:
        """
        음성을 텍스트로 변환
        
        Args:
            audio_bytes: 오디오 데이터
            
        Returns:
            변환된 텍스트
        """
        return run_speech_to_text(audio_bytes)


# 편의를 위한 전역 함수
def create_stt_client(config_path: Optional[str] = None) -> SpeechToTextClient:
    """
    STT 클라이언트 생성
    
    Args:
        config_path: 설정 파일 경로 (선택)
        
    Returns:
        SpeechToTextClient 인스턴스
    """
    return SpeechToTextClient(config_path=config_path)


if __name__ == "__main__":
    # 테스트
    print("=== 3-3 STT 어댑터 테스트 ===")
    
    # 더미 오디오 바이트
    dummy_audio = b"dummy audio data"
    
    # 함수 방식 테스트
    result = run_speech_to_text(dummy_audio)
    print(f"결과 (함수): {result}")
    
    # 클래스 방식 테스트
    client = create_stt_client()
    result = client.run(dummy_audio)
    print(f"결과 (클래스): {result}")

