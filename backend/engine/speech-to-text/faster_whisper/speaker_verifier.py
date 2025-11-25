"""
Speaker Verification Module using Resemblyzer
화자 검증 및 점진적 프로필 완성 (Progressive Profiling)
"""

import numpy as np
from typing import Dict, Optional, Tuple
import yaml
from pathlib import Path


class SpeakerVerifier:
    """
    Resemblyzer를 사용한 화자 검증 시스템
    
    주요 기능:
    - 음성 임베딩 추출
    - 화자 간 유사도 계산
    - 점진적 프로필 업데이트
    - 품질 게이트 (Quality Gate)
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Args:
            config_path: config.yaml 파일 경로 (선택)
        """
        # 설정 로드
        if config_path is None:
            config_path = Path(__file__).parent / "config.yaml"
        
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
        
        self.config = config.get('speaker_verification', {})
        self.enabled = self.config.get('enabled', True)
        self.similarity_threshold = self.config.get('similarity_threshold', 0.75)
        self.min_audio_duration = self.config.get('min_audio_duration', 3.0)
        self.update_weight = self.config.get('update_weight', 0.3)
        
        # Resemblyzer 모델 (Lazy initialization)
        self._model = None
        self._sample_rate = config.get('audio', {}).get('sample_rate', 16000)
        
    def _get_model(self):
        """Resemblyzer 모델 Lazy 로드"""
        if self._model is None:
            try:
                from resemblyzer import VoiceEncoder
                print("[Speaker Verifier] Resemblyzer 모델 로딩 중...")
                self._model = VoiceEncoder()
                print("[Speaker Verifier] ✅ Resemblyzer 로드 완료")
            except ImportError as e:
                print(f"[Speaker Verifier] ❌ Resemblyzer를 찾을 수 없습니다: {e}")
                print("[Speaker Verifier] 💡 설치: pip install resemblyzer")
                raise
            except Exception as e:
                print(f"[Speaker Verifier] ❌ Resemblyzer 로드 실패: {e}")
                raise
        return self._model
    
    def extract_embedding(self, audio: np.ndarray) -> np.ndarray:
        """
        오디오에서 화자 임베딩 추출
        
        Args:
            audio: 오디오 데이터 (numpy array, float32, 16kHz)
            
        Returns:
            임베딩 벡터 (256차원)
        """
        if not self.enabled:
            return None
        
        try:
            model = self._get_model()
            
            # Resemblyzer는 16kHz 기대
            if len(audio) < self.min_audio_duration * self._sample_rate:
                print(f"[Speaker Verifier] ⚠️ 오디오가 너무 짧음 ({len(audio) / self._sample_rate:.1f}초 < {self.min_audio_duration}초)")
                return None
            
            # 임베딩 추출
            embedding = model.embed_utterance(audio)
            print(f"[Speaker Verifier] ✅ 임베딩 추출 완료 (shape: {embedding.shape})")
            return embedding
            
        except Exception as e:
            print(f"[Speaker Verifier] ❌ 임베딩 추출 실패: {e}")
            return None
    
    def compare_speakers(self, emb1: np.ndarray, emb2: np.ndarray) -> float:
        """
        두 화자 임베딩 간 유사도 계산 (코사인 유사도)
        
        Args:
            emb1: 첫 번째 임베딩
            emb2: 두 번째 임베딩
            
        Returns:
            유사도 (0~1, 1에 가까울수록 같은 화자)
        """
        if emb1 is None or emb2 is None:
            return 0.0
        
        # 코사인 유사도 계산
        similarity = np.dot(emb1, emb2) / (np.linalg.norm(emb1) * np.linalg.norm(emb2))
        return float(similarity)
    
    def identify_speaker(
        self, 
        current_embedding: np.ndarray, 
        existing_profiles: Dict[str, dict]
    ) -> Tuple[str, float]:
        """
        현재 임베딩을 기존 프로필과 비교하여 화자 식별
        
        Args:
            current_embedding: 현재 오디오의 임베딩
            existing_profiles: 기존 화자 프로필 딕셔너리
                {"user-A": {"embedding": np.ndarray, "quality": str, ...}, ...}
            
        Returns:
            (화자 ID, 최고 유사도) 튜플
            - 기존 화자와 매칭되면 해당 ID
            - 매칭 안 되면 새 ID (user-A, user-B, ...)
        """
        if current_embedding is None:
            return None, 0.0
        
        if not existing_profiles:
            # 첫 번째 사용자
            return "user-A", 0.0
        
        # 모든 기존 프로필과 비교
        best_match_id = None
        best_similarity = 0.0
        
        for speaker_id, profile in existing_profiles.items():
            existing_embedding = profile.get("embedding")
            if existing_embedding is None:
                continue
            
            similarity = self.compare_speakers(current_embedding, existing_embedding)
            print(f"[Speaker Debug] {speaker_id} 유사도: {similarity:.3f}")
            
            if similarity > best_similarity:
                best_similarity = similarity
                best_match_id = speaker_id
        
        # 임계값 이상이면 기존 화자로 인식
        if best_similarity >= self.similarity_threshold:
            print(f"[Speaker Debug] ✅ 기존 화자 매칭: {best_match_id} (유사도: {best_similarity:.3f})")
            return best_match_id, best_similarity
        
        # 새로운 화자
        # user-A, user-B, ... 형식으로 ID 생성
        existing_count = len(existing_profiles)
        new_id = f"user-{chr(65 + existing_count)}"  # A=65, B=66, ...
        print(f"[Speaker Debug] 🆕 새 화자 감지: {new_id} (최고 유사도: {best_similarity:.3f} < {self.similarity_threshold})")
        return new_id, 0.0
    
    def should_update_profile(
        self, 
        new_quality: str, 
        old_quality: str
    ) -> bool:
        """
        기존 프로필을 새 임베딩으로 업데이트할지 판단
        
        Args:
            new_quality: 새 오디오 품질 (success/medium/low_quality)
            old_quality: 기존 프로필 품질
            
        Returns:
            업데이트 여부
        """
        quality_rank = {
            "success": 3,
            "medium": 2,
            "low_quality": 1,
            "no_speech": 0
        }
        
        new_rank = quality_rank.get(new_quality, 0)
        old_rank = quality_rank.get(old_quality, 0)
        
        should_update = new_rank > old_rank
        
        print(f"[Speaker Debug] 프로필 업데이트 판단: new={new_quality}({new_rank}) vs old={old_quality}({old_rank}) → {'업데이트' if should_update else '유지'}")
        return should_update
    
    def update_embedding(
        self, 
        old_embedding: np.ndarray, 
        new_embedding: np.ndarray,
        speaker_id: str = "unknown"
    ) -> np.ndarray:
        """
        점진적 임베딩 업데이트 (가중 평균)
        
        Args:
            old_embedding: 기존 임베딩
            new_embedding: 새 임베딩
            speaker_id: 화자 ID (디버깅용)
            
        Returns:
            업데이트된 임베딩
        """
        if old_embedding is None:
            return new_embedding
        if new_embedding is None:
            return old_embedding
        
        # 가중 평균: new_weight * new + (1 - new_weight) * old
        updated_embedding = (
            self.update_weight * new_embedding 
            + (1 - self.update_weight) * old_embedding
        )
        
        # 정규화 (코사인 유사도를 위해)
        updated_embedding = updated_embedding / np.linalg.norm(updated_embedding)
        
        # 업데이트 전후 비교
        old_vs_new_sim = self.compare_speakers(old_embedding, new_embedding)
        old_vs_updated_sim = self.compare_speakers(old_embedding, updated_embedding)
        new_vs_updated_sim = self.compare_speakers(new_embedding, updated_embedding)
        
        print(f"[Speaker Update] 🔄 {speaker_id} 프로필 점진적 업데이트:")
        print(f"  - old ↔ new 유사도: {old_vs_new_sim:.3f}")
        print(f"  - old ↔ updated 유사도: {old_vs_updated_sim:.3f}")
        print(f"  - new ↔ updated 유사도: {new_vs_updated_sim:.3f}")
        print(f"  - 가중치: new={self.update_weight}, old={1-self.update_weight}")
        
        return updated_embedding
