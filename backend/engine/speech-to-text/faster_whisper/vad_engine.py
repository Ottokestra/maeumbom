"""
마음봄 - Silero VAD 엔진
음성 활동 감지 (Voice Activity Detection)
"""

import torch
import numpy as np
from typing import Optional, Tuple
import time


class SileroVAD:
    """Silero VAD 모델을 사용한 음성 활동 감지"""
    
    def __init__(
        self,
        threshold: float = 0.5,
        min_speech_duration_ms: int = 250,
        max_speech_duration_s: float = 30.0,
        min_silence_duration_ms: int = 2000,
        short_silence_duration_ms: int = 500,  # 짧은 침묵 감지 (문장 구분용)
        speech_pad_ms: int = 300,
        sample_rate: int = 16000
    ):
        """
        Args:
            threshold: 음성 감지 임계값 (0.0 ~ 1.0)
            min_speech_duration_ms: 최소 발화 길이 (ms)
            max_speech_duration_s: 최대 발화 길이 (초)
            min_silence_duration_ms: 무음 감지 시간 (ms) - 발화 종료
            short_silence_duration_ms: 짧은 무음 감지 시간 (ms) - 문장 구분/확정
            speech_pad_ms: 발화 앞뒤 패딩 (ms)
            sample_rate: 샘플링 레이트
        """
        self.threshold = threshold
        self.min_speech_duration_ms = min_speech_duration_ms
        self.max_speech_duration_s = max_speech_duration_s
        self.min_silence_duration_ms = min_silence_duration_ms
        self.short_silence_duration_ms = short_silence_duration_ms
        self.speech_pad_ms = speech_pad_ms
        self.sample_rate = sample_rate
        
        # 샘플 단위로 변환
        self.min_speech_samples = int(sample_rate * min_speech_duration_ms / 1000)
        self.max_speech_samples = int(sample_rate * max_speech_duration_s)
        self.min_silence_samples = int(sample_rate * min_silence_duration_ms / 1000)
        self.short_silence_samples = int(sample_rate * short_silence_duration_ms / 1000)
        self.speech_pad_samples = int(sample_rate * speech_pad_ms / 1000)
        
        # Silero VAD 모델 로드
        print("📥 Silero VAD 모델 로딩 중...")
        try:
            self.model, utils = torch.hub.load(
                repo_or_dir='snakers4/silero-vad',
                model='silero_vad',
                force_reload=False,
                onnx=False
            )
            self.get_speech_timestamps = utils[0]
            print("✅ Silero VAD 모델 로드 완료")
        except Exception as e:
            print(f"❌ Silero VAD 모델 로드 실패: {e}")
            raise
            
        # 상태
        self.is_speaking = False
        self.speech_start_sample = 0
        self.silence_start_sample = 0
        self.current_sample = 0
        self.speech_buffer = []
        self.last_was_speech = False  # 이전 청크가 음성이었는지 추적
        self.short_pause_triggered = False  # 짧은 침묵 이미 감지됨
        
    def reset(self):
        """상태 초기화"""
        self.is_speaking = False
        self.speech_start_sample = 0
        self.silence_start_sample = 0
        self.current_sample = 0
        self.speech_buffer = []
        self.last_was_speech = False
        self.short_pause_triggered = False
        
    def process_chunk(
        self,
        audio_chunk: np.ndarray
    ) -> Tuple[bool, Optional[np.ndarray], bool]:
        """
        오디오 청크 처리
        
        Args:
            audio_chunk: 오디오 데이터 (numpy array, float32)
            
        Returns:
            (발화 완료 여부, 발화 오디오 데이터, 짧은 침묵 감지 여부)
        """
        # Tensor로 변환
        if len(audio_chunk) == 0:
            return False, None, False
            
        audio_tensor = torch.from_numpy(audio_chunk).float()
        
        # VAD 확률 계산
        with torch.no_grad():
            speech_prob = self.model(audio_tensor, self.sample_rate).item()
        
        # 🔍 VAD 확률 로깅 (음성이 있을 때만)
        if speech_prob > 0.3:  # 임계값보다 낮아도 확인
            print(f"[VAD PROB] speech_prob={speech_prob:.3f}, threshold={self.threshold:.3f}, is_speech={speech_prob >= self.threshold}", flush=True)
        
        is_short_pause = False  # 짧은 침묵 감지 플래그
        current_is_speech = speech_prob >= self.threshold
        
        # 음성 감지
        if current_is_speech:
            if not self.is_speaking:
                # 발화 시작
                print(f"[VAD] 🎤 발화 시작 감지! (prob={speech_prob:.3f})", flush=True)
                self.is_speaking = True
                self.speech_start_sample = self.current_sample
                self.speech_buffer = []
                self.silence_start_sample = self.current_sample
                self.short_pause_triggered = False
                
            # 버퍼에 추가
            self.speech_buffer.append(audio_chunk)
            
            # ⭐ 이전에 무음이었다가 지금 음성이면 침묵 종료
            if not self.last_was_speech:
                # 침묵에서 음성으로 전환 - 침묵 시작점 리셋
                self.silence_start_sample = self.current_sample
                # 짧은 침묵 플래그도 리셋 (다음 침묵을 위해)
                self.short_pause_triggered = False
            
        else:
            # 무음 감지
            if self.is_speaking:
                # ⭐ 음성에서 무음으로 전환되는 순간 - 침묵 시작!
                if self.last_was_speech:
                    self.silence_start_sample = self.current_sample
                
                # 버퍼에 추가 (무음도 포함)
                self.speech_buffer.append(audio_chunk)
                
                # 무음 지속 시간 확인
                silence_duration = self.current_sample - self.silence_start_sample
                
                # ⭐ 짧은 침묵 감지 (문장 구분용) - 한 번만!
                if not self.short_pause_triggered and silence_duration >= self.short_silence_samples:
                    is_short_pause = True
                    self.short_pause_triggered = True  # 플래그 설정
                    print(f"[VAD 디버그] 짧은 침묵 감지됨! ({silence_duration / self.sample_rate * 1000:.0f}ms)", flush=True)
                
                if silence_duration >= self.min_silence_samples:
                    # 발화 종료
                    speech_duration = self.current_sample - self.speech_start_sample
                    silence_ms = silence_duration / self.sample_rate * 1000
                    print(f"[VAD 디버그] 긴 침묵 감지 ({silence_ms:.0f}ms) -> 발화 종료!", flush=True)
                    
                    if speech_duration >= self.min_speech_samples:
                        # 유효한 발화
                        speech_audio = np.concatenate(self.speech_buffer)
                        self.reset()
                        return True, speech_audio, False
                    else:
                        # 너무 짧은 발화 - 무시
                        print(f"[VAD 디버그] 발화가 너무 짧아 무시됨", flush=True)
                        self.reset()
                        
                elif (self.current_sample - self.speech_start_sample) >= self.max_speech_samples:
                    # 최대 발화 길이 초과
                    speech_audio = np.concatenate(self.speech_buffer)
                    self.reset()
                    return True, speech_audio, False
        
        # 이전 상태 업데이트
        self.last_was_speech = current_is_speech
        self.current_sample += len(audio_chunk)
        return False, None, is_short_pause
        
    def get_speech_probability(self, audio_chunk: np.ndarray) -> float:
        """
        오디오 청크의 음성 확률 계산
        
        Args:
            audio_chunk: 오디오 데이터
            
        Returns:
            음성 확률 (0.0 ~ 1.0)
        """
        if len(audio_chunk) == 0:
            return 0.0
            
        audio_tensor = torch.from_numpy(audio_chunk).float()
        
        with torch.no_grad():
            speech_prob = self.model(audio_tensor, self.sample_rate).item()
            
        return speech_prob
    
    def get_current_silence_duration_ms(self) -> float:
        """
        현재 침묵 지속 시간 반환 (ms)
        
        Returns:
            침묵 지속 시간 (밀리초)
        """
        if not self.is_speaking:
            return 0.0
        
        silence_duration_samples = self.current_sample - self.silence_start_sample
        return (silence_duration_samples / self.sample_rate) * 1000
    
    def has_short_pause(self) -> bool:
        """
        짧은 침묵(문장 구분용)이 감지되었는지 확인
        
        Returns:
            짧은 침묵 감지 여부
        """
        if not self.is_speaking:
            return False
        
        silence_duration = self.current_sample - self.silence_start_sample
        return silence_duration >= self.short_silence_samples
    
    def get_buffer_length(self) -> int:
        """
        현재 버퍼에 저장된 오디오 길이 반환
        
        Returns:
            버퍼 청크 개수
        """
        return len(self.speech_buffer)