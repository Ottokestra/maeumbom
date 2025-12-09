"""
Response Generator for Phase 3 Voice Chat

Handles emotion parameter generation, response-type detection, 
and casual tone enforcement for the orchestrator.
"""
import re
import logging
from typing import Dict, List, Optional
from openai import OpenAI
import os

logger = logging.getLogger(__name__)


def generate_emotion_parameter(
    conversation_history: List[Dict[str, str]],
    llm_response: str,
    user_text: str
) -> str:
    """
    대화 컨텍스트와 LLM 응답을 분석하여 emotion 파라미터 생성
    
    Args:
        conversation_history: 대화 히스토리 (최근 3개 메시지)
        llm_response: LLM이 생성한 응답 텍스트
        user_text: 사용자 입력 텍스트
        
    Returns:
        emotion: "sadness", "happiness", "anger", "fear" 중 하나
    """
    try:
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        
        # 대화 히스토리 포맷팅
        history_text = ""
        for msg in conversation_history[-3:]:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            history_text += f"{role}: {content}\n"
        
        prompt = f"""다음 대화에서 AI 응답의 감정 톤을 분석하세요.

대화 히스토리:
{history_text}

사용자 입력: {user_text}
AI 응답: {llm_response}

AI 응답이 표현하는 공감의 감정을 다음 4가지 중 하나로 분류하세요:
- sadness: 슬픈 일에 대한 공감, 위로
- happiness: 기쁜 일에 대한 공감, 축하
- anger: 억울하거나 화나는 일에 대한 공감, 지지
- fear: 두려움, 무서움 등에 대한 공감, 안심

응답은 반드시 위 4가지 중 하나의 단어만 출력하세요 (소문자).
"""
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are an emotion analyzer. Respond with only one word from: sadness, happiness, anger, fear"},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=10
        )
        
        emotion = response.choices[0].message.content.strip().lower()
        
        # 유효성 검사
        valid_emotions = ["sadness", "happiness", "anger", "fear"]
        if emotion not in valid_emotions:
            logger.warning(f"Invalid emotion '{emotion}', defaulting to 'happiness'")
            emotion = "happiness"
        
        logger.info(f"✨ [Emotion] Generated: {emotion}")
        return emotion
        
    except Exception as e:
        logger.error(f"Failed to generate emotion parameter: {e}", exc_info=True)
        return "happiness"  # 기본값


def generate_response_type(llm_response: str) -> str:
    """
    LLM 응답을 분석하여 response-type 감지
    
    Args:
        llm_response: LLM이 생성한 응답 텍스트
        
    Returns:
        response_type: "list" 또는 "normal"
    """
    try:
        # 정규식: "1." 또는 "1)" 형태로 시작하는 라인 찾기
        # 최소 2개 이상의 번호 목록이 있어야 list로 판단
        pattern = r'^\s*\d+[\.\)]\s+'
        lines = llm_response.split('\n')
        
        numbered_lines = 0
        for line in lines:
            if re.match(pattern, line.strip()):
                numbered_lines += 1
        
        # 2개 이상의 번호 목록이 있으면 list type
        if numbered_lines >= 2:
            logger.info(f"📋 [Response Type] Detected: list (found {numbered_lines} numbered items)")
            return "list"
        else:
            logger.info(f"💬 [Response Type] Detected: normal")
            return "normal"
            
    except Exception as e:
        logger.error(f"Failed to detect response type: {e}", exc_info=True)
        return "normal"  # 기본값


def enforce_casual_tone_prompt(base_prompt: str) -> str:
    """
    시스템 프롬프트에 반말 톤 지시사항 추가
    
    Args:
        base_prompt: 기본 시스템 프롬프트
        
    Returns:
        updated_prompt: 반말 톤이 추가된 프롬프트
    """
    casual_instruction = """

**말투 스타일:**
- 친구와 대화하듯 편안한 반말을 사용하세요
- 존댓말 사용 금지 (예: "안녕하세요" ❌ → "안녕" ✅)
- 자연스럽고 친근한 톤으로 대화하세요
- 예시:
  - "오늘 어떠셨어요?" ❌
  - "오늘 어땠어?" ✅
"""
    
    return base_prompt + casual_instruction


def enforce_list_format_prompt(base_prompt: str) -> str:
    """
    리스트 응답 생성 시 "1. / 2. / 3." 형식 강제
    
    Args:
        base_prompt: 기본 시스템 프롬프트
        
    Returns:
        updated_prompt: 리스트 형식 지시사항이 추가된 프롬프트
    """
    list_instruction = """

**리스트 형식 규칙:**
- 여러 항목을 나열할 때는 반드시 "1. / 2. / 3." 형식을 사용하세요
- 각 항목은 새 줄에 작성하세요
- 예시:
  1. 첫 번째 항목
  2. 두 번째 항목
  3. 세 번째 항목
"""
    
    return base_prompt + list_instruction


def get_casual_tone_system_prompt() -> str:
    """
    반말 톤이 적용된 기본 시스템 프롬프트 반환
    
    Returns:
        system_prompt: 반말 톤 시스템 프롬프트
    """
    base_prompt = """당신은 갱년기 중년 여성을 돕는 AI 친구 '봄이'입니다.

역할:
- 친구처럼 편안하게 대화하며 공감하고 위로합니다
- 갱년기 증상과 일상의 어려움을 이해하고 도움을 줍니다
- 필요시 루틴, 운동, 명상 등을 추천합니다

대화 원칙:
- 따뜻하고 공감적인 태도
- 구체적이고 실용적인 조언
- 부정적 감정을 인정하고 존중"""

    return enforce_casual_tone_prompt(base_prompt)


# ============================================================================
# 통합 함수
# ============================================================================

def generate_response_metadata(
    conversation_history: List[Dict[str, str]],
    llm_response: str,
    user_text: str
) -> Dict[str, str]:
    """
    LLM 응답에 대한 메타데이터 생성 (emotion + response_type)
    
    Args:
        conversation_history: 대화 히스토리
        llm_response: LLM 응답 텍스트
        user_text: 사용자 입력
        
    Returns:
        metadata: {"emotion": "...", "response_type": "..."}
    """
    try:
        emotion = generate_emotion_parameter(
            conversation_history, llm_response, user_text
        )
        response_type = generate_response_type(llm_response)
        
        return {
            "emotion": emotion,
            "response_type": response_type
        }
    except Exception as e:
        logger.error(f"Failed to generate response metadata: {e}", exc_info=True)
        return {
            "emotion": "happiness",
            "response_type": "normal"
        }
