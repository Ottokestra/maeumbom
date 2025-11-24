"""
LangChain Agent용 Memory Layer 어댑터

장기 기억을 저장하고 관리하는 시스템
- 반복되는 감정 패턴
- 장기 고민 사항 (수면, 건강, 인간관계 등)
- 사용자 선호도
- 위험 수준 기반 자동 저장
"""
import json
import os
from pathlib import Path
from typing import List, Dict, Any, Optional
from datetime import datetime
from collections import defaultdict


# 메모리 저장 경로
MEMORY_STORAGE_PATH = Path(__file__).parent.parent / "memory_data"
MEMORY_STORAGE_PATH.mkdir(parents=True, exist_ok=True)


class MemoryCategory:
    """장기 기억 카테고리"""
    SLEEP_ISSUE = "sleep_issue"
    HEALTH_CONCERN = "health_concern"
    RELATIONSHIP = "relationship"
    ANXIETY_PATTERN = "anxiety_pattern"
    MOOD_PATTERN = "mood_pattern"
    MENOPAUSE_SYMPTOM = "menopause_symptom"
    PERSONAL_PREFERENCE = "personal_preference"
    OTHER = "other"


class MemoryType:
    """기억 타입"""
    LONG_TERM_PATTERN = "long_term_pattern"  # 반복되는 패턴
    PERSISTENT_CONCERN = "persistent_concern"  # 지속적 고민
    USER_PREFERENCE = "user_preference"  # 사용자 선호


class MemoryLayer:
    """
    장기 기억 저장 및 조회 시스템
    
    저장 조건:
    - 위험 수준이 'watch' 이상
    - 반복되는 감정 패턴
    - 사용자가 명시적으로 언급한 장기 고민
    """
    
    def __init__(self, storage_path: Path = MEMORY_STORAGE_PATH):
        """
        초기화
        
        Args:
            storage_path: 메모리 저장 경로
        """
        self.storage_path = storage_path
        self.storage_path.mkdir(parents=True, exist_ok=True)
        
        # 세션별 메모리 저장소
        # {session_id: {memory_id: memory_dict}}
        self._memories: Dict[str, Dict[str, Dict]] = defaultdict(dict)
        
        # 전역 메모리 저장소 (세션 간 공유)
        self._global_memories: Dict[str, Dict] = {}
        
        # 파일에서 로드
        self._load_from_file()
    
    def should_store_in_memory(
        self, 
        user_text: str,
        emotion_result: Dict[str, Any],
        session_history: List[Dict] = None
    ) -> bool:
        """
        장기 기억 저장 여부 판단
        
        Args:
            user_text: 사용자 입력
            emotion_result: 감정 분석 결과
            session_history: 세션 히스토리 (선택)
            
        Returns:
            저장 여부
        """
        # 1. 위험 수준 체크
        risk_level = emotion_result.get("service_signals", {}).get("risk_level", "low")
        if risk_level in ["watch", "alert", "critical"]:
            return True
        
        # 2. 반복 키워드 체크
        repeat_keywords = ["계속", "반복", "매번", "항상", "요즘", "최근", "자꾸"]
        if any(keyword in user_text for keyword in repeat_keywords):
            return True
        
        # 3. 장기 고민 키워드 체크
        concern_keywords = ["잠", "수면", "불면", "건강", "관계", "스트레스", 
                           "불안", "우울", "열감", "갱년기", "기분"]
        if any(keyword in user_text for keyword in concern_keywords):
            # 세션 히스토리에서 같은 주제가 2회 이상 나왔는지 체크
            if session_history and len(session_history) >= 4:
                count = sum(1 for msg in session_history 
                           if msg.get("role") == "user" and 
                           any(kw in msg.get("content", "") for kw in concern_keywords))
                if count >= 2:
                    return True
        
        return False
    
    def categorize_concern(self, user_text: str, emotion_result: Dict) -> str:
        """
        고민 카테고리 분류
        
        Args:
            user_text: 사용자 입력
            emotion_result: 감정 분석 결과
            
        Returns:
            카테고리 문자열
        """
        text_lower = user_text.lower()
        
        if any(kw in text_lower for kw in ["잠", "수면", "불면", "자다", "깨"]):
            return MemoryCategory.SLEEP_ISSUE
        
        if any(kw in text_lower for kw in ["열감", "갱년기", "안면홍조", "식은땀"]):
            return MemoryCategory.MENOPAUSE_SYMPTOM
        
        if any(kw in text_lower for kw in ["건강", "아프", "통증", "피곤", "지치"]):
            return MemoryCategory.HEALTH_CONCERN
        
        if any(kw in text_lower for kw in ["관계", "사람", "친구", "가족", "남편", "아이"]):
            return MemoryCategory.RELATIONSHIP
        
        primary_emotion = emotion_result.get("primary_emotion", {}).get("code", "")
        if primary_emotion in ["anxiety", "fear", "worry"]:
            return MemoryCategory.ANXIETY_PATTERN
        
        if primary_emotion in ["sadness", "depression", "hopelessness"]:
            return MemoryCategory.MOOD_PATTERN
        
        return MemoryCategory.OTHER
    
    def add_memory(
        self,
        session_id: str,
        user_text: str,
        emotion_result: Dict[str, Any],
        memory_type: str = MemoryType.LONG_TERM_PATTERN,
        is_global: bool = False
    ) -> Optional[str]:
        """
        장기 기억 추가
        
        Args:
            session_id: 세션 ID
            user_text: 사용자 입력
            emotion_result: 감정 분석 결과
            memory_type: 기억 타입
            is_global: 전역 메모리 여부 (세션 간 공유)
            
        Returns:
            memory_id 또는 None
        """
        # 카테고리 분류
        category = self.categorize_concern(user_text, emotion_result)
        
        # 메모리 ID 생성
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        memory_id = f"mem_{category}_{timestamp}"
        
        # 요약 생성 (첫 50자)
        summary = user_text[:50] + "..." if len(user_text) > 50 else user_text
        
        # 관련 감정들
        related_emotions = [emotion_result.get("primary_emotion", {}).get("code", "")]
        related_emotions.extend([
            sec.get("code") 
            for sec in emotion_result.get("secondary_emotions", [])[:2]
        ])
        
        # 메모리 데이터 생성
        memory = {
            "memory_id": memory_id,
            "type": memory_type,
            "category": category,
            "summary": summary,
            "first_mentioned": datetime.now().isoformat(),
            "last_mentioned": datetime.now().isoformat(),
            "frequency": 1,
            "related_emotions": related_emotions,
            "session_ids": [session_id],
            "risk_level": emotion_result.get("service_signals", {}).get("risk_level", "low")
        }
        
        # 저장
        if is_global:
            self._global_memories[memory_id] = memory
        else:
            self._memories[session_id][memory_id] = memory
        
        # 파일에 저장
        self._save_to_file()
        
        print(f"[Memory Layer] 💾 새 기억 저장: {memory_id} ({category})")
        
        return memory_id
    
    def update_memory(
        self,
        memory_id: str,
        session_id: str,
        is_global: bool = False
    ) -> bool:
        """
        기존 기억 업데이트 (빈도 증가)
        
        Args:
            memory_id: 메모리 ID
            session_id: 세션 ID
            is_global: 전역 메모리 여부
            
        Returns:
            성공 여부
        """
        memory_store = self._global_memories if is_global else self._memories.get(session_id, {})
        
        if memory_id not in memory_store:
            return False
        
        memory = memory_store[memory_id]
        memory["frequency"] += 1
        memory["last_mentioned"] = datetime.now().isoformat()
        
        if session_id not in memory.get("session_ids", []):
            memory["session_ids"].append(session_id)
        
        self._save_to_file()
        
        print(f"[Memory Layer] 🔄 기억 업데이트: {memory_id} (빈도: {memory['frequency']})")
        
        return True
    
    def get_relevant_memories(
        self,
        session_id: str,
        category: Optional[str] = None,
        min_frequency: int = 1,
        include_global: bool = True
    ) -> List[Dict]:
        """
        관련 기억 조회
        
        Args:
            session_id: 세션 ID
            category: 카테고리 필터 (선택)
            min_frequency: 최소 빈도
            include_global: 전역 메모리 포함 여부
            
        Returns:
            기억 리스트 (빈도순 정렬)
        """
        memories = []
        
        # 세션별 메모리
        session_memories = self._memories.get(session_id, {}).values()
        memories.extend(session_memories)
        
        # 전역 메모리
        if include_global:
            memories.extend(self._global_memories.values())
        
        # 필터링
        if category:
            memories = [m for m in memories if m.get("category") == category]
        
        memories = [m for m in memories if m.get("frequency", 0) >= min_frequency]
        
        # 빈도순 정렬
        memories.sort(key=lambda x: x.get("frequency", 0), reverse=True)
        
        return memories
    
    def format_for_llm(self, memories: List[Dict]) -> str:
        """
        LLM 프롬프트용 포맷팅
        
        Args:
            memories: 기억 리스트
            
        Returns:
            포맷된 텍스트
        """
        if not memories:
            return ""
        
        lines = ["장기 기억 (반복 패턴 및 지속적 고민):"]
        
        for mem in memories[:5]:  # 최대 5개
            category_ko = {
                MemoryCategory.SLEEP_ISSUE: "수면 문제",
                MemoryCategory.HEALTH_CONCERN: "건강 고민",
                MemoryCategory.RELATIONSHIP: "인간관계",
                MemoryCategory.ANXIETY_PATTERN: "불안 패턴",
                MemoryCategory.MOOD_PATTERN: "기분 패턴",
                MemoryCategory.MENOPAUSE_SYMPTOM: "갱년기 증상",
            }.get(mem.get("category"), "기타")
            
            summary = mem.get("summary", "")
            frequency = mem.get("frequency", 1)
            
            lines.append(f"- [{category_ko}] {summary} (언급 횟수: {frequency}회)")
        
        return "\n".join(lines)
    
    def _save_to_file(self):
        """메모리를 파일로 저장"""
        try:
            # 세션별 메모리
            session_file = self.storage_path / "session_memories.json"
            with open(session_file, "w", encoding="utf-8") as f:
                json.dump(dict(self._memories), f, ensure_ascii=False, indent=2)
            
            # 전역 메모리
            global_file = self.storage_path / "global_memories.json"
            with open(global_file, "w", encoding="utf-8") as f:
                json.dump(self._global_memories, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"[Memory Layer] ⚠️ 파일 저장 실패: {e}")
    
    def _load_from_file(self):
        """파일에서 메모리 로드"""
        try:
            # 세션별 메모리
            session_file = self.storage_path / "session_memories.json"
            if session_file.exists():
                with open(session_file, "r", encoding="utf-8") as f:
                    loaded = json.load(f)
                    self._memories = defaultdict(dict, loaded)
            
            # 전역 메모리
            global_file = self.storage_path / "global_memories.json"
            if global_file.exists():
                with open(global_file, "r", encoding="utf-8") as f:
                    self._global_memories = json.load(f)
            
            print(f"[Memory Layer] 📂 메모리 로드 완료: "
                  f"세션 {len(self._memories)}개, 전역 {len(self._global_memories)}개")
        except Exception as e:
            print(f"[Memory Layer] ⚠️ 파일 로드 실패: {e}")


# 전역 인스턴스
_memory_layer = None


def get_memory_layer() -> MemoryLayer:
    """
    전역 Memory Layer 인스턴스 반환
    
    Returns:
        MemoryLayer 인스턴스
    """
    global _memory_layer
    if _memory_layer is None:
        _memory_layer = MemoryLayer()
    return _memory_layer


# 편의 함수들
def should_store_memory(user_text: str, emotion_result: Dict, session_history: List[Dict] = None) -> bool:
    """장기 기억 저장 여부 판단"""
    return get_memory_layer().should_store_in_memory(user_text, emotion_result, session_history)


def add_memory(session_id: str, user_text: str, emotion_result: Dict, is_global: bool = False) -> Optional[str]:
    """장기 기억 추가"""
    return get_memory_layer().add_memory(session_id, user_text, emotion_result, is_global=is_global)


def get_memories_for_prompt(session_id: str, category: Optional[str] = None) -> str:
    """LLM 프롬프트용 기억 조회"""
    memories = get_memory_layer().get_relevant_memories(session_id, category=category)
    return get_memory_layer().format_for_llm(memories)


if __name__ == "__main__":
    # 테스트
    print("=" * 80)
    print("Memory Layer 어댑터 테스트")
    print("=" * 80)
    
    # 감정 분석 결과 더미 데이터
    emotion_result = {
        "primary_emotion": {"code": "anxiety", "name_ko": "불안"},
        "secondary_emotions": [
            {"code": "confusion", "name_ko": "혼란"},
            {"code": "sadness", "name_ko": "슬픔"}
        ],
        "service_signals": {
            "risk_level": "watch"
        }
    }
    
    # 테스트 1: 메모리 저장 판단
    test_text_1 = "요즘 계속 잠을 못 자서 힘들어요"
    layer = get_memory_layer()
    
    should_store = layer.should_store_in_memory(test_text_1, emotion_result)
    print(f"\n[테스트 1] 저장 판단: {should_store}")
    print(f"입력: {test_text_1}")
    
    # 테스트 2: 메모리 추가
    if should_store:
        memory_id = layer.add_memory("test_session_1", test_text_1, emotion_result)
        print(f"\n[테스트 2] 메모리 추가 완료: {memory_id}")
    
    # 테스트 3: 메모리 조회
    memories = layer.get_relevant_memories("test_session_1")
    print(f"\n[테스트 3] 저장된 메모리: {len(memories)}개")
    for mem in memories:
        print(f"  - {mem['category']}: {mem['summary']} (빈도: {mem['frequency']})")
    
    # 테스트 4: LLM 프롬프트 포맷팅
    prompt_text = layer.format_for_llm(memories)
    print(f"\n[테스트 4] LLM 프롬프트 포맷:")
    print(prompt_text)
    
    print("\n" + "=" * 80)
    print("✅ 테스트 완료!")
    print("=" * 80)
