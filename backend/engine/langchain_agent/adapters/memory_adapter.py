"""
LangChain Agent용 Memory Layer 어댑터 (V2 - DB Schema Fixed + Promotion Logic)

장기 기억을 저장하고 관리하는 시스템
- 반복되는 감정 패턴 (빈도 기반 승격)
- 장기 고민 사항 (수면, 건강, 인간관계 등)
- 사용자 선호도
- 위험 수준 기반 자동 저장
- 명시적 기억 요청/삭제 처리
"""
import json
import os
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
from collections import defaultdict
import re

from app.db.database import SessionLocal
from app.db.models import GlobalMemory, Conversation
from sqlalchemy import and_, or_, func


class MemoryCategory:
    """장기 기억 카테고리"""
    SLEEP_ISSUE = "sleep_issue"
    HEALTH_CONCERN = "health_concern"
    RELATIONSHIP = "relationship"
    ANXIETY_PATTERN = "anxiety_pattern"
    MOOD_PATTERN = "mood_pattern"
    MENOPAUSE_SYMPTOM = "menopause_symptom"
    PERSONAL_PREFERENCE = "personal_preference"
    ALLERGY = "allergy"  # 알러지 정보 (높은 중요도)
    OTHER = "other"


class MemoryType:
    """기억 타입"""
    LONG_TERM_PATTERN = "long_term_pattern"  # 반복되는 패턴
    PERSISTENT_CONCERN = "persistent_concern"  # 지속적 고민
    USER_PREFERENCE = "user_preference"  # 사용자 선호
    CRITICAL_INFO = "critical_info"  # 중요 정보 (알러지 등)


# 명시적 기억 요청 키워드
MEMORY_STORE_KEYWORDS = [
    "기억해", "꼭 기억해", "기억해줘", "꼭 기억해줘",
    "잊지마", "잊지 마", "잊지말아줘", "잊지 말아줘",
    "알아둬", "알아두세요", "명심해", "명심하세요",
    "저장해", "저장해줘", "메모해", "메모해줘"
]

# 명시적 기억 삭제 키워드
MEMORY_DELETE_KEYWORDS = [
    "잊어버려", "잊어줘", "잊어버리세요", 
    "지워", "지워줘", "삭제해", "삭제해줘",
    "기억 안해도 돼", "기억 안 해도 돼", "기억하지마", "기억하지 마",
    "그건 무시해", "그건 무시하세요", "신경쓰지마", "신경쓰지 마"
]


class MemoryLayer:
    """
    장기 기억 저장 및 조회 시스템 (DB 기반 V2)
    
    저장 조건:
    - 위험 수준이 'watch' 이상
    - 사용자가 명시적으로 언급한 장기 고민
    - 명시적 기억 요청 (즉시 Global로 승격)
    """
    
    def __init__(self):
        """초기화"""
        # 감정 강도 승격 설정
        self.emotion_polarity_threshold = -0.7  # 이 값보다 낮으면 (부정적)
        self.risk_levels_for_promotion = ["watch", "alert", "critical"]
    
    def _get_db(self):
        return SessionLocal()
    
    def detect_explicit_memory_request(self, text: str) -> bool:
        """명시적 기억 요청 감지"""
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in MEMORY_STORE_KEYWORDS)
    
    def detect_explicit_memory_deletion(self, text: str) -> Optional[str]:
        """
        명시적 기억 삭제 요청 감지
        
        Returns:
            삭제할 주제/키워드 (예: "오이", "김치찌개") 또는 None
        """
        text_lower = text.lower()
        
        # 삭제 키워드가 있는지 확인
        has_delete_keyword = any(keyword in text_lower for keyword in MEMORY_DELETE_KEYWORDS)
        if not has_delete_keyword:
            return None
        
        # 간단한 패턴 매칭으로 삭제 대상 추출
        patterns = [
            r"(\S+)(?:는|은|이|가|을|를)?\s*(?:잊어|지워|삭제)",
            r"(\S+)\s+기억\s*(?:안|하지)",
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                return match.group(1).strip()
        
        return "general"  # 구체적 대상 없이 일반 삭제 요청
    
    def should_store_in_memory(
        self, 
        user_text: str,
        emotion_result: Dict[str, Any],
        session_history: List[Dict] = None
    ) -> bool:
        """
        세션 기억 저장 여부 판단 (Legacy - Not used in new flow)
        """
        # 1. 위험 수준 체크
        risk_level = emotion_result.get("service_signals", {}).get("risk_level", "low")
        if risk_level in self.risk_levels_for_promotion:
            return True
        
        # 2. 반복 키워드 체크
        repeat_keywords = ["계속", "반복", "매번", "항상", "요즘", "최근", "자꾸", "또", "다시"]
        if any(keyword in user_text for keyword in repeat_keywords):
            return True
        
        # 3. 장기 고민 키워드 체크
        concern_keywords = [
            "잠", "수면", "불면", "건강", "관계", "스트레스", 
            "남편", "자식", "직장", "돈", "미래", "우울", "불안",
            "알러지", "알레르기", "좋아", "싫어", "취미"
        ]
        if any(keyword in user_text for keyword in concern_keywords):
            return True
        
        # 4. 명시적 요청
        if self.detect_explicit_memory_request(user_text):
            return True
            
        return False
    
    def check_promotion_rules(
        self,
        user_id: int,
        session_id: str,
        category: str,
        emotion_result: Dict[str, Any],
        user_text: str
    ) -> Tuple[bool, str, int]:
        """
        승격 규칙 체크
        """
        db = self._get_db()
        try:
            # 규칙 1: 명시적 요청 (최우선)
            if self.detect_explicit_memory_request(user_text):
                return (True, "explicit_request", 10)
            
            # 규칙 2: 감정 강도
            polarity = emotion_result.get("polarity", 0.0)
            risk_level = emotion_result.get("service_signals", {}).get("risk_level", "low")
            
            if polarity < self.emotion_polarity_threshold or risk_level in self.risk_levels_for_promotion:
                importance = 8 if risk_level in ["alert", "critical"] else 6
                return (True, f"high_emotion_intensity (polarity={polarity}, risk={risk_level})", importance)
            
            return (False, "no_promotion_criteria_met", 1)
            
        finally:
            db.close()
    
    def promote_memory(
        self,
        user_id: int,
        session_id: str,
        category: str,
        content: str,
        emotion_result: Dict[str, Any],
        importance: int,
        reason: str
    ) -> bool:
        """
        세션 메모리를 전역 메모리로 승격
        """
        db = self._get_db()
        try:
            # 항상 새 Global Memory 생성 (누적 저장)
            new_global = GlobalMemory(
                USER_ID=user_id,
                CATEGORY=category,
                MEMORY_TEXT=content,
                IMPORTANCE=importance,
                SOURCE_SESSION_ID=session_id,
                CREATED_BY=user_id
            )
            db.add(new_global)
            print(f"[MemoryLayer] ✅ Memory promoted to Global: {category} (reason: {reason}, importance: {importance})")
            
            db.commit()
            return True
            
        except Exception as e:
            print(f"[MemoryLayer] ⚠️ Promotion failed: {e}")
            db.rollback()
            return False
        finally:
            db.close()
    
    def delete_memory(
        self,
        user_id: int,
        subject: str
    ) -> int:
        """
        특정 주제의 기억 삭제 (Soft Delete)
        """
        db = self._get_db()
        try:
            deleted_count = 0
            
            # Global Memory에서 검색 및 삭제
            global_mems = db.query(GlobalMemory).filter(
                and_(
                    GlobalMemory.USER_ID == user_id,
                    GlobalMemory.IS_DELETED == 'N',
                    or_(
                        GlobalMemory.MEMORY_TEXT.contains(subject),
                        GlobalMemory.CATEGORY.contains(subject)
                    )
                )
            ).all()
            
            for mem in global_mems:
                mem.IS_DELETED = 'Y'
                mem.UPDATED_BY = user_id
                mem.UPDATED_AT = datetime.now()
                deleted_count += 1
            
            db.commit()
            print(f"[MemoryLayer] 🗑️ Deleted {deleted_count} memories about '{subject}'")
            return deleted_count
            
        except Exception as e:
            print(f"[MemoryLayer] ⚠️ Memory deletion failed: {e}")
            db.rollback()
            return 0
        finally:
            db.close()
    
    def add_memory(
        self, 
        content: str, 
        emotion_result: Dict[str, Any],
        session_id: str,
        user_id: int
    ) -> Dict[str, Any]:
        """
        기억 저장 (DB) - V2 with Promotion Logic
        (Legacy: Direct add_memory call, mostly replaced by Agent V2 logic)
        """
        # 1. 삭제 요청 먼저 확인
        delete_subject = self.detect_explicit_memory_deletion(content)
        if delete_subject:
            deleted_count = self.delete_memory(user_id, delete_subject)
            return {
                "action": "delete",
                "subject": delete_subject,
                "deleted_count": deleted_count
            }
        
        # 2. 카테고리 분류
        category = self._classify_category(content, emotion_result)
        memory_type = self._determine_memory_type(content, emotion_result)
        
        # 3. 승격 규칙 체크
        should_promote, reason, importance = self.check_promotion_rules(
            user_id, session_id, category, emotion_result, content
        )
        
        # 4. 승격 처리 (Global Memory Only)
        if should_promote:
            self.promote_memory(
                user_id, session_id, category, content, emotion_result, importance, reason
            )
        
        return {
            "action": "store",
            "category": category,
            "memory_type": memory_type,
            "promoted": should_promote,
            "promotion_reason": reason if should_promote else None,
            "importance": importance if should_promote else None
        }

    def get_memories_for_prompt(self, session_id: str, user_id: int) -> str:
        """
        프롬프트 주입용 메모리 문자열 생성 (DB 조회)
        시간 정보 포함: 언제 저장된 기억인지 표시
        """
        from datetime import datetime
        
        db = self._get_db()
        try:
            memories = []
            
            # 1. Global Memories (전역 기억) - 중요도 순 정렬
            global_mems = db.query(GlobalMemory).filter(
                and_(
                    GlobalMemory.USER_ID == user_id,
                    GlobalMemory.IS_DELETED == 'N'
                )
            ).order_by(GlobalMemory.IMPORTANCE.desc()).all()
            
            if global_mems:
                memories.append("=== 사용자 장기 기억 (중요 정보) ===")
                for mem in global_mems:
                    importance_marker = "⭐" * min(mem.IMPORTANCE // 2, 5)  # 중요도 시각화
                    
                    # 🆕 시간 정보 추가
                    time_context = self._format_time_context(mem.CREATED_AT)
                    
                    memories.append(
                        f"{importance_marker} [{mem.CATEGORY}] {mem.MEMORY_TEXT} {time_context}"
                    )
            
            return "\n".join(memories)
        finally:
            db.close()
    
    def _format_time_context(self, created_at) -> str:
        """
        생성 시간을 사람이 읽기 쉬운 형식으로 변환
        
        Returns:
            "(오늘)", "(어제)", "(3일 전)", "(2주 전)", "(3개월 전)" 형식
        """
        from datetime import datetime
        
        now = datetime.now()
        delta = now - created_at
        days_ago = delta.days
        
        if days_ago == 0:
            # 오늘
            hours_ago = delta.seconds // 3600
            if hours_ago == 0:
                return "(방금)"
            elif hours_ago < 3:
                return f"({hours_ago}시간 전)"
            else:
                return "(오늘)"
        elif days_ago == 1:
            return "(어제)"
        elif days_ago < 7:
            return f"({days_ago}일 전)"
        elif days_ago < 30:
            weeks = days_ago // 7
            return f"({weeks}주 전)"
        elif days_ago < 365:
            months = days_ago // 30
            return f"({months}개월 전)"
        else:
            years = days_ago // 365
            return f"({years}년 전)"
    
    def _classify_category(self, content: str, emotion_result: Dict) -> str:
        """내용 기반 카테고리 분류"""
        # 알러지는 최우선 분류
        if any(w in content for w in ["알러지", "알레르기", "알러지가", "알레르기가"]):
            return MemoryCategory.ALLERGY
        
        if any(w in content for w in ["잠", "수면", "불면"]):
            return MemoryCategory.SLEEP_ISSUE
        if any(w in content for w in ["건강", "아파", "통증", "약"]):
            return MemoryCategory.HEALTH_CONCERN
        if any(w in content for w in ["남편", "자식", "친구", "사람", "가족"]):
            return MemoryCategory.RELATIONSHIP
        if any(w in content for w in ["좋아", "싫어", "취미", "즐겨"]):
            return MemoryCategory.PERSONAL_PREFERENCE
        
        # 감정 기반
        emotion = emotion_result.get("emotion", "")
        if emotion in ["anxiety", "fear"]:
            return MemoryCategory.ANXIETY_PATTERN
        if emotion in ["sadness", "depression"]:
            return MemoryCategory.MOOD_PATTERN
            
        return MemoryCategory.OTHER
        
    def _determine_memory_type(self, content: str, emotion_result: Dict) -> str:
        """기억 타입 결정"""
        # 명시적 요청은 중요 정보
        if self.detect_explicit_memory_request(content):
            return MemoryType.CRITICAL_INFO
        
        risk_level = emotion_result.get("service_signals", {}).get("risk_level", "low")
        
        if risk_level in ["watch", "alert", "critical"]:
            return MemoryType.PERSISTENT_CONCERN
        
        if any(w in content for w in ["매번", "항상", "자꾸", "계속"]):
            return MemoryType.LONG_TERM_PATTERN
            
        return MemoryType.USER_PREFERENCE


# ============================================================================
# Standalone Functions for Backward Compatibility
# ============================================================================

_memory_layer = MemoryLayer()

def should_store_memory(user_text: str, emotion_result: Dict[str, Any], session_history: List[Dict] = None) -> bool:
    return _memory_layer.should_store_in_memory(user_text, emotion_result, session_history)

def add_memory(content: str, emotion_result: Dict[str, Any], session_id: str, user_id: int) -> Dict[str, Any]:
    return _memory_layer.add_memory(content, emotion_result, session_id, user_id)

def get_memories_for_prompt(session_id: str, user_id: int) -> str:
    return _memory_layer.get_memories_for_prompt(session_id, user_id)

def promote_memory(
    user_id: int,
    session_id: str,
    category: str,
    content: str,
    emotion_result: Dict[str, Any],
    importance: int,
    reason: str
) -> bool:
    return _memory_layer.promote_memory(
        user_id, session_id, category, content, emotion_result, importance, reason
    )

def delete_memory(user_id: int, subject: str) -> int:
    return _memory_layer.delete_memory(user_id, subject)    
    def _classify_category(self, content: str, emotion_result: Dict) -> str:
        """내용 기반 카테고리 분류"""
        # 알러지는 최우선 분류
        if any(w in content for w in ["알러지", "알레르기", "알러지가", "알레르기가"]):
            return MemoryCategory.ALLERGY
        
        if any(w in content for w in ["잠", "수면", "불면"]):
            return MemoryCategory.SLEEP_ISSUE
        if any(w in content for w in ["건강", "아파", "통증", "약"]):
            return MemoryCategory.HEALTH_CONCERN
        if any(w in content for w in ["남편", "자식", "친구", "사람", "가족"]):
            return MemoryCategory.RELATIONSHIP
        if any(w in content for w in ["좋아", "싫어", "취미", "즐겨"]):
            return MemoryCategory.PERSONAL_PREFERENCE
        
        # 감정 기반
        emotion = emotion_result.get("emotion", "")
        if emotion in ["anxiety", "fear"]:
            return MemoryCategory.ANXIETY_PATTERN
        if emotion in ["sadness", "depression"]:
            return MemoryCategory.MOOD_PATTERN
            
        return MemoryCategory.OTHER
        
    def _determine_memory_type(self, content: str, emotion_result: Dict) -> str:
        """기억 타입 결정"""
        # 명시적 요청은 중요 정보
        if self.detect_explicit_memory_request(content):
            return MemoryType.CRITICAL_INFO
        
        risk_level = emotion_result.get("service_signals", {}).get("risk_level", "low")
        
        if risk_level in ["watch", "alert", "critical"]:
            return MemoryType.PERSISTENT_CONCERN
        
        if any(w in content for w in ["매번", "항상", "자꾸", "계속"]):
            return MemoryType.LONG_TERM_PATTERN
            
        return MemoryType.USER_PREFERENCE


# ============================================================================
# Standalone Functions for Backward Compatibility
# ============================================================================

_memory_layer = MemoryLayer()

def should_store_memory(user_text: str, emotion_result: Dict[str, Any], session_history: List[Dict] = None) -> bool:
    return _memory_layer.should_store_in_memory(user_text, emotion_result, session_history)

def add_memory(content: str, emotion_result: Dict[str, Any], session_id: str, user_id: int) -> Dict[str, Any]:
    return _memory_layer.add_memory(content, emotion_result, session_id, user_id)

def get_memories_for_prompt(session_id: str, user_id: int) -> str:
    return _memory_layer.get_memories_for_prompt(session_id, user_id)

def promote_memory(
    user_id: int,
    session_id: str,
    category: str,
    content: str,
    emotion_result: Dict[str, Any],
    importance: int,
    reason: str
) -> bool:
    return _memory_layer.promote_memory(
        user_id, session_id, category, content, emotion_result, importance, reason
    )

def delete_memory(user_id: int, subject: str) -> int:
    return _memory_layer.delete_memory(user_id, subject)
