"""
Lightweight Emotion Classifier

Fast keyword-based classifier to determine if emotion analysis is needed.
Part of the hybrid approach: Classifier → Orchestrator LLM
Response time: ~1ms
"""
import re
from typing import Literal
import logging

logger = logging.getLogger(__name__)

class LightweightEmotionClassifier:
    """
    Rule-based emotion necessity classifier
    
    Returns:
        "필요": Clear emotional expression detected
        "불필요": Neutral question or greeting
        "애매": Uncertain, delegate to Orchestrator LLM
    """
    
    # Emotion keywords (high precision)
    EMOTION_KEYWORDS = {
        # Negative emotions
        "힘들", "우울", "slop", "불안", "화", "짜증", "스트레스",
        "아프", "피곤", "지쳐", "걱정", "두려", "무섭", "외로",
        "답답", "막막", "갑갑", "속상", "억울", "서러", "괴로",
        
        # Positive emotions  
        "기쁘", "행복", "좋아", "설레", "감사", "뿌듯", "즐거",
        "신나", "반가", "사랑",
        
        # Physical symptoms (often emotion-related)
        "잠 못", "두통", "어지러", "식욕 없", "가슴 답답"
    }
    
    # Neutral patterns (questions, requests, greetings)
    NEUTRAL_PATTERNS = [
        r"^(안녕|좋은|반가워|고마워|알겠어|네|응|ㅇㅇ)",  # Greetings
        r"(추천|알려|설명|방법|어떻게|뭐|무엇)",  # Questions
        r"(날씨|시간|일정|계획|루틴|음식|운동)",  # Information requests
        r"(해줘|해 줘|보여줘|알려줘)",  # Requests
    ]
    
    def predict(self, text: str) -> Literal["필요", "불필요", "애매"]:
        """
        Determine if emotion analysis is needed
        
        Args:
            text: User input text
            
        Returns:
            "필요": Emotion analysis needed (clear emotional expression)
            "불필요": Can skip analysis (neutral/informational)
            "애매": Uncertain, let Orchestrator decide
        """
        text = text.strip()
        
        # Too short → delegate
        if len(text) < 3:
            return "애매"
        
        # 1. Check neutral patterns first (fast rejection)
        for pattern in self.NEUTRAL_PATTERNS:
            if re.search(pattern, text):
                logger.debug(f"[Classifier] Neutral pattern matched: {pattern}")
                return "불필요"
        
        # 2. Check emotion keywords
        for keyword in self.EMOTION_KEYWORDS:
            if keyword in text:
                logger.debug(f"[Classifier] Emotion keyword found: {keyword}")
                return "필요"
        
        # 3. Question mark → likely informational
        if "?" in text or "뭐" in text or "뭘" in text or "어디" in text:
            return "불필요"
        
        # 4. Very short statements → ambiguous
        if len(text) < 10:
            return "애매"
        
        # 5. Default: defer to Orchestrator
        logger.debug("[Classifier] Uncertain, deferring to Orchestrator")
        return "애매"
    
    def batch_predict(self, texts: list[str]) -> list[str]:
        """Batch prediction for testing"""
        return [self.predict(text) for text in texts]


# Singleton instance
_classifier = None

def get_emotion_classifier() -> LightweightEmotionClassifier:
    """Get singleton classifier instance"""
    global _classifier
    if _classifier is None:
        _classifier = LightweightEmotionClassifier()
    return _classifier
