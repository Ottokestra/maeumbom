"""
마음봄 프로토타입 2 - Silero VAD + Whisper.cpp
실시간 음성 인식
"""

import sys
import yaml
import time
import numpy as np
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from common.audio_handler import AudioHandler, AudioBuffer
from common.latency_tracker import LatencyTracker
from faster_whisper.vad_engine import SileroVAD
from faster_whisper.whisper_engine import WhisperSTT


class MaumBomSTT:
    """마음봄 통합 STT 시스템"""
    
    def __init__(self, config_path: str = "config.yaml"):
        """
        Args:
            config_path: 설정 파일 경로
        """
        # 설정 로드
        print("📄 설정 파일 로딩 중...")
        with open(config_path, 'r', encoding='utf-8') as f:
            self.config = yaml.safe_load(f)
            
        # 컴포넌트 초기화
        self._init_components()
        
    def _init_components(self):
        """컴포넌트 초기화"""
        # 오디오 핸들러
        audio_config = self.config['audio']
        self.audio_handler = AudioHandler(
            sample_rate=audio_config['sample_rate'],
            channels=audio_config['channels'],
            chunk_size=audio_config['chunk_size']
        )
        
        # 오디오 버퍼
        self.audio_buffer = AudioBuffer(
            max_duration=self.config['vad']['max_speech_duration_s'],
            sample_rate=audio_config['sample_rate']
        )
        
        # VAD 엔진
        vad_config = self.config['vad']
        self.vad = SileroVAD(
            threshold=vad_config['threshold'],
            min_speech_duration_ms=vad_config['min_speech_duration_ms'],
            max_speech_duration_s=vad_config['max_speech_duration_s'],
            min_silence_duration_ms=vad_config['min_silence_duration_ms'],
            short_silence_duration_ms=vad_config.get('short_silence_duration_ms', 500),
            speech_pad_ms=vad_config['speech_pad_ms'],
            sample_rate=audio_config['sample_rate']
        )
        
        # Whisper STT
        whisper_config = self.config['whisper']
        self.whisper = WhisperSTT(
            model_path=whisper_config['model_path'],
            language="ko",  # 한국어 고정
            n_threads=whisper_config['n_threads'],
            sample_rate=audio_config['sample_rate']
        )
        
        # 지연 시간 추적기
        self.latency_tracker = LatencyTracker()
        
    def run(self):
        """메인 실행 루프"""
        print("\n" + "="*60)
        print("🎤 마이크 준비 완료. 말씀해주세요...")
        print("   (Ctrl+C로 종료)")
        print("="*60 + "\n")
        
        try:
            # 오디오 스트림 시작
            self.audio_handler.start_stream()
            
            # 메인 루프
            is_currently_speaking = False
            is_processing = False  # 처리 중 플래그 추가
            speech_buffer = []
            committed_text = ""  # 확정된 텍스트 (VAD 짧은 침묵 감지 시 확정)
            last_commit_buffer_length = 0  # 마지막 확정 시점의 버퍼 길이
            last_commit_time = time.time()  # 마지막 확정 시간
            last_stt_time = time.time()
            stt_interval = 1.5  # 1.5초마다 중간 STT 실행
            commit_interval = 3.0  # 3초마다 강제 확정
            
            while True:
                # 오디오 청크 읽기
                audio_bytes = self.audio_handler.read_chunk()
                if audio_bytes is None:
                    continue
                    
                # numpy 배열로 변환
                audio_chunk = self.audio_handler.bytes_to_numpy(audio_bytes)
                
                # 처리 중이면 오디오 큐 비우고 VAD 체크 생략 (중요!)
                if is_processing:
                    # 오디오 큐에 쌓인 데이터 버리기
                    while not self.audio_handler.audio_queue.empty():
                        try:
                            self.audio_handler.audio_queue.get_nowait()
                        except:
                            break
                    continue
                
                # ⭐ VAD 처리 먼저 실행 (침묵 감지 업데이트)
                is_speech_end, speech_audio, is_short_pause = self.vad.process_chunk(audio_chunk)
                
                # VAD 상태 확인 (발화 중인지)
                speech_prob = self.vad.get_speech_probability(audio_chunk)
                
                # 발화 시작 감지
                if speech_prob > self.vad.threshold and not is_currently_speaking:
                    is_currently_speaking = True
                    speech_buffer = []
                    committed_text = ""  # 새 발화 시작 시 확정 텍스트 초기화
                    last_commit_buffer_length = 0
                    last_commit_time = time.time()  # 확정 시간 초기화
                    print("\n🎤 [발화 시작] 말씀하세요...", flush=True)
                    self.latency_tracker.mark_speech_start()
                
                # 발화 중 처리
                if is_currently_speaking and not is_speech_end:
                    # 버퍼에 추가
                    speech_buffer.append(audio_chunk)
                    
                    # 주기적 VAD 상태 로그 제거 (Log Flooding 방지)
                    # 상태 변화 시에만 로그 출력 (발화 시작, 짧은 침묵, 긴 침묵, 발화 종료)
                    
                    current_time = time.time()
                    should_commit = False
                    commit_reason = ""
                    
                    # ⭐ 확정 트리거 조건 체크
                    # 1. 짧은 침묵 감지 시 (버퍼에 충분한 오디오가 있을 때만)
                    buffer_duration = sum(len(chunk) for chunk in speech_buffer) / self.audio_handler.sample_rate
                    if is_short_pause and buffer_duration >= 0.5:  # 최소 0.5초 이상
                        should_commit = True
                        commit_reason = "짧은 침묵 감지"
                    
                    # 2. 시간 기반 강제 확정 (3초마다, 버퍼에 충분한 오디오가 있을 때만)
                    elif current_time - last_commit_time >= commit_interval and buffer_duration >= 1.0:  # 최소 1초 이상
                        should_commit = True
                        commit_reason = f"시간 경과 ({commit_interval}초)"
                    
                    # ⭐ 확정 실행
                    if should_commit and len(speech_buffer) > last_commit_buffer_length:
                        buffer_length = len(speech_buffer)
                        total_audio_sec = sum(len(chunk) for chunk in speech_buffer) / self.audio_handler.sample_rate
                        new_audio_sec = sum(len(chunk) for chunk in speech_buffer[last_commit_buffer_length:]) / self.audio_handler.sample_rate
                        
                        # ⭐ 최소 오디오 길이 체크 (자원 낭비 방지)
                        if new_audio_sec < 0.5:
                            print(f"[디버그] 새로운 오디오가 너무 짧음 ({new_audio_sec:.1f}초 < 0.5초) - 확정 건너뜀", flush=True)
                            last_commit_time = current_time  # 무한루프 방지
                            continue
                        
                        print(f"\n[디버그] {commit_reason} -> 확정 실행", flush=True)
                        print(f"[디버그] 버퍼: 전체 {buffer_length}청크 ({total_audio_sec:.1f}초), 새로운 부분 {buffer_length - last_commit_buffer_length}청크 ({new_audio_sec:.1f}초)", flush=True)
                        
                        try:
                            stt_start = time.time()
                            
                            # ⭐ 새로운 부분만 처리 (병목 해결!)
                            if last_commit_buffer_length > 0:
                                # 이미 확정된 부분이 있음 - 새로운 부분만 처리
                                new_audio_chunks = speech_buffer[last_commit_buffer_length:]
                                new_audio = np.concatenate(new_audio_chunks)
                                print(f"[디버그] 증분 확정: 새로운 {len(new_audio_chunks)}청크만 STT 처리...", flush=True)
                                # ⭐ initial_prompt로 이전 확정 텍스트 전달 (문맥 유지)
                                transcript, quality = self.whisper.transcribe(
                                    new_audio, 
                                    callback=None,
                                    initial_prompt=committed_text[-100:] if committed_text else ""  # 마지막 100자
                                )
                            else:
                                # 첫 확정 - 전체 처리
                                buffer_audio = np.concatenate(speech_buffer)
                                print(f"[디버그] 첫 확정: 전체 {len(speech_buffer)}청크 STT 처리...", flush=True)
                                transcript, quality = self.whisper.transcribe(buffer_audio, callback=None)
                            
                            stt_time = (time.time() - stt_start) * 1000
                            
                            if quality in ["success", "medium"] and transcript:
                                # ⭐ 텍스트 누적 (이전 확정 + 새로운 텍스트)
                                if committed_text:
                                    committed_text = committed_text + " " + transcript
                                else:
                                    committed_text = transcript
                                
                                last_commit_buffer_length = len(speech_buffer)
                                last_commit_time = current_time
                                print(f"✓ [확정] {committed_text} (처리시간: {stt_time:.0f}ms)", flush=True)
                            elif quality == "low_quality" and transcript:
                                # ⭐ low_quality도 확정으로 처리 (무한루프 방지)
                                if committed_text:
                                    committed_text = committed_text + " " + transcript
                                else:
                                    committed_text = transcript
                                
                                last_commit_buffer_length = len(speech_buffer)
                                last_commit_time = current_time
                                print(f"⚠️  [확정/품질낮음] {committed_text} (처리시간: {stt_time:.0f}ms)", flush=True)
                            elif quality == "no_speech":
                                # 음성이 없는 경우 - 확정 시간만 업데이트하고 버퍼는 유지
                                print(f"[디버그] 음성 없음 - 확정 건너뜀 (버퍼 유지)", flush=True)
                                last_commit_time = current_time  # 시간만 업데이트 (무한 반복 방지)
                            else:
                                print(f"[디버그] 확정 실패: 품질={quality}, 텍스트='{transcript}'", flush=True)
                                last_commit_time = current_time  # ⭐ 무한루프 방지를 위해 시간 업데이트
                        except Exception as e:
                            print(f"[디버그] 확정 오류: {e}", flush=True)
                            import traceback
                            traceback.print_exc()
                    
                    # 일정 시간마다 중간 STT 실행 (새로운 부분만!)
                    if current_time - last_stt_time >= stt_interval:
                        if len(speech_buffer) > last_commit_buffer_length:
                            # ⭐ 확정된 이후의 새로운 부분만 처리 (병목 해결!)
                            if last_commit_buffer_length > 0:
                                # 새로운 부분만 추출
                                new_audio_chunks = speech_buffer[last_commit_buffer_length:]
                                if len(new_audio_chunks) > 0:
                                    new_audio = np.concatenate(new_audio_chunks)
                                    new_audio_sec = len(new_audio) / self.audio_handler.sample_rate
                                    
                                    # ⭐ 최소 오디오 길이 체크 (0.5초)
                                    if new_audio_sec >= 0.5:
                                        print(f"\n[디버그] 증분 STT: 새로운 {len(new_audio_chunks)}청크 ({new_audio_sec:.1f}초) 처리 중...", end="", flush=True)
                                        stt_start = time.time()
                                        partial_text = self._process_partial_speech_incremental(new_audio, committed_text)
                                        stt_time = (time.time() - stt_start) * 1000
                                        
                                        if partial_text and committed_text:
                                            # 확정된 텍스트 + 새로운 부분
                                            print(f"\r💬 [실시간] {committed_text} {partial_text} ({stt_time:.0f}ms)", end="", flush=True)
                                        elif partial_text:
                                            print(f"\r💬 [실시간] {partial_text} ({stt_time:.0f}ms)", end="", flush=True)
                            else:
                                # 아직 확정된 것이 없으면 전체 처리
                                buffer_audio = np.concatenate(speech_buffer)
                                total_audio_sec = len(buffer_audio) / self.audio_handler.sample_rate
                                
                                # ⭐ 최소 오디오 길이 체크 (0.5초)
                                if total_audio_sec >= 0.5:
                                    print(f"\n[디버그] 전체 STT: {len(speech_buffer)}청크 ({total_audio_sec:.1f}초) 처리 중...", end="", flush=True)
                                    self._process_partial_speech(buffer_audio)
                            
                            last_stt_time = current_time
                
                if is_speech_end and speech_audio is not None:
                    print("\n🔚 [발화 종료] 최종 처리 중...", flush=True)
                    is_currently_speaking = False
                    speech_buffer = []
                    is_processing = True  # 처리 시작
                    
                    try:
                        # VAD 상태 완전히 리셋
                        self.vad.reset()
                        
                        # 발화 완료 - 최종 처리
                        self._process_speech(speech_audio)
                        
                    except Exception as e:
                        print(f"\n❌ 처리 중 오류: {e}")
                        import traceback
                        traceback.print_exc()
                        
                    finally:
                        # 반드시 실행: 처리 완료 후 오디오 큐 비우기
                        try:
                            queue_cleared = 0
                            while not self.audio_handler.audio_queue.empty():
                                try:
                                    self.audio_handler.audio_queue.get_nowait()
                                    queue_cleared += 1
                                    if queue_cleared > 1000:  # 무한 루프 방지
                                        break
                                except:
                                    break
                        except Exception as e:
                            print(f"[디버그] 큐 비우기 오류 (무시): {e}")
                        
                        # 반드시 실행: VAD 한 번 더 리셋 (확실하게)
                        try:
                            self.vad.reset()
                        except Exception as e:
                            print(f"[디버그] VAD 리셋 오류 (무시): {e}")
                        
                        # 반드시 실행: 처리 플래그 해제
                        is_processing = False
                        is_currently_speaking = False  # 혹시 모를 상태 초기화
                        speech_buffer = []
                        committed_text = ""  # 확정 텍스트 초기화
                        last_commit_buffer_length = 0  # 확정 버퍼 길이 초기화
                        last_commit_time = time.time()  # 확정 시간 초기화
                        
                        print("\n" + "="*60)
                        print("🎤 다음 발화를 기다리는 중...")
                        print("="*60 + "\n")
                    
        except KeyboardInterrupt:
            print("\n\n👋 프로그램을 종료합니다...")
            
        except Exception as e:
            print(f"\n❌ 오류 발생: {e}")
            import traceback
            traceback.print_exc()
            
        finally:
            self.audio_handler.close()
    
    def _process_partial_speech(self, audio: np.ndarray):
        """
        발화 중 부분 음성 처리 (실시간 중간 결과) - 전체 오디오 처리
        
        Args:
            audio: 부분 오디오 데이터
        """
        try:
            # 간단한 STT만 실행 (후처리 없음)
            transcript, quality = self.whisper.transcribe(audio, callback=None)
            # 품질이 좋을 때만 출력
            if transcript and quality == "success":
                print(f"\r💬 [실시간] {transcript}", end="", flush=True)
        except Exception as e:
            # 중간 처리 오류는 무시
            pass
    
    def _process_partial_speech_incremental(self, audio: np.ndarray, context: str = "") -> str:
        """
        ⭐ 발화 중 부분 음성 처리 (증분 방식) - 새로운 부분만 처리
        
        Args:
            audio: 새로운 부분의 오디오 데이터
            context: 이전 확정 텍스트 (문맥 유지용)
            
        Returns:
            인식된 텍스트 (확정 이후의 새로운 부분)
        """
        try:
            # ⭐ initial_prompt로 문맥 전달
            transcript, quality = self.whisper.transcribe(
                audio, 
                callback=None,
                initial_prompt=context[-100:] if context else ""  # 마지막 100자
            )
            # 품질이 좋을 때만 반환
            if transcript and quality in ["success", "medium"]:
                return transcript
        except Exception as e:
            # 중간 처리 오류는 무시
            pass
        return ""
            
    def _process_speech(self, audio: np.ndarray):
        """
        발화 처리 파이프라인
        
        Args:
            audio: 발화 오디오 데이터
        """
        try:
            # 발화 종료 시간 기록
            self.latency_tracker.mark_speech_end()
            
            # 1. STT 처리
            print("\n🔄 음성 인식 중...")
            
            # 부분 텍스트 콜백
            last_text = [""]
            def partial_callback(text):
                # 마지막 텍스트와 다를 때만 출력 (중복 방지)
                if text != last_text[0]:
                    print(f"\r[실시간] {text}", end="", flush=True)
                    last_text[0] = text
                    self.latency_tracker.mark_partial_text()
            
            # Whisper STT (품질 검사 포함)
            stt_start = time.time()
            transcript, quality = self.whisper.transcribe(audio, callback=partial_callback)
            stt_time = (time.time() - stt_start) * 1000
            
            self.latency_tracker.mark_stt_complete()
            
            # 품질에 따른 처리
            if quality == "no_speech":
                print(f"\n⚠️  [음성 미감지] 말소리가 감지되지 않았습니다.")
                print(f"   (처리 시간: {stt_time:.0f}ms)")
                self.latency_tracker.print_summary()
                return  # 처리 중단
                
            elif quality == "low_quality":
                print(f"\n⚠️  [인식 불가] 소음이 심해 인식할 수 없습니다.")
                print(f"   인식된 텍스트: '{transcript}'")
                print(f"   (처리 시간: {stt_time:.0f}ms)")
                print("\n💡 조용한 곳에서 다시 말씀해주세요.")
                self.latency_tracker.print_summary()
                return  # 처리 중단
            
            # 품질에 따른 출력
            if quality == "medium":
                print(f"\n⚠️  [STT 완료] {transcript} (품질: 보통)")
                print(f"   (처리 시간: {stt_time:.0f}ms)")
            else:
                print(f"\n✅ [STT 완료] {transcript}")
                print(f"   (처리 시간: {stt_time:.0f}ms)")
            
            # 2. 지연 시간 요약
            self.latency_tracker.print_summary()
            
        except Exception as e:
            print(f"\n❌ _process_speech 오류: {e}")
            import traceback
            traceback.print_exc()


def main():
    """메인 함수"""
    print("="*60)
    print("🌸 마음봄(MaumBom) STT 엔진")
    print("   Silero VAD + Faster-Whisper")
    print("="*60)
    print()
    
    # 설정 파일 확인
    config_path = Path(__file__).parent / "config.yaml"
    if not config_path.exists():
        print("❌ config.yaml 파일이 없습니다!")
        return
        
    # 시스템 생성 및 실행
    try:
        system = MaumBomSTT(str(config_path))
        system.run()
        
    except Exception as e:
        print(f"❌ 초기화 오류: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()

