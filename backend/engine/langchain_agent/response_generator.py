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


def remove_audio_tags(text: str) -> str:
    """
    Eleven Labs v3 audio tag 제거 (프론트엔드 표시용 원본 텍스트 생성)
    
    Args:
        text: audio tag가 포함된 텍스트
        
    Returns:
        audio tag가 제거된 원본 텍스트
        
    Examples:
        "[excited] 안녕!" -> "안녕!"
        "오늘 [sighs] 피곤해" -> "오늘 피곤해"
        "[whispers] 비밀인데... [pauses] 말해줄까?" -> "비밀인데... 말해줄까?"
    """
    # 대괄호로 감싸진 태그를 모두 제거 (예: [excited], [sighs], [whispers])
    # 패턴: [로 시작하여 ]로 끝나는 단어들
    cleaned_text = re.sub(r'\[[\w\s]+\]\s*', '', text)
    
    # 🆕 줄바꿈은 보존하고, 연속된 공백만 하나로 정리
    # 줄바꿈이 아닌 공백만 정리 (탭, 스페이스 등)
    cleaned_text = re.sub(r'[^\S\n]+', ' ', cleaned_text)  # \S = 공백 아닌 문자, [^\S\n] = 줄바꿈 제외한 공백
    
    return cleaned_text.strip()


def clean_text_for_tts(text: str) -> str:
    """
    TTS 음성 출력용 텍스트 정리 (마크다운 기호 제거, 줄바꿈 처리)
    
    Args:
        text: 마크다운과 줄바꿈이 포함된 텍스트
        
    Returns:
        TTS에 적합하게 정리된 텍스트 (audio tags는 유지)
        
    Examples:
        "오늘은 **휴식**이 필요해" -> "오늘은 휴식이 필요해"
        "충분히 쉬어.\n내가 옆에 있을게." -> "충분히 쉬어. 내가 옆에 있을게."
        "`가벼운 스트레칭`만 해봐" -> "가벼운 스트레칭만 해봐"
    """
    # 1. 마크다운 기호 제거
    # **볼드** 또는 __볼드__ -> 볼드
    cleaned = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
    cleaned = re.sub(r'__(.+?)__', r'\1', cleaned)
    
    # `코드` 또는 ``코드`` -> 코드
    cleaned = re.sub(r'`+(.+?)`+', r'\1', cleaned)
    
    # # 헤더 기호 제거
    cleaned = re.sub(r'^#+\s+', '', cleaned, flags=re.MULTILINE)
    
    # - 리스트 기호 제거 (줄 시작 부분만)
    cleaned = re.sub(r'^\s*[-*]\s+', '', cleaned, flags=re.MULTILINE)
    
    # 2. 줄바꿈 처리
    # 두 개 이상의 줄바꿈 -> 마침표 + 공백 (문단 구분)
    cleaned = re.sub(r'\n\n+', '. ', cleaned)
    
    # 단일 줄바꿈 -> 공백 (자연스러운 읽기)
    cleaned = re.sub(r'\n', ' ', cleaned)
    
    # 3. 여러 공백을 하나로 정리
    cleaned = re.sub(r'\s+', ' ', cleaned).strip()
    
    return cleaned



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
        # 🆕 Method 1: LLM이 명시한 TYPE 태그 체크 (우선순위 1)
        type_match = re.search(r'\[TYPE:(list|normal)\]', llm_response, re.IGNORECASE)
        if type_match:
            detected_type = type_match.group(1).lower()
            logger.info(f"📋 [Response Type] Detected from [TYPE] tag: {detected_type}")
            return detected_type
        
        # Method 2: 정규식 fallback (기존 방식)
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
            logger.info(f"📋 [Response Type] Detected from regex: list (found {numbered_lines} numbered items)")
            return "list"
        else:
            logger.info(f"💬 [Response Type] Detected: normal (no list pattern found)")
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


# ============================================================================
# Alarm Request Parsing
# ============================================================================

def parse_alarm_request(
    user_text: str,
    llm_response: str,
    current_datetime
) -> Dict:
    """
    사용자 요청에서 알람 정보를 파싱
    
    Args:
        user_text: 사용자 입력 텍스트
        llm_response: LLM 응답 텍스트
        current_datetime: 현재 시간 (datetime 객체)
        
    Returns:
        {
            "response_type": "alarm" | None,
            "count": int,
            "data": [...]
        }
    """
    print("=" * 80)
    print("🚨 [ALARM PARSER] FUNCTION CALLED!")
    print(f"User text: {user_text}")
    print(f"LLM response: {llm_response}")
    print("=" * 80)
    
    try:
        import json
        import random
        from datetime import datetime
        
        print("[ALARM PARSER] Step 1: Imports successful")
        
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        
        print("[ALARM PARSER] Step 2: OpenAI client created")
        
        # 현재 시간 정보
        current_str = current_datetime.strftime("%Y년 %m월 %d일 %H시 %M분 %A")
        weekday_map = {
            'Monday': '월요일',
            'Tuesday': '화요일',
            'Wednesday': '수요일',
            'Thursday': '목요일',
            'Friday': '금요일',
            'Saturday': '토요일',
            'Sunday': '일요일'
        }
        current_weekday_kr = weekday_map.get(current_datetime.strftime('%A'), '알 수 없음')
        
        print(f"[ALARM PARSER] Step 3: Current time formatted: {current_str}")
        
        # 🆕 Pre-filter: 알람 관련 키워드가 없으면 조기 반환
        alarm_keywords = ["알람", "알림", "기상", "깨워", "시간", "시", "분", "am", "pm", "오전", "오후"]
        user_and_response = (user_text + " " + llm_response).lower()
        
        has_alarm_keyword = any(keyword in user_and_response for keyword in alarm_keywords)
        
        if not has_alarm_keyword:
            print("[ALARM PARSER] Step 3.5: No alarm keywords found, skipping LLM call")
            return {
                "response_type": None,
                "count": 0,
                "data": []
            }
        
        print("[ALARM PARSER] Step 3.5: Alarm keywords detected, proceeding with LLM parsing")
        
        # LLM을 이용한 알람 파싱
        prompt = f"""현재 시간: {current_str} ({current_weekday_kr})

사용자 요청: "{user_text}"
AI 응답: "{llm_response}"

이 요청이 알람 설정 요청인지 판단하고, 맞다면 시간 정보를 추출하세요.

**중요 규칙 (반드시 준수!):**
1. **알람 설정 요청이 아니면 반드시 {{"is_alarm": false}} 반환**
2. **시간 정보가 명확하지 않으면 {{"is_alarm": false}} 반환**
3. time, minute, am_pm 필드는 **절대 null 불가** - 반드시 숫자/문자열로 제공
4. minute이 언급 안 되면 무조건 0
5. 여러 알람의 경우 각각 완전한 정보 (time, minute, am_pm 모두 필수)
6. am_pm 추론: 5시/6시/7시 → 문맥상 오후로 판단
7. **name 필드:** 사용자가 알람 용도를 명시했으면 10글자 이내로 요약, 없으면 null

**반환 형식:**
{{
  "is_alarm": true,
  "alarms": [
    {{
      "year": 2025,
      "month": 12,
      "week": ["Monday"],
      "day": 10,
      "time": 2,        // 반드시 숫자 (1-12), null 금지
      "minute": 30,     // 반드시 숫자 (0-59), null 금지
      "am_pm": "pm",    // 반드시 "am" 또는 "pm", null 금지
      "name": "약 먹기"  // 용도가 있으면 10글자 이내, 없으면 null
    }}
  ]
}}

**알람 요청 예시 (is_alarm: true):**
- "5시, 6시, 7시 알람" → name: null
- "내일 오후 2시 30분에 깨워줘" → name: null
- "오전 9시 알림 설정" → name: null
- "오후 3시에 약 먹을 시간 알려줘" → name: "약 먹기"
- "내일 아침 7시 운동 알람" → name: "운동"

**일반 대화 예시 (is_alarm: false):**
- "안녕" → {{"is_alarm": false}}
- "고마워" → {{"is_alarm": false}}
- "오늘 하루 어땠어?" → {{"is_alarm": false}}
- "날씨 어때?" → {{"is_alarm": false}}
- "좋은 하루 보내" → {{"is_alarm": false}}

**기본값:**
- 연도/월/일/요일: 지정 안 하면 현재 기준
- minute: 지정 안 하면 00
- am_pm: 13시 이상이면 pm, 아니면 am (오전/오후 언급 없으면 am)
- time: 1~12 범위로 변환 (13시 → 1시 pm, 14시 → 2시 pm)
- name: 사용자가 용도를 명시하지 않았으면 null

**요일 변환:**
- 월요일: Monday, 화요일: Tuesday, 수요일: Wednesday
- 목요일: Thursday, 금요일: Friday, 토요일: Saturday, 일요일: Sunday

**중요:** JSON만 출력하세요. 설명이나 마크다운 코드 블록 없이 순수 JSON만 반환.
"""
        
        print("[ALARM PARSER] Step 4: Prompt created, calling LLM...")
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a time parser. Return only valid JSON, no markdown or explanations."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=500
        )
        
        result_text = response.choices[0].message.content.strip()
        
        print(f"[ALARM PARSER] Step 5: LLM response received: {result_text[:200]}...")
        
        print(f"[ALARM PARSER] Step 5: LLM response received: {result_text[:200]}...")
        
        # JSON 파싱 (마크다운 코드 블록 제거)
        if result_text.startswith("```json"):
            result_text = result_text.replace("```json", "").replace("```", "").strip()
        elif result_text.startswith("```"):
            result_text = result_text.replace("```", "").strip()
        
        print(f"[ALARM PARSER] Step 6: Cleaned JSON: {result_text[:200]}...")
        
        result = json.loads(result_text)
        
        print(f"[ALARM PARSER] Step 7: JSON parsed successfully: {result}")
        
        # 알람이 아니면 None 반환
        if not result.get("is_alarm", False):
            print("[ALARM PARSER] Step 8: Not an alarm request, returning None")
            return {
                "response_type": None,
                "count": 0,
                "data": []
            }
        
        print("[ALARM PARSER] Step 9: IS an alarm request!")
        
        alarms = result.get("alarms", [])
        
        print(f"[ALARM PARSER] Step 10: Found {len(alarms)} alarms")
        
        print("[ALARM PARSER] Step 11: Processing alarms...")
        
        # 각 알람 처리 및 검증
        processed_alarms = []
        for i, alarm in enumerate(alarms):
            print(f"[ALARM PARSER] Step 12.{i}: Processing alarm {i+1}/{len(alarms)}: {alarm}")
            
            # 🆕 Null 값 검증 - time이나 minute이 None이면 스킵
            time_val = alarm.get("time")
            minute_val = alarm.get("minute")
            am_pm_val = alarm.get("am_pm")
            
            if time_val is None or minute_val is None or am_pm_val is None:
                logger.warning(f"⚠️ [Alarm] Skipping alarm {i+1}: null values detected (time={time_val}, minute={minute_val}, am_pm={am_pm_val})")
                print(f"[ALARM PARSER] Step 12.{i}: SKIPPED - null values")
                continue
            
            # Type validation
            if not isinstance(time_val, int) or not isinstance(minute_val, int):
                logger.warning(f"⚠️ [Alarm] Skipping alarm {i+1}: invalid types (time={type(time_val)}, minute={type(minute_val)})")
                print(f"[ALARM PARSER] Step 12.{i}: SKIPPED - invalid types")
                continue
            
            # 알람 시간 생성
            try:
                alarm_dt = datetime(
                    year=alarm.get("year", current_datetime.year),
                    month=alarm.get("month", current_datetime.month),
                    day=alarm.get("day", current_datetime.day),
                    hour=_convert_to_24h(time_val, am_pm_val),
                    minute=minute_val
                )
            except Exception as e:
                logger.warning(f"⚠️ [Alarm] Skipping alarm {i+1}: datetime creation failed - {e}")
                print(f"[ALARM PARSER] Step 12.{i}: SKIPPED - datetime error")
                continue
            
            # 과거 날짜 검증
            is_valid = alarm_dt > current_datetime
            
            print(f"[ALARM PARSER] Step 13.{i}: alarm_dt={alarm_dt}, current={current_datetime}, is_valid={is_valid}")
            
            # � Name 필드 처리
            alarm_name = alarm.get("name")
            if alarm_name:
                # 사용자가 명시한 이름이 있으면 무조건 그대로 사용
                pass
            else:
                # name이 null일 경우에만 이스터에그 또는 기본값 적용
                if random.random() < 0.001:  # 0.1% 확률
                    easter_eggs = [
                        "봄이 와쪄욤><",
                        "(❁´▽`❁)",
                        "(❀╹◡╹)",
                        "◟( ˘ ³˘)◞ "
                    ]
                    alarm_name = random.choice(easter_eggs)
                    logger.info(f"🎉 [Easter Egg] {alarm_name}")
                else:
                    alarm_name = "봄이의 알림"
            
            # 🆕 유효한 알람만 추가 (time/minute/name 포함)
            if is_valid:
                processed_alarms.append({
                    "year": alarm_dt.year,
                    "month": alarm_dt.month,
                    "week": alarm.get("week", [current_datetime.strftime('%A')]),
                    "day": alarm_dt.day,
                    "is_valid_alarm": True,
                    "time": time_val,
                    "minute": minute_val,
                    "am_pm": am_pm_val,
                    "name": alarm_name
                })
                print(f"[ALARM PARSER] Step 14.{i}: ADDED - valid alarm with name: {alarm_name}")
            else:
                print(f"[ALARM PARSER] Step 14.{i}: SKIPPED - past datetime")
        
        # 🆕 최종 검증: 유효한 알람이 하나도 없으면 None 반환
        if not processed_alarms:
            logger.warning(f"⚠️ [Alarm] No valid alarms after processing")
            print("[ALARM PARSER] Step 15: NO VALID ALARMS - returning None")
            return {
                "response_type": None,
                "count": 0,
                "data": []
            }
        
        logger.info(f"✅ [Alarm] Parsed {len(processed_alarms)} valid alarms")
        print(f"[ALARM PARSER] Step 15: SUCCESS! Returning {len(processed_alarms)} alarm(s)")
        
        result = {
            "response_type": "alarm",
            "count": len(processed_alarms),
            "data": processed_alarms
        }
        
        print(f"[ALARM PARSER] Step 15: FINAL RESULT: {result}")
        print("=" * 80)
        
        return result
        
    except Exception as e:
        logger.error(f"Failed to parse alarm request: {e}", exc_info=True)
        print(f"[ALARM PARSER] ERROR: {e}")
        print("=" * 80)
        return {
            "response_type": None,
            "count": 0,
            "data": []
        }


def _convert_to_24h(time_12h: int, am_pm: str) -> int:
    """12시간 형식을 24시간 형식으로 변환"""
    if am_pm.lower() == "pm" and time_12h != 12:
        return time_12h + 12
    elif am_pm.lower() == "am" and time_12h == 12:
        return 0
    else:
        return time_12h
