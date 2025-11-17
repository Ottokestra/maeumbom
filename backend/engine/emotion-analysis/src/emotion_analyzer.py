"""
Emotion analysis model using OpenAI GPT-4o mini
"""
import sys
from pathlib import Path
from openai import OpenAI
from typing import Dict, List
import re
import json

# 경로 설정 및 import
src_path = Path(__file__).parent
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

import importlib.util

# config import
config_path = src_path / "config.py"
spec = importlib.util.spec_from_file_location("config", config_path)
config_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config_module)
EMOTIONS = config_module.EMOTIONS
LLM_MODEL = config_module.LLM_MODEL
OPENAI_API_KEY = config_module.OPENAI_API_KEY


class EmotionAnalyzer:
    """Analyze emotions using OpenAI GPT-4o mini"""
    
    def __init__(self, model_name: str = LLM_MODEL):
        """
        Initialize emotion analyzer with OpenAI API
        
        Args:
            model_name: Name of the OpenAI model (default: gpt-4o-mini)
        """
        print(f"Initializing OpenAI client with model: {model_name}")
        
        # Initialize OpenAI client
        self.client = OpenAI(api_key=OPENAI_API_KEY)
        self.model_name = model_name
        
        # Emotion categories
        self.emotions = EMOTIONS
        self.num_emotions = len(EMOTIONS)
        
        print(f"OpenAI client initialized successfully with {self.num_emotions} emotion categories")
    
    def _create_prompt(self, text: str, context_texts: list = None) -> str:
        """
        Create prompt for LLM
        
        Args:
            text: Input text to analyze
            context_texts: Optional list of similar context texts
            
        Returns:
            Formatted prompt string
        """
        # Emotion descriptions in Korean
        emotion_desc = {
            "joy": "기쁨 (즐거움, 만족, 행복)",
            "calmness": "평온 (안정감, 안도감)",
            "sadness": "슬픔 (우울, 상실감)",
            "anger": "분노 (화남, 짜증, 혐오)",
            "anxiety": "불안 (걱정, 두려움)",
            "loneliness": "외로움 (고립감, 그리움)",
            "fatigue": "피로 (지침, 무기력)",
            "confusion": "혼란 (당황, 어색함)",
            "guilt": "죄책감 (미안함, 자책감)",
            "frustration": "좌절 (무력감, 답답함)"
        }
        
        prompt = f"""당신은 갱년기 여성의 감정을 분석하는 전문가입니다.

다음 텍스트에서 감지되는 감정을 분석하고, 각 감정의 강도를 1-5점으로 평가하세요.

텍스트: "{text}"
"""
        
        # Add context if available
        if context_texts and len(context_texts) > 0:
            prompt += "\n참고 - 유사한 감정 표현:\n"
            for i, ctx in enumerate(context_texts[:3], 1):
                if isinstance(ctx, dict):
                    prompt += f"{i}. \"{ctx.get('text', '')}\" (감정: {ctx.get('emotion', '')}, 강도: {ctx.get('intensity', 0)})\n"
        
        prompt += f"""
감정 카테고리 (각 1-5점으로 평가):
"""
        for emotion, desc in emotion_desc.items():
            prompt += f"- {emotion}: {desc}\n"
        
        prompt += """
중요한 지침:
1. 텍스트에서 가장 강하게 느껴지는 상위 3개 감정만 선택하세요.
2. 3개 감정의 비율을 퍼센트로 표현하되, 합계가 반드시 100이 되어야 합니다.
3. 가장 강한 감정부터 순서대로 나열하세요.
4. 다른 설명 없이 JSON만 출력하세요.

예시:
입력: "가족들에게 자꾸 화를 내요"
출력:
{"top_emotions": [{"emotion": "anger", "percentage": 60}, {"emotion": "guilt", "percentage": 30}, {"emotion": "frustration", "percentage": 10}]}

입력: "정말 기분이 좋아요"
출력:
{"top_emotions": [{"emotion": "joy", "percentage": 90}, {"emotion": "calmness", "percentage": 8}, {"emotion": "anxiety", "percentage": 2}]}

입력: "요즘 너무 피곤해요"
출력:
{"top_emotions": [{"emotion": "fatigue", "percentage": 75}, {"emotion": "sadness", "percentage": 15}, {"emotion": "frustration", "percentage": 10}]}

이제 다음 텍스트를 분석하세요. JSON만 출력하세요:
"""
        
        return prompt
    
    def _parse_llm_response(self, response: str) -> Dict[str, int]:
        """
        Parse LLM response to extract top 3 emotions with percentages
        
        Args:
            response: LLM generated text
            
        Returns:
            Dictionary mapping emotion to percentage (top 3 only, others 0)
        """
        # Initialize all emotions to 0
        emotion_scores = {emotion: 0 for emotion in self.emotions}
        
        # Try to find JSON with top_emotions
        json_patterns = [
            r'\{["\']?top_emotions["\']?\s*:\s*\[[^\]]+\]\s*\}',  # Full JSON with array
            r'\{[\s\S]*?top_emotions[\s\S]*?\}',  # Flexible match
        ]
        
        for pattern in json_patterns:
            json_match = re.search(pattern, response, re.DOTALL)
            if json_match:
                try:
                    json_str = json_match.group(0)
                    data = json.loads(json_str)
                    
                    # Extract top emotions
                    if 'top_emotions' in data and isinstance(data['top_emotions'], list):
                        for item in data['top_emotions'][:3]:  # Only top 3
                            if isinstance(item, dict):
                                emotion = item.get('emotion', '')
                                percentage = item.get('percentage', 0)
                                if emotion in self.emotions:
                                    emotion_scores[emotion] = int(percentage)
                        
                        # If we got valid data, return it
                        if sum(emotion_scores.values()) > 0:
                            return emotion_scores
                except (json.JSONDecodeError, KeyError, TypeError, ValueError) as e:
                    print(f"JSON parsing failed: {e}")
                    continue
        
        # Fallback: Manual parsing
        print("Using fallback parsing...")
        found_emotions = []
        
        # Look for patterns like: "emotion": "anger", "percentage": 60
        emotion_pattern = r'["\']?emotion["\']?\s*:\s*["\'](\w+)["\']'
        percentage_pattern = r'["\']?percentage["\']?\s*:\s*(\d+)'
        
        emotion_matches = re.findall(emotion_pattern, response)
        percentage_matches = re.findall(percentage_pattern, response)
        
        for emotion, percentage in zip(emotion_matches, percentage_matches):
            if emotion in self.emotions:
                found_emotions.append((emotion, int(percentage)))
        
        # Sort by percentage and take top 3
        found_emotions.sort(key=lambda x: x[1], reverse=True)
        for emotion, percentage in found_emotions[:3]:
            emotion_scores[emotion] = percentage
        
        # If still no emotions found, use keyword-based fallback
        if sum(emotion_scores.values()) == 0:
            print("Using keyword-based fallback...")
            # Analyze the original text (stored in prompt)
            text_lower = response.lower()
            
            # Simple keyword matching
            if any(word in text_lower for word in ['기쁨', '좋', '행복', 'joy', 'happy']):
                emotion_scores['joy'] = 85
                emotion_scores['calmness'] = 10
                emotion_scores['anxiety'] = 5  # 약간의 설렘/긴장
            elif any(word in text_lower for word in ['화', '짜증', '분노', 'anger']):
                emotion_scores['anger'] = 70
                emotion_scores['frustration'] = 20
                emotion_scores['guilt'] = 10
            elif any(word in text_lower for word in ['피곤', '지침', 'fatigue', 'tired']):
                emotion_scores['fatigue'] = 75
                emotion_scores['sadness'] = 15
                emotion_scores['frustration'] = 10
            elif any(word in text_lower for word in ['슬', '우울', 'sad']):
                emotion_scores['sadness'] = 70
                emotion_scores['loneliness'] = 20
                emotion_scores['fatigue'] = 10
            else:
                emotion_scores['confusion'] = 60
                emotion_scores['anxiety'] = 25
                emotion_scores['sadness'] = 15
        
        return emotion_scores
    
    def analyze(self, text: str, context_texts: list = None) -> Dict[str, any]:
        """
        Analyze emotions using OpenAI API
        
        Args:
            text: Input text to analyze
            context_texts: Optional list of similar context texts
            
        Returns:
            Dictionary with emotion scores and primary emotion
        """
        # Create prompt
        prompt = self._create_prompt(text, context_texts)
        
        # Call OpenAI API
        try:
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {
                        "role": "system",
                        "content": "당신은 감정 분석 전문가입니다. 주어진 텍스트를 분석하여 JSON 형식으로만 응답하세요."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.1,  # 낮은 온도로 일관된 응답
                max_tokens=200,  # JSON 응답에 충분한 토큰
                response_format={"type": "json_object"}  # JSON 형식 강제 (gpt-4o-mini는 지원하지 않을 수 있음)
            )
            
            # Extract response text
            generated_text = response.choices[0].message.content.strip()
            
            print(f"\n=== OpenAI API Response ===")
            print(generated_text)
            print("=" * 50)
            
        except Exception as e:
            # response_format이 지원되지 않는 경우 재시도
            if "response_format" in str(e).lower():
                print("JSON mode not supported, retrying without response_format...")
                response = self.client.chat.completions.create(
                    model=self.model_name,
                    messages=[
                        {
                            "role": "system",
                            "content": "당신은 감정 분석 전문가입니다. 주어진 텍스트를 분석하여 JSON 형식으로만 응답하세요."
                        },
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    temperature=0.1,
                    max_tokens=200
                )
                generated_text = response.choices[0].message.content.strip()
                
                print(f"\n=== OpenAI API Response ===")
                print(generated_text)
                print("=" * 50)
            else:
                raise e
        
        # Parse emotion scores (percentages)
        emotion_scores = self._parse_llm_response(generated_text)
        
        # Find primary emotion (highest percentage)
        primary_emotion = max(emotion_scores.items(), key=lambda x: x[1])
        
        # Get top 3 emotions only (non-zero)
        top_3_emotions = {
            emotion: score 
            for emotion, score in sorted(
                emotion_scores.items(), 
                key=lambda x: x[1], 
                reverse=True
            )[:3]
            if score > 0
        }
        
        return {
            "emotions": top_3_emotions,  # Only top 3
            "all_emotions": emotion_scores,  # All 10 for compatibility
            "primary_emotion": primary_emotion[0],
            "primary_percentage": primary_emotion[1]
        }


# Global instance
_emotion_analyzer = None


def get_emotion_analyzer() -> EmotionAnalyzer:
    """
    Get or create the global emotion analyzer instance
    
    Returns:
        EmotionAnalyzer instance
    """
    global _emotion_analyzer
    if _emotion_analyzer is None:
        _emotion_analyzer = EmotionAnalyzer()
    return _emotion_analyzer
