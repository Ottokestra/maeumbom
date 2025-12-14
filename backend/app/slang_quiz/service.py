"""
Business logic for slang quiz game
OpenAI integration, question selection, score calculation
"""
import os
import json
import asyncio
import re
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func
from openai import AsyncOpenAI
from dotenv import load_dotenv

from app.db.models import SlangQuizQuestion, SlangQuizGame, SlangQuizAnswer, User

# Load environment variables
load_dotenv()

# Initialize OpenAI client
client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))


# ============================================================================
# Ethics Filtering Constants
# ============================================================================

# 초성 줄임말 패턴: 한글 자음/모음만으로 이루어진 단어 (2-4자)
INITIALISM_PATTERN = re.compile(r'^[ㄱ-ㅎㅏ-ㅣ]{2,4}$')

# 윤리성 필터에 걸리는 단어 블랙리스트
# 특정 단체/커뮤니티에서 유래한 단어, 폭력적/차별적 단어 등
BLACKLIST_WORDS = {
    "웅앵웅",  # 특정 단체에서 유래
    # 추가로 발견되는 단어들을 여기에 추가
}

# 초성 줄임말 예시 (참고용)
COMMON_INITIALISMS = {
    "ㅇㅋ", "ㅇㅈ", "ㅈㄱㄴ", "ㄱㅅ", "ㅅㄱ", "ㅎㅇ", "ㅂㅂ", "ㅇㄷ",
    "ㄴㄴ", "ㅇㅇ", "ㄱㄷ", "ㅈㅅ", "ㅂㄱ", "ㅇㄹ", "ㄱㄴ", "ㅇㅁ"
}


# ============================================================================
# Constants
# ============================================================================

DIFFICULTY_INSTRUCTIONS = {
    "beginner": """
[초급 - 매우 대중적인 한국 신조어]
- 5060 세대도 한 번쯤 들어봤을 법한 단어
- TV, 뉴스, 일상 대화에서 자주 등장하는 단어
- **중요 제약사항**:
  * 초성만 있는 줄임말(ㅇㅈ, ㄱㅅ, ㅈㄱㄴ 등)은 절대 사용하지 마세요
  * 의미가 명확하고 교육적 가치가 있는 단어만 선택하세요
  * 단어의 유래나 배경 스토리가 있는 단어를 우선 선택하세요
- 좋은 예시: "킹받네", "TMI", "꾸안꾸", "갑분싸", "존맛", "핵인싸", "갓생", "억텐", "프불"
- 나쁜 예시: "ㅇㅈ", "ㄱㅅ", "ㅈㄱㄴ" (초성만 있는 줄임말)
""",
    "intermediate": """
[중급 - 들어본 적 있는 한국 신조어]
- 젊은 세대(10대~30대)가 자주 사용하는 단어
- 뜻을 정확히 모를 수 있지만 들어본 적은 있는 단어
- **중요 제약사항**:
  * 초성만 있는 줄임말은 절대 사용하지 마세요
  * 의미가 풍부하고 창의적인 단어를 선택하세요
  * 단어의 유래나 언어 유희적 요소가 있는 단어를 우선 선택하세요
- 좋은 예시: "갓생", "억텐", "프불", "갑분싸", "별다줄", "오하영", "점메추", "군싹", "제곧내", "존버"
- 나쁜 예시: "ㅇㅈ", "ㅈㄱㄴ", "ㅇㅋ" (초성만 있는 줄임말)
""",
    "advanced": """
[고급 - 최신/특정 커뮤니티 한국 신조어]
- **매우 어려운 난이도**: 5060 세대가 거의 모를 법한 최신 트렌드 단어
- 최신 트렌드(2024-2025년) 또는 특정 온라인 커뮤니티(인스타, 틱톡, 게임, 웹툰 등)에서만 사용
- 세대 간 소통이 꼭 필요한 단어
- **중요 제약사항**:
  * 초성만 있는 줄임말은 절대 사용하지 마세요
  * 중급 단어와 명확히 구분되는 매우 어려운 단어만 선택하세요
  * 창의적이고 재미있으며 교육적 가치가 있는 단어를 선택하세요
  * 단어의 창의성과 언어 유희적 요소가 뚜렷한 단어를 우선 선택하세요
  * 특정 문화나 배경 지식이 필요한 단어를 우선 선택하세요
- **난이도 기준**:
  * 중급 단어("갓생", "억텐", "프불" 등)보다 훨씬 어려워야 함
  * 5060 세대가 한 번도 들어본 적 없을 법한 단어
  * 젊은 세대도 일부만 알고 있는 최신 단어
- 좋은 예시: "제곧내", "머선129", "웅앵웅", "존버", "캘박", "별다줄", "점메추", "군싹", "오하영", "갑분싸", "킹받게스트", "제곧내", "머선129"
- 나쁜 예시: "ㅇㅈ", "ㅈㄱㄴ", "ㅇㅋ" (초성만 있는 줄임말), "갓생", "억텐" (중급 수준)
- **추가 요구사항**: 
  * 단어의 유래가 특정 문화(게임, 웹툰, 드라마, 유튜브 등)에서 나온 경우 그 배경을 설명에 포함하세요
  * 언어 유희적 요소(말장난, 발음 유사 등)가 있는 단어를 우선 선택하세요
"""
}

QUIZ_TYPE_INSTRUCTIONS = {
    "word_to_meaning": """
[퀴즈 타입: 단어 → 뜻]
1. 문제 형식: "자녀가 'OOO'라고 했다면 무슨 뜻일까요?"
2. 보기 4개: 정답 뜻 1개 + 그럴듯한 오답 뜻 3개
3. **오답 생성 규칙**:
   - 오답은 실제로 있을 법한 뜻으로 만들어서 헷갈리게 하세요
   - 정답과 비슷하지만 미묘하게 다른 의미로 만들기
   - 예: 정답이 "화가 난다"면 오답은 "기분이 좋다", "슬프다", "놀라다" 등 감정 관련이지만 다른 의미
   - 너무 명백하게 틀린 오답은 피하세요 (예: "배가 고프다", "졸리다" 같은 전혀 관련 없는 것)
4. **단어 선택 기준**:
   - 의미가 명확하고 교육적 가치가 있는 단어
   - 실제로 자주 사용되는 단어
   - 5060 세대가 배우면 유용한 단어
""",
    "meaning_to_word": """
[퀴즈 타입: 뜻 → 단어]

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! 절대 규칙 (CRITICAL RULES) - 반드시 따라야 합니다 !!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

규칙 1: 문제(question)에는 절대 단어를 넣지 마세요! 오직 뜻(풀어쓴 표현)만 넣으세요!
규칙 2: 선택지(options)에는 절대 뜻을 넣지 마세요! 오직 단어만 넣으세요!
규칙 3: 실제로 존재하는 한국 신조어만 사용하세요! 절대 만들어내지 마세요!
       - 인터넷, SNS, 커뮤니티에서 실제로 사용되는 단어만 선택하세요
       - 없는 단어를 창작하거나 추측하지 마세요
       - 예: "조와" 같은 존재하지 않는 단어는 절대 사용 금지!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

1. 문제 형식 (MUST FOLLOW):
   
   반드시 이 형식을 따르세요:
   "자녀가 '[뜻의 풀어쓴 표현]'라고 말하면 어떤 단어일까요?"
   
   ✅ 올바른 예시 (CORRECT):
   - "자녀가 '갑자기 분위기 싸해졌다'라고 말하면 어떤 단어일까요?"
   - "자녀가 '제목이 곧 내용이다'라고 말하면 어떤 단어일까요?"
   - "자녀가 '엄청 좋다'라고 말하면 어떤 단어일까요?"
   
   ❌ 절대 하지 마세요 (NEVER DO THIS):
   - "자녀가 '갑분싸'라고 했다면 무슨 뜻일까요?" (단어를 물어봄 - 잘못됨!)
   - "자녀가 '개꿀'이라고 말하면 어떤 뜻일까요?" (단어를 물어봄 - 잘못됨!)
   - "자녀가 '노잼'이라고 했다면 무슨 뜻일까요?" (단어를 물어봄 - 잘못됨!)

2. 선택지 형식 (MUST FOLLOW):
   
   반드시 단어만 넣으세요! 뜻을 넣으면 안 됩니다!
   
   ✅ 올바른 예시 (CORRECT):
   - ["갑분싸", "갑싸", "갑분", "분싸"] (모두 단어 - 정답!)
   - ["제곧내", "제곧나", "제목내", "곧내"] (모두 단어 - 정답!)
   - ["개꿀", "개굴", "꿀", "개좋"] (모두 단어 - 정답!)
   
   ❌ 절대 하지 마세요 (NEVER DO THIS):
   - ["갑자기 분위기 싸해졌다", "갑자기 분위기 좋다", ...] (뜻들 - 잘못됨!)
   - ["아주 좋다", "아주 나쁘다", ...] (뜻들 - 잘못됨!)
   - ["재미없다", "재미있다", ...] (뜻들 - 잘못됨!)

3. **오답 생성 규칙 (매우 중요!):**
   
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!! 오답은 반드시 정답 단어와 발음이 비슷한 단어여야 합니다! !!!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   
   오답 생성 방법:
   a) 정답 단어의 일부 글자를 변형
      - 예: "갑분싸" → "갑싸", "갑분", "분싸"
      - 예: "제곧내" → "제곧나", "제목내", "곧내"
   
   b) 정답 단어와 발음이 비슷한 다른 단어
      - 예: "갓생" → "갓난", "갓물", "갓길"
      - 예: "존버" → "존비", "존대", "버티"
   
   c) 정답 단어에 글자 추가/삭제
      - 예: "캘박" → "캘더박", "캘리박", "캘박하"
   
   ❌ 절대 하지 마세요:
   - 정답 단어를 쪼개서 오답으로 사용 (예: "갑분싸" → "갑자기", "분위기", "싸해" ❌)
   - 전혀 관련 없는 단어 (예: "존버" → "아재개그", "고수", "이상형" ❌)
   - 뜻을 오답으로 사용 (예: "개꿀" → "아주 좋다", "아주 나쁘다" ❌)

4. **완벽한 JSON 예시**:

예시 1 (갑분싸):
{
  "word": "갑분싸",
  "question": "자녀가 '갑자기 분위기 싸해졌다'라고 말하면 어떤 단어일까요?",
  "options": ["갑분싸", "갑싸", "갑분", "분싸"],
  "answer_index": 0
}

예시 2 (개꿀):
{
  "word": "개꿀",
  "question": "자녀가 '엄청 좋다'라고 말하면 어떤 단어일까요?",
  "options": ["개꿀", "개굴", "꿀", "개좋"],
  "answer_index": 0
}

예시 3 (노잼):
{
  "word": "노잼",
  "question": "자녀가 '재미없다'라고 말하면 어떤 단어일까요?",
  "options": ["노잼", "노잼보", "잼없", "노재"],
  "answer_index": 0
}

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
다시 한번 강조: 문제에는 뜻만, 선택지에는 단어만 넣으세요!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"""
}


# ============================================================================
# Ethics Filtering Functions
# ============================================================================

def is_initialism(word: str) -> bool:
    """
    Check if word is an initialism (초성 줄임말)
    
    Args:
        word: Word to check
        
    Returns:
        True if word is an initialism
    """
    if not word:
        return False
    
    # Check if matches initialism pattern
    if INITIALISM_PATTERN.match(word):
        return True
    
    # Check against common initialisms
    if word in COMMON_INITIALISMS:
        return True
    
    return False


def is_blacklisted(word: str) -> bool:
    """
    Check if word is in blacklist
    
    Args:
        word: Word to check
        
    Returns:
        True if word is blacklisted
    """
    return word in BLACKLIST_WORDS


def is_unethical_question(question: Dict[str, Any]) -> Tuple[bool, str]:
    """
    Check if question violates ethical guidelines
    
    Args:
        question: Question dictionary
        
    Returns:
        (is_unethical, reason)
    """
    word = question.get("word", "")
    
    # Check initialism
    if is_initialism(word):
        return True, "initialism"
    
    # Check blacklist
    if is_blacklisted(word):
        return True, "blacklisted"
    
    return False, ""


def filter_unethical_questions(questions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Filter out unethical questions
    
    Args:
        questions: List of question dictionaries
        
    Returns:
        List of valid questions
    """
    valid_questions = []
    filtered_count = 0
    filtered_words = []
    
    for q in questions:
        is_unethical, reason = is_unethical_question(q)
        if is_unethical:
            word = q.get("word", "unknown")
            filtered_words.append(f"{word} ({reason})")
            filtered_count += 1
        else:
            valid_questions.append(q)
    
    if filtered_count > 0:
        print(f"[FILTER] Filtered out {filtered_count} unethical questions: {', '.join(filtered_words)}")
    
    return valid_questions


# ============================================================================
# OpenAI Service
# ============================================================================

async def generate_quiz_with_openai(
    level: str,
    quiz_type: str,
    count: int = 1,
    exclude_words: Optional[List[str]] = None
) -> List[Dict[str, Any]]:
    """
    Generate quiz questions using OpenAI GPT-4o-mini
    
    Args:
        level: Difficulty level (beginner/intermediate/advanced)
        quiz_type: Quiz type (word_to_meaning/meaning_to_word)
        count: Number of questions to generate
        exclude_words: Words to exclude from generation
        
    Returns:
        List of quiz question dictionaries
    """
    difficulty_instruction = DIFFICULTY_INSTRUCTIONS.get(level, DIFFICULTY_INSTRUCTIONS["beginner"])
    quiz_type_instruction = QUIZ_TYPE_INSTRUCTIONS.get(quiz_type, QUIZ_TYPE_INSTRUCTIONS["word_to_meaning"])
    
    exclude_text = ""
    if exclude_words:
        exclude_text = f"""

[중요 - 중복 방지]
이미 출제된 단어 목록: {', '.join(exclude_words)}
→ **절대 이 단어들을 다시 사용하지 마세요**
→ 각 문제마다 서로 다른 단어를 사용해야 합니다
→ {count}개의 문제를 생성할 때 모든 단어가 서로 달라야 합니다
→ 같은 단어를 여러 번 사용하면 안 됩니다"""
    
    prompt = f"""당신은 **한국의 5060 여성**을 위한 **한국 신조어** 교육 전문가입니다.

[중요 원칙]
- 반드시 **한국에서 사용되는 신조어**만 사용하세요
- 한국 젊은 세대(10대~30대)가 실제로 사용하는 단어
- 인터넷, SNS, 카카오톡 등에서 자주 쓰이는 표현
- **절대 초성만 있는 줄임말(ㅇㅈ, ㄱㅅ, ㅈㄱㄴ, ㅇㅋ 등)은 사용하지 마세요**
- 의미가 명확하고 교육적 가치가 있는 단어만 선택하세요

[요청사항]
- 난이도: {level}
- 퀴즈 타입: {quiz_type}
- 문제 개수: {count}개
- 문제당 제한 시간: 40초

{difficulty_instruction}

{quiz_type_instruction}

[단어 선택 기준]
1. **교육적 가치**: 5060 세대가 배우면 자녀와의 소통에 도움이 되는 단어
2. **명확성**: 의미가 명확하고 모호하지 않은 단어
3. **실용성**: 실제로 자주 사용되는 단어
4. **흥미**: 재미있고 배우고 싶은 단어
5. **유래**: 단어의 유래나 배경 스토리가 있는 단어 우선

[해설 작성 규칙]
- **상세한 설명** (최소 50자 이상):
  * 단어의 유래와 배경 스토리 설명
  * 왜 이 단어가 생겼는지 설명
  * 실제 사용 예시 2개 이상 포함
  * 5060 세대가 이해하기 쉬운 비유나 설명 추가
- 해요체로 친근하게 작성하세요
- 5060 여성이 이해하기 쉽게 설명하세요
- 예시: "'킹받네'는 '열받네'를 강조한 표현이에요. '킹'은 영어 'king'에서 유래했으며, 무언가를 강조할 때 사용해요. '킹'은 '최고', '엄청난'이라는 의미로, '킹받네'는 '엄청나게 화가 난다'는 뜻이에요. 예를 들어 '오늘 일이 너무 킹받네', '이 사람 정말 킹받게 만든다'처럼 사용합니다."

[보상 카드 작성 규칙]
- 해당 단어를 포함한 자녀 응원 메시지 (30자 이내)
- 부정적 단어도 긍정적 맥락으로 포장하세요
- 예: "킹받는 일이 있어도 엄마는 네 편이야!"
- background_mood는 메시지 분위기에 따라 warm(따뜻한), cheer(밝은), cool(차분한) 중 선택

{exclude_text}

[출력 형식]
반드시 다음 JSON 형식으로 응답하세요:

{{
  "questions": [
    {{
      "word": "갓생",
      "question": "자녀가 '갓생'이라고 했다면 무슨 뜻일까요?",
      "options": [
        "신처럼 사는 삶",
        "게으른 삶",
        "바쁜 삶",
        "평범한 삶"
      ],
      "answer_index": 0,
      "explanation": "'갓생'은 '갓(God)'과 '생(生)'을 합친 말로, '신처럼 사는 삶'이라는 뜻이에요. 목표를 가지고 열심히 살아가는 삶, 또는 이상적인 삶을 의미해요. '갓'은 '신'을 뜻하면서 동시에 '최고의', '완벽한'이라는 의미도 담고 있어요. 예를 들어 '올해는 갓생 살기 위해 열심히 운동할 거야', '갓생을 위해 매일 일찍 일어나고 있어'처럼 사용합니다. 이 표현은 자신의 삶을 긍정적으로 표현하고 싶을 때 자주 쓰여요.",
      "reward_card": {{
        "message": "너는 이미 갓생을 살고 있어!",
        "background_mood": "cheer"
      }}
    }}
    ... (총 {count}개)
  ]
}}

[중복 방지 - 매우 중요]
- {count}개의 문제를 생성할 때 각 문제의 "word" 필드는 모두 서로 달라야 합니다
- 같은 단어를 여러 번 사용하면 안 됩니다
- 각 문제마다 고유한 단어를 사용하세요

[체크리스트]
각 문제 생성 시 확인:
1. 초성 줄임말 아님 (ㅇㅈ, ㄱㅅ, ㅈㄱㄴ, ㅇㅋ 등 제외)
2. 중복 단어 아님 (매우 중요!)
3. 의미 명확, 교육적 가치 있음
4. 설명 상세 (50자 이상), 예시 2개 이상
"""
    
    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = await client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": "당신은 한국 신조어 교육 전문가입니다. 항상 JSON 형식으로 응답합니다."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.8,
                response_format={"type": "json_object"}
            )
            
            result = json.loads(response.choices[0].message.content)
            questions = result.get("questions", [])
            
            # Validate structure first
            valid_structured_questions = []
            for q in questions:
                if not all(key in q for key in ["word", "question", "options", "answer_index", "explanation", "reward_card"]):
                    continue
                if len(q["options"]) != 4:
                    continue
                if not (0 <= q["answer_index"] <= 3):
                    continue
                valid_structured_questions.append(q)
            
            if not valid_structured_questions:
                raise ValueError(f"No valid structured questions generated (got {len(questions)} total)")
            
            # Filter out unethical questions
            ethical_questions = filter_unethical_questions(valid_structured_questions)
            
            # Accept if we have at least 80% of requested count after filtering
            min_required = max(1, int(count * 0.8))
            if len(ethical_questions) >= min_required:
                if len(ethical_questions) < count:
                    print(f"[WARN] Generated {len(ethical_questions)} ethical questions instead of {count}, accepting anyway")
                return ethical_questions[:count]
            
            # If we have some ethical questions but not enough, retry
            if ethical_questions:
                print(f"[WARN] Only {len(ethical_questions)} ethical questions after filtering, retrying...")
                if attempt == max_retries - 1:
                    # Return what we have on last attempt
                    return ethical_questions[:count]
            else:
                raise ValueError(f"No ethical questions after filtering (got {len(valid_structured_questions)} valid structured questions)")
            
        except Exception as e:
            print(f"[ERROR] OpenAI API call failed (attempt {attempt + 1}/{max_retries}): {e}")
            if attempt == max_retries - 1:
                raise
            await asyncio.sleep(1)  # Wait before retry
    
    return []


# ============================================================================
# Question Selection Logic
# ============================================================================

def select_questions_for_user(
    db: Session,
    user_id: int,
    level: str,
    quiz_type: str,
    count: int = 5
) -> List[SlangQuizQuestion]:
    """
    Select questions for user (prioritize unsolved questions)
    
    Args:
        db: Database session
        user_id: User ID
        level: Difficulty level
        quiz_type: Quiz type
        count: Number of questions to select
        
    Returns:
        List of SlangQuizQuestion objects (guaranteed unique)
    """
    # 1. Get IDs of questions already solved by user
    solved_ids = db.query(SlangQuizAnswer.QUESTION_ID).filter(
        SlangQuizAnswer.USER_ID == user_id,
        SlangQuizAnswer.IS_DELETED == False
    ).distinct().all()
    solved_ids = [id[0] for id in solved_ids]
    
    selected_questions = []
    selected_ids = set()
    
    # 2. Try to get unsolved questions first
    unsolved_questions = db.query(SlangQuizQuestion).filter(
        SlangQuizQuestion.LEVEL == level,
        SlangQuizQuestion.QUIZ_TYPE == quiz_type,
        SlangQuizQuestion.IS_ACTIVE == True,
        SlangQuizQuestion.IS_DELETED == False,
        SlangQuizQuestion.ID.notin_(solved_ids) if solved_ids else True
    ).order_by(func.random()).all()
    
    # Add unique unsolved questions
    for q in unsolved_questions:
        if q.ID not in selected_ids:
            selected_questions.append(q)
            selected_ids.add(q.ID)
            if len(selected_questions) >= count:
                break
    
    # 3. If not enough, get from all questions (excluding already selected)
    if len(selected_questions) < count:
        all_questions = db.query(SlangQuizQuestion).filter(
            SlangQuizQuestion.LEVEL == level,
            SlangQuizQuestion.QUIZ_TYPE == quiz_type,
            SlangQuizQuestion.IS_ACTIVE == True,
            SlangQuizQuestion.IS_DELETED == False,
            SlangQuizQuestion.ID.notin_(list(selected_ids)) if selected_ids else True
        ).order_by(func.random()).all()
        
        for q in all_questions:
            if q.ID not in selected_ids:
                selected_questions.append(q)
                selected_ids.add(q.ID)
                if len(selected_questions) >= count:
                    break
    
    # 4. Ensure no duplicates (final check)
    unique_questions = []
    seen_ids = set()
    for q in selected_questions:
        if q.ID not in seen_ids:
            unique_questions.append(q)
            seen_ids.add(q.ID)
    
    if len(unique_questions) != len(selected_questions):
        print(f"[WARN] Removed {len(selected_questions) - len(unique_questions)} duplicate questions")
    
    return unique_questions


# ============================================================================
# Score Calculation Logic
# ============================================================================

def calculate_score(is_correct: bool, response_time: int) -> int:
    """
    Calculate score based on correctness and response time
    
    문제당 20점 만점 (총 5문제 = 100점):
    - 1초: 20점
    - 2초: 19점
    - 10초: 11점
    - 20초: 1점
    - 20초 초과: 0점 (타임아웃)
    - 오답: 0점
    
    공식: 점수 = 21 - 응답시간
    
    Args:
        is_correct: Whether the answer is correct
        response_time: Time taken to answer (seconds)
        
    Returns:
        Score earned (0-20 points per question)
    """
    if not is_correct:
        return 0
    
    # 타임아웃 체크 (20초 초과)
    if response_time > 20:
        return 0
    
    # 점수 계산: 21 - 응답시간
    # min/max로 안전장치 (0-20점 범위)
    score = 21 - response_time
    return min(20, max(0, score))


def calculate_ranking(
    db: Session,
    game_id: int,
    level: str,
    quiz_type: str,
    total_score: int
) -> Optional[Dict[str, Any]]:
    """
    Calculate ranking for a completed game
    
    같은 난이도 + 퀴즈 타입의 완료된 게임들과 비교하여 랭킹 계산
    
    Args:
        db: Database session
        game_id: Current game ID (자신 제외용)
        level: Difficulty level (beginner/intermediate/advanced)
        quiz_type: Quiz type (word_to_meaning/meaning_to_word)
        total_score: Total score of current game (0-100)
        
    Returns:
        Ranking information dict or None if not enough data
        {
            "percentile": 80.0,
            "total_games": 100,
            "better_than": 80,
            "rank_message": "🎉 초급 단어→뜻 퀴즈에서 상위 20%입니다!"
        }
    """
    # 1. 같은 level + quiz_type의 완료된 게임들 조회 (자신 제외, 표준 필드 활용)
    same_category_games = db.query(SlangQuizGame).filter(
        SlangQuizGame.LEVEL == level,
        SlangQuizGame.QUIZ_TYPE == quiz_type,
        SlangQuizGame.IS_COMPLETED == True,
        SlangQuizGame.IS_DELETED == False,
        SlangQuizGame.ID != game_id  # 자신 제외
    ).all()
    
    # 최소 게임 수 체크 (10개 이상일 때만 랭킹 표시)
    if len(same_category_games) < 10:
        return None
    
    # 2. 내 점수보다 낮은 게임 개수 계산
    better_than = sum(1 for g in same_category_games if g.TOTAL_SCORE < total_score)
    
    # 3. 백분위 계산
    total_games = len(same_category_games)
    percentile = (better_than / total_games) * 100
    
    # 4. 상위 퍼센트 계산
    top_percent = 100 - percentile
    
    # 5. 메시지 생성
    level_kr = {"beginner": "초급", "intermediate": "중급", "advanced": "고급"}
    type_kr = {"word_to_meaning": "단어→뜻", "meaning_to_word": "뜻→단어"}
    
    if top_percent <= 10:
        rank_message = f"🏆 {level_kr[level]} {type_kr[quiz_type]} 퀴즈에서 상위 {top_percent:.0f}%입니다! 대단해요!"
    elif top_percent <= 30:
        rank_message = f"🎉 {level_kr[level]} {type_kr[quiz_type]} 퀴즈에서 상위 {top_percent:.0f}%입니다!"
    elif top_percent <= 50:
        rank_message = f"👍 {level_kr[level]} {type_kr[quiz_type]} 퀴즈에서 상위 {top_percent:.0f}%입니다!"
    else:
        rank_message = f"💪 {level_kr[level]} {type_kr[quiz_type]} 퀴즈에서 상위 {top_percent:.0f}%입니다. 화이팅!"
    
    return {
        "percentile": round(percentile, 1),
        "total_games": total_games + 1,  # 자신 포함
        "better_than": better_than,
        "rank_message": rank_message
    }


# ============================================================================
# Data Persistence (JSON Backup)
# ============================================================================

def save_questions_to_json(
    questions: List[Dict[str, Any]],
    level: str,
    quiz_type: str,
    base_path: Optional[Path] = None
) -> None:
    """
    Save questions to JSON files (backup)
    
    Args:
        questions: List of question dictionaries
        level: Difficulty level
        quiz_type: Quiz type
        base_path: Base path for data folder (default: app/slang_quiz/data)
    """
    if base_path is None:
        base_path = Path(__file__).parent / "data"
    
    folder_path = base_path / level / quiz_type
    folder_path.mkdir(parents=True, exist_ok=True)
    
    # Get existing file count
    existing_files = list(folder_path.glob("question_*.json"))
    start_num = len(existing_files) + 1
    
    for idx, question in enumerate(questions, start=start_num):
        filename = f"question_{idx:03d}.json"
        file_path = folder_path / filename
        
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(question, f, ensure_ascii=False, indent=2)
    
    print(f"[INFO] Saved {len(questions)} questions to {folder_path}")


def load_questions_from_json(
    level: str,
    quiz_type: str,
    base_path: Optional[Path] = None
) -> List[Dict[str, Any]]:
    """
    Load questions from JSON files
    
    Args:
        level: Difficulty level
        quiz_type: Quiz type
        base_path: Base path for data folder
        
    Returns:
        List of question dictionaries
    """
    if base_path is None:
        base_path = Path(__file__).parent / "data"
    
    folder_path = base_path / level / quiz_type
    
    if not folder_path.exists():
        return []
    
    questions = []
    for file_path in sorted(folder_path.glob("question_*.json")):
        with open(file_path, "r", encoding="utf-8") as f:
            question = json.load(f)
            questions.append(question)
    
    return questions


# ============================================================================
# Database Operations
# ============================================================================

def save_questions_to_db(
    db: Session,
    questions: List[Dict[str, Any]],
    level: str,
    quiz_type: str,
    created_by: Optional[int] = None
) -> List[SlangQuizQuestion]:
    """
    Save questions to database (with duplicate check)
    
    Args:
        db: Database session
        questions: List of question dictionaries
        level: Difficulty level
        quiz_type: Quiz type
        created_by: Creator user ID
        
    Returns:
        List of created SlangQuizQuestion objects
    """
    # Get existing words to avoid duplicates
    existing_questions = db.query(SlangQuizQuestion).filter(
        SlangQuizQuestion.LEVEL == level,
        SlangQuizQuestion.QUIZ_TYPE == quiz_type,
        SlangQuizQuestion.IS_DELETED == False
    ).all()
    
    existing_words = {q.WORD for q in existing_questions}
    
    created_questions = []
    skipped_words = []
    
    for q in questions:
        word = q["word"]
        
        # Skip if word already exists
        if word in existing_words:
            skipped_words.append(word)
            continue
        
        question = SlangQuizQuestion(
            LEVEL=level,
            QUIZ_TYPE=quiz_type,
            WORD=word,
            QUESTION=q["question"],
            OPTIONS=q["options"],
            ANSWER_INDEX=q["answer_index"],
            EXPLANATION=q["explanation"],
            REWARD_MESSAGE=q["reward_card"]["message"],
            REWARD_BACKGROUND_MOOD=q["reward_card"]["background_mood"],
            IS_ACTIVE=True,
            USAGE_COUNT=0,
            CREATED_BY=created_by
        )
        db.add(question)
        created_questions.append(question)
        existing_words.add(word)  # Add to set to prevent duplicates within the same batch
    
    if skipped_words:
        print(f"[WARN] 중복 단어로 인해 {len(skipped_words)}개 문제 건너뜀: {', '.join(skipped_words[:10])}")
    
    db.commit()
    
    for q in created_questions:
        db.refresh(q)
    
    return created_questions

