"""
Business logic for slang quiz game
OpenAI integration, question selection, score calculation
"""
import os
import json
import asyncio
from pathlib import Path
from typing import List, Dict, Any, Optional
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
# Constants
# ============================================================================

DIFFICULTY_INSTRUCTIONS = {
    "beginner": """
[초급 - 매우 대중적인 한국 신조어]
- 5060 세대도 한 번쯤 들어봤을 법한 단어
- TV, 뉴스, 일상 대화에서 자주 등장하는 단어
- 예시: "킹받네", "ㅇㅈ(인정)", "ㄱㅅ(감사)", "TMI", "꾸안꾸", "갑분싸", "존맛", "핵인싸"
""",
    "intermediate": """
[중급 - 들어본 적 있는 한국 신조어]
- 젊은 세대(10대~30대)가 자주 사용하는 단어
- 뜻을 정확히 모를 수 있지만 들어본 적은 있는 단어
- 예시: "갓생", "억텐", "프불", "갑분싸", "별다줄", "오하영", "점메추", "군싹"
""",
    "advanced": """
[고급 - 최신/특정 커뮤니티 한국 신조어]
- 최신 트렌드 또는 특정 온라인 커뮤니티(인스타, 틱톡 등)에서 사용
- 세대 간 소통이 필요한 단어
- 예시: "제곧내", "머선129", "웅앵웅", "존버", "킹받게스트", "ㅈㄱㄴ", "ㅇㅋ"
"""
}

QUIZ_TYPE_INSTRUCTIONS = {
    "word_to_meaning": """
[퀴즈 타입: 단어 → 뜻]
1. 문제 형식: "자녀가 'OOO'라고 했다면 무슨 뜻일까요?"
2. 보기 4개: 정답 뜻 1개 + 그럴듯한 오답 뜻 3개
3. 오답은 실제로 있을 법한 뜻으로 만들어서 헷갈리게 하세요
""",
    "meaning_to_word": """
[퀴즈 타입: 뜻 → 단어]
1. 문제 형식: "다음 중 'OOO(뜻)'을 의미하는 단어는?"
2. 보기 4개: 정답 단어 1개 + 말장난 오답 3개
3. **중요**: 오답은 정답 단어와 발음이나 글자가 비슷해서 헷갈리는 단어로 만드세요
   예: 정답 '캘박' → 오답 '캘더박', '캘리박', '캘박하'
"""
}


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
        exclude_text = f"\n\n[중요] 이미 출제된 단어: {', '.join(exclude_words)}\n→ 이 단어들은 제외하고 다른 단어로 생성하세요."
    
    prompt = f"""당신은 **한국의 5060 여성**을 위한 **한국 신조어** 교육 전문가입니다.

[중요]
- 반드시 **한국에서 사용되는 신조어**만 사용하세요
- 한국 젊은 세대(10대~30대)가 실제로 사용하는 단어
- 인터넷, SNS, 카카오톡 등에서 자주 쓰이는 표현

[요청사항]
- 난이도: {level}
- 퀴즈 타입: {quiz_type}
- 문제 개수: {count}개
- 문제당 제한 시간: 40초

{difficulty_instruction}

{quiz_type_instruction}

[해설 작성 규칙]
- 단어의 유래와 사용 예시를 포함하세요
- 해요체로 친근하게 작성하세요
- 5060 여성이 이해하기 쉽게 설명하세요

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
      "word": "킹받네",
      "question": "자녀가 '킹받네'라고 했다면 무슨 뜻일까요?",
      "options": ["기분이 좋다", "화가 난다", "배가 고프다", "졸리다"],
      "answer_index": 1,
      "explanation": "'킹받네'는 '열받네'를 강조한 표현이에요. '킹'은 영어 'king'에서 유래했으며, 무언가를 강조할 때 사용해요. 예를 들어 '오늘 일이 너무 킹받네'처럼 사용합니다.",
      "reward_card": {{
        "message": "킹받는 일이 있어도 엄마는 네 편이야!",
        "background_mood": "warm"
      }}
    }}
    ... (총 {count}개)
  ]
}}
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
            
            # Validate response
            if not questions or len(questions) != count:
                raise ValueError(f"Expected {count} questions, got {len(questions)}")
            
            for q in questions:
                if not all(key in q for key in ["word", "question", "options", "answer_index", "explanation", "reward_card"]):
                    raise ValueError("Missing required fields in question")
                if len(q["options"]) != 4:
                    raise ValueError("Expected 4 options")
                if not (0 <= q["answer_index"] <= 3):
                    raise ValueError("Invalid answer_index")
            
            return questions
            
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
        List of SlangQuizQuestion objects
    """
    # 1. Get IDs of questions already solved by user
    solved_ids = db.query(SlangQuizAnswer.QUESTION_ID).filter(
        SlangQuizAnswer.USER_ID == user_id,
        SlangQuizAnswer.IS_DELETED == False
    ).distinct().all()
    solved_ids = [id[0] for id in solved_ids]
    
    # 2. Try to get unsolved questions
    questions = db.query(SlangQuizQuestion).filter(
        SlangQuizQuestion.LEVEL == level,
        SlangQuizQuestion.QUIZ_TYPE == quiz_type,
        SlangQuizQuestion.IS_ACTIVE == True,
        SlangQuizQuestion.IS_DELETED == False,
        SlangQuizQuestion.ID.notin_(solved_ids) if solved_ids else True
    ).order_by(func.random()).limit(count).all()
    
    # 3. If not enough unsolved questions, get from all questions
    if len(questions) < count:
        questions = db.query(SlangQuizQuestion).filter(
            SlangQuizQuestion.LEVEL == level,
            SlangQuizQuestion.QUIZ_TYPE == quiz_type,
            SlangQuizQuestion.IS_ACTIVE == True,
            SlangQuizQuestion.IS_DELETED == False
        ).order_by(func.random()).limit(count).all()
    
    return questions


# ============================================================================
# Score Calculation Logic
# ============================================================================

def calculate_score(is_correct: bool, response_time: int) -> int:
    """
    Calculate score based on correctness and response time
    
    Linear decrease: 10초부터 1초당 -1점
    - 10초 이내: 150점 (100 + 50)
    - 20초: 140점 (100 + 40)
    - 30초: 130점 (100 + 30)
    - 40초: 120점 (100 + 20)
    - 40초 초과: 100점
    - 오답: 0점
    
    Args:
        is_correct: Whether the answer is correct
        response_time: Time taken to answer (seconds)
        
    Returns:
        Score earned
    """
    if not is_correct:
        return 0
    
    base_score = 100
    
    if response_time <= 10:
        bonus = 50
    elif response_time <= 40:
        bonus = 50 - (response_time - 10)
    else:
        bonus = 0
    
    return base_score + bonus


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
    Save questions to database
    
    Args:
        db: Database session
        questions: List of question dictionaries
        level: Difficulty level
        quiz_type: Quiz type
        created_by: Creator user ID
        
    Returns:
        List of created SlangQuizQuestion objects
    """
    created_questions = []
    
    for q in questions:
        question = SlangQuizQuestion(
            LEVEL=level,
            QUIZ_TYPE=quiz_type,
            WORD=q["word"],
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
    
    db.commit()
    
    for q in created_questions:
        db.refresh(q)
    
    return created_questions

