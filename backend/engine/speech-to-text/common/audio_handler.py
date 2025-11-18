"""
마음봄 - 오디오 입력 핸들러
PyAudio를 사용하여 마이크 입력을 캡처하고 스트리밍합니다.
"""

import pyaudio
import numpy as np
from typing import Callable, Optional
import threading
import queue


class AudioHandler:
    """마이크 오디오 입력을 처리하는 클래스"""
    
    def __init__(
        self,
        sample_rate: int = 16000,
        channels: int = 1,
        chunk_size: int = 1024,
        format: int = pyaudio.paInt16
    ):
        """
        Args:
            sample_rate: 샘플링 레이트 (Hz)
            channels: 채널 수 (1: Mono, 2: Stereo)
            chunk_size: 버퍼 크기
            format: 오디오 포맷
        """
        self.sample_rate = sample_rate
        self.channels = channels
        self.chunk_size = chunk_size
        self.format = format
        
        self.pyaudio = pyaudio.PyAudio()
        self.stream: Optional[pyaudio.Stream] = None
        self.is_recording = False
        self.audio_queue = queue.Queue()
        
    def start_stream(self, callback: Optional[Callable] = None):
        """
        오디오 스트림 시작
        
        Args:
            callback: 오디오 데이터를 받을 콜백 함수
        """
        if self.stream is not None:
            self.stop_stream()
            
        def audio_callback(in_data, frame_count, time_info, status):
            if callback:
                callback(in_data)
            else:
                self.audio_queue.put(in_data)
            return (in_data, pyaudio.paContinue)
        
        self.stream = self.pyaudio.open(
            format=self.format,
            channels=self.channels,
            rate=self.sample_rate,
            input=True,
            frames_per_buffer=self.chunk_size,
            stream_callback=audio_callback
        )
        
        self.is_recording = True
        self.stream.start_stream()
        print(f"[오디오] 마이크 스트림 시작 (샘플레이트: {self.sample_rate}Hz)")
        
    def stop_stream(self):
        """오디오 스트림 종료"""
        if self.stream is not None:
            self.is_recording = False
            self.stream.stop_stream()
            self.stream.close()
            self.stream = None
            print("[오디오] 마이크 스트림 종료")
            
    def read_chunk(self) -> Optional[bytes]:
        """
        큐에서 오디오 청크 읽기
        
        Returns:
            오디오 데이터 (bytes) 또는 None
        """
        try:
            return self.audio_queue.get(timeout=1.0)
        except queue.Empty:
            return None
            
    def bytes_to_numpy(self, audio_bytes: bytes) -> np.ndarray:
        """
        바이트 데이터를 numpy 배열로 변환
        
        Args:
            audio_bytes: 오디오 바이트 데이터
            
        Returns:
            numpy 배열 (float32, -1.0 ~ 1.0 범위)
        """
        audio_int16 = np.frombuffer(audio_bytes, dtype=np.int16)
        audio_float32 = audio_int16.astype(np.float32) / 32768.0
        return audio_float32
        
    def numpy_to_bytes(self, audio_array: np.ndarray) -> bytes:
        """
        numpy 배열을 바이트 데이터로 변환
        
        Args:
            audio_array: numpy 배열 (float32)
            
        Returns:
            오디오 바이트 데이터
        """
        audio_int16 = (audio_array * 32768.0).astype(np.int16)
        return audio_int16.tobytes()
        
    def close(self):
        """리소스 정리"""
        self.stop_stream()
        self.pyaudio.terminate()
        print("[오디오] 리소스 정리 완료")
        
    def __enter__(self):
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()


class AudioBuffer:
    """오디오 데이터를 버퍼링하는 클래스"""
    
    def __init__(self, max_duration: float = 30.0, sample_rate: int = 16000):
        """
        Args:
            max_duration: 최대 버퍼 시간 (초)
            sample_rate: 샘플링 레이트
        """
        self.max_duration = max_duration
        self.sample_rate = sample_rate
        self.max_samples = int(max_duration * sample_rate)
        self.buffer = []
        self.lock = threading.Lock()
        
    def append(self, audio_data: np.ndarray):
        """
        오디오 데이터 추가
        
        Args:
            audio_data: numpy 배열
        """
        with self.lock:
            self.buffer.append(audio_data)
            # 최대 길이 초과 시 앞부분 제거
            total_samples = sum(len(chunk) for chunk in self.buffer)
            while total_samples > self.max_samples and len(self.buffer) > 1:
                removed = self.buffer.pop(0)
                total_samples -= len(removed)
                
    def get_all(self) -> np.ndarray:
        """
        버퍼의 모든 데이터를 반환
        
        Returns:
            연결된 numpy 배열
        """
        with self.lock:
            if not self.buffer:
                return np.array([], dtype=np.float32)
            return np.concatenate(self.buffer)
            
    def clear(self):
        """버퍼 초기화"""
        with self.lock:
            self.buffer = []
            
    def get_duration(self) -> float:
        """
        현재 버퍼에 저장된 오디오 길이 (초)
        
        Returns:
            오디오 길이 (초)
        """
        with self.lock:
            total_samples = sum(len(chunk) for chunk in self.buffer)
            return total_samples / self.sample_rate

