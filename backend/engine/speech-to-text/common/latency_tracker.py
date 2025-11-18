"""
마음봄 - 지연 시간 측정 유틸리티
각 처리 단계의 타임스탬프를 기록하고 지연 시간을 계산합니다.
"""

import time
from typing import Dict, Optional
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class LatencyRecord:
    """지연 시간 기록"""
    speech_start: Optional[float] = None  # 발화 시작
    speech_end: Optional[float] = None    # 발화 종료
    stt_complete: Optional[float] = None  # STT 완료
    postprocess_complete: Optional[float] = None  # 후처리 완료
    
    # 부분 텍스트 수신 시간들
    partial_timestamps: list = field(default_factory=list)


class LatencyTracker:
    """지연 시간을 추적하고 측정하는 클래스"""
    
    def __init__(self):
        self.current_record = LatencyRecord()
        self.records = []
        self.session_start = time.time()
        
    def mark_speech_start(self):
        """발화 시작 시간 기록"""
        self.current_record = LatencyRecord()
        self.current_record.speech_start = time.time()
        
    def mark_speech_end(self):
        """발화 종료 시간 기록"""
        self.current_record.speech_end = time.time()
        
    def mark_stt_complete(self):
        """STT 완료 시간 기록"""
        self.current_record.stt_complete = time.time()
        
    def mark_postprocess_complete(self):
        """후처리 완료 시간 기록"""
        self.current_record.postprocess_complete = time.time()
        
    def mark_partial_text(self):
        """부분 텍스트 수신 시간 기록"""
        timestamp = time.time()
        self.current_record.partial_timestamps.append(timestamp)
        
    def print_summary(self):
        """현재 세션의 지연 시간 요약 출력"""
        record = self.current_record
        
        print("\n" + "="*60)
        print("⏱️  지연 시간 분석")
        print("="*60)
        
        if record.speech_start and record.speech_end:
            duration = (record.speech_end - record.speech_start) * 1000
            print(f"🎤 발화 지속 시간: {duration:.0f}ms")
            
        if record.speech_end and record.stt_complete:
            stt_latency = (record.stt_complete - record.speech_end) * 1000
            print(f"⚡ STT 처리 시간: {stt_latency:.0f}ms")
            
        if record.stt_complete and record.postprocess_complete:
            post_latency = (record.postprocess_complete - record.stt_complete) * 1000
            print(f"💬 AI 응답 시간: {post_latency:.0f}ms")
            
        if record.speech_end and record.postprocess_complete:
            total_latency = (record.postprocess_complete - record.speech_end) * 1000
            print(f"📈 전체 처리 시간: {total_latency:.0f}ms")
        elif record.speech_end and record.stt_complete:
            total_latency = (record.stt_complete - record.speech_end) * 1000
            print(f"📈 전체 처리 시간: {total_latency:.0f}ms")
            
        if record.partial_timestamps:
            if record.speech_start is not None:
                first_partial_latency = (record.partial_timestamps[0] - record.speech_start) * 1000
                print(f"⏱️  첫 부분 텍스트까지: {first_partial_latency:.0f}ms")
            
        print("="*60 + "\n")
        
        # 기록 저장
        self.records.append(record)
        
    def get_average_latency(self) -> Dict[str, float]:
        """
        평균 지연 시간 계산
        
        Returns:
            각 단계별 평균 지연 시간 (ms)
        """
        if not self.records:
            return {}
            
        stt_latencies = []
        post_latencies = []
        total_latencies = []
        
        for record in self.records:
            if record.speech_end and record.stt_complete:
                stt_latencies.append(
                    (record.stt_complete - record.speech_end) * 1000
                )
                
            if record.stt_complete and record.postprocess_complete:
                post_latencies.append(
                    (record.postprocess_complete - record.stt_complete) * 1000
                )
                
            if record.speech_end and record.postprocess_complete:
                total_latencies.append(
                    (record.postprocess_complete - record.speech_end) * 1000
                )
            elif record.speech_end and record.stt_complete:
                total_latencies.append(
                    (record.stt_complete - record.speech_end) * 1000
                )
                
        result = {}
        if stt_latencies:
            result['stt_avg'] = sum(stt_latencies) / len(stt_latencies)
        if post_latencies:
            result['post_avg'] = sum(post_latencies) / len(post_latencies)
        if total_latencies:
            result['total_avg'] = sum(total_latencies) / len(total_latencies)
            
        return result
        
    def _calculate_latency(
        self,
        start_time: Optional[float],
        end_time: Optional[float]
    ) -> Optional[float]:
        """
        두 시간 사이의 지연 시간 계산 (밀리초)
        
        Args:
            start_time: 시작 시간
            end_time: 종료 시간
            
        Returns:
            지연 시간 (ms) 또는 None
        """
        if start_time is None or end_time is None:
            return None
        return (end_time - start_time) * 1000
        
    def _print_timestamp(
        self,
        label: str,
        timestamp: float,
        latency: Optional[float] = None
    ):
        """
        타임스탬프 출력
        
        Args:
            label: 레이블
            timestamp: 타임스탬프
            latency: 지연 시간 (ms, 선택사항)
        """
        elapsed = timestamp - self.session_start
        time_str = f"{elapsed:06.3f}초"
        
        if latency is not None:
            print(f"[{label}] {time_str} (지연: {latency:.0f}ms)")
        else:
            print(f"[{label}] {time_str}")
            
    def reset(self):
        """현재 기록 초기화"""
        self.current_record = LatencyRecord()

