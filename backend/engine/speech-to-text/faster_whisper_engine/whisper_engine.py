"""
마음봄 - Faster-Whisper 엔진
실시간 음성-텍스트 변환
"""

import numpy as np
from typing import Optional, List, Callable
from pathlib import Path
import sys

# faster_whisper import (site-packages에서 import하기 위해 sys.path 조작)
WhisperModel = None
try:
    # 프로젝토리 디렉토리를 sys.path에서 제거
    current_file = Path(__file__).resolve()
    project_dirs = [
        str(current_file.parent),  # faster_whisper 디렉토리
        str(current_file.parent.parent),  # speech-to-text 디렉토리
        str(current_file.parent.parent.parent),  # engine 디렉토리
        str(current_file.parent.parent.parent.parent),  # backend 디렉토리
    ]

    original_path = sys.path.copy()
    sys.path = [p for p in sys.path if p not in project_dirs]

    from faster_whisper import WhisperModel as _WhisperModel

    WhisperModel = _WhisperModel

    # sys.path 복원
    sys.path = original_path
except ImportError as e:
    print(f"[WARNING] faster_whisper import failed: {e}")
    WhisperModel = None


class WhisperSTT:
    """Faster-Whisper를 사용한 음성-텍스트 변환"""

    def __init__(
        self,
        model_path: str = "models/ggml-base.bin",  # 호환성 유지, 사용 안 함
        language: str = "ko",
        n_threads: int = 8,
        sample_rate: int = 16000,
    ):
        """
        Args:
            model_path: 레거시 파라미터 (사용 안 함)
            language: 언어 코드 (한국어 고정)
            n_threads: 사용할 스레드 수
            sample_rate: 샘플링 레이트
        """
        self.language = language
        self.n_threads = n_threads
        self.sample_rate = sample_rate

        # Faster-Whisper 모델 로드
        self.model = None
        self._load_model()

    def _load_model(self):
        """Faster-Whisper 모델 로드"""
        try:
            if WhisperModel is None:
                raise ImportError("faster-whisper 패키지가 설치되지 않았습니다")

            print("📥 Faster-Whisper 모델 로딩 중 (large-v3-turbo)...")
            self.model = WhisperModel(
                "large-v3-turbo",
                device="cpu",
                compute_type="int8",
                num_workers=self.n_threads,
            )
            print("✅ Faster-Whisper large-v3-turbo 로드 완료")

        except ImportError as e:
            print(f"❌ faster-whisper를 찾을 수 없습니다: {e}")
            print("💡 설치: pip install faster-whisper")
            raise

        except Exception as e:
            print(f"❌ Faster-Whisper 로드 실패: {e}")
            import traceback

            traceback.print_exc()
            raise

    def transcribe(
        self,
        audio: np.ndarray,
        callback: Optional[Callable[[str], None]] = None,
        initial_prompt: str = "",
    ) -> tuple:
        """
        오디오를 텍스트로 변환 (실시간 스트리밍 + 품질 검사)

        Args:
            audio: 오디오 데이터 (numpy array, float32)
            callback: 부분 텍스트 콜백 함수
            initial_prompt: 이전 확정 텍스트 (문맥 유지용)

        Returns:
            (텍스트, 품질 상태) 튜플
            - 품질 상태: "success", "medium", "low_quality", "no_speech", "error"
        """
        if self.model is None:
            return "[모델 로드 실패]", "error"

        try:
            # Faster-Whisper로 실시간 세그먼트 스트리밍 (환각 방지 최적화)
            segments, info = self.model.transcribe(
                audio,
                language="ko",
                beam_size=1,
                # [중요] 짧은 단어 인식을 위해 필터링 해제 또는 완화
                log_prob_threshold=None,  # ⭐ 기본값(-1.0) 대신 None으로 설정하여 확신도가 낮아도 반환하게 함
                # 또는 log_prob_threshold=-3.0, (너무 이상한 잡음이 섞인다면 -3.0 정도로 설정)
                condition_on_previous_text=False,
                initial_prompt=initial_prompt if initial_prompt else None,
                temperature=0.0,
                # [수정] 너무 엄격하면 짧은 텍스트가 걸러질 수 있음
                compression_ratio_threshold=2.4,  # ⭐ 2.0 -> 2.4로 완화
                no_speech_threshold=0.6,
                repetition_penalty=1.2,
                vad_filter=False,  # 외부 VAD 사용 중이므로 유지
                word_timestamps=False,
            )

            # 세그먼트별로 실시간 처리 + 품질 검사
            full_text = ""
            total_logprob = 0
            segment_count = 0

            for segment in segments:
                segment_text = segment.text.strip()

                # 세그먼트 품질 검사
                avg_logprob = (
                    segment.avg_logprob if hasattr(segment, "avg_logprob") else 0
                )
                no_speech_prob = (
                    segment.no_speech_prob if hasattr(segment, "no_speech_prob") else 0
                )

                # 디버그 로그
                # print(f"[디버그] 세그먼트: '{segment_text}' | logprob: {avg_logprob:.2f} | no_speech: {no_speech_prob:.2f}")

                if segment_text:
                    full_text += segment_text + " "
                    total_logprob += avg_logprob
                    segment_count += 1

                    # 부분 텍스트 콜백 (실시간 출력)
                    if callback:
                        callback(full_text.strip())

            # 전체 품질 평가
            final_text = full_text.strip()

            if not final_text:
                return "", "no_speech"

            # 🚨 반복 패턴 감지 (숫자 카운팅, 기호 반복 등)
            if self._is_repetitive_pattern(final_text):
                print(f"[디버그] 반복 패턴 감지: '{final_text[:50]}...'")
                return final_text, "low_quality"  # 반복 패턴은 소음으로 처리

            avg_quality = total_logprob / segment_count if segment_count > 0 else -999

            # 디버그 로그 (품질 판단 과정 확인용)
            print(f"[품질 판단] 텍스트: '{final_text}' | logprob: {avg_quality:.3f}")

            # 품질 판단 (logprob 기반)
            # faster-whisper의 avg_logprob 범위: 보통 -1.0 ~ 0.0
            if avg_quality > -0.5:
                # 확신 매우 높음 - 정상
                print(f"[품질 판단] → success")
                return final_text, "success"
            elif avg_quality > -1.0:
                # 확신 중간 - 사용 가능
                print(f"[품질 판단] → medium")
                return final_text, "medium"
            else:
                # 확신 낮음 - 소음 가능성
                print(f"[품질 판단] → low_quality")
                return final_text, "low_quality"

        except Exception as e:
            print(f"❌ 음성 인식 오류: {e}")
            import traceback

            traceback.print_exc()
            return "[인식 실패]", "error"

    def _is_repetitive_pattern(self, text: str) -> bool:
        """
        반복 패턴 감지 (숫자 카운팅, 기호 반복 등)

        Args:
            text: 검사할 텍스트

        Returns:
            반복 패턴이면 True
        """
        import re

        # 1. 숫자 카운팅 패턴 (1, 2, 3, 4... 또는 하나, 둘, 셋...)
        if re.search(r"(\d+[,\s]*){4,}", text):  # 숫자가 4개 이상 연속
            return True

        # 2. 같은 단어 4번 이상 반복
        words = text.split()
        if len(words) >= 4:
            for i in range(len(words) - 3):
                if words[i] == words[i + 1] == words[i + 2] == words[i + 3]:
                    return True

        # 3. 기호 반복 (.,.,. 또는 ..., 등)
        if re.search(r"([.,!?;][\s]*){4,}", text):
            return True

        # 4. 같은 문자가 10번 이상 반복
        if re.search(r"(.)\1{9,}", text):
            return True

        # 5. 짧은 문장이 계속 반복 (예: "네 네 네 네")
        if len(text) < 30:  # 짧은 텍스트만 체크
            unique_words = set(words)
            if len(words) >= 3 and len(unique_words) <= 2:
                return True

        return False

    def transcribe_with_timestamps(self, audio: np.ndarray) -> List[dict]:
        """
        타임스탬프와 함께 텍스트 변환

        Args:
            audio: 오디오 데이터

        Returns:
            세그먼트 리스트 [{text, start, end}, ...]
        """
        if self.model is None:
            return []

        try:
            segments, info = self.model.transcribe(
                audio, language=self.language, vad_filter=False, beam_size=5
            )

            result_segments = []
            for segment in segments:
                if segment.text.strip():
                    result_segments.append(
                        {
                            "text": segment.text.strip(),
                            "start": segment.start,
                            "end": segment.end,
                        }
                    )

            return result_segments

        except Exception as e:
            print(f"❌ 음성 인식 오류: {e}")
            return []
