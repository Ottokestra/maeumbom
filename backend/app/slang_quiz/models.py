"""
Pydantic models for slang quiz game API
Request/Response validation models
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


# ============================================================================
# Enums
# ============================================================================

class QuizLevel(str, Enum):
    """Quiz difficulty level"""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class QuizType(str, Enum):
    """Quiz type"""
    WORD_TO_MEANING = "word_to_meaning"
    MEANING_TO_WORD = "meaning_to_word"


class RewardMood(str, Enum):
    """Reward card background mood"""
    WARM = "warm"
    CHEER = "cheer"
    COOL = "cool"


# ============================================================================
# Request Models
# ============================================================================

class StartGameRequest(BaseModel):
    """Request model for starting a new game"""
    level: QuizLevel = Field(..., description="Quiz difficulty level")
    quiz_type: QuizType = Field(..., description="Quiz type")
    
    class Config:
        json_schema_extra = {
            "example": {
                "level": "beginner",
                "quiz_type": "word_to_meaning"
            }
        }


class SubmitAnswerRequest(BaseModel):
    """Request model for submitting an answer"""
    question_number: int = Field(..., ge=1, le=5, description="Question number (1-5)")
    user_answer_index: int = Field(..., ge=-1, le=3, description="User's selected answer index (0-3, -1 for timeout)")
    response_time_seconds: int = Field(..., ge=0, description="Time taken to answer (seconds)")
    
    class Config:
        json_schema_extra = {
            "example": {
                "question_number": 1,
                "user_answer_index": 1,
                "response_time_seconds": 15
            }
        }


# ============================================================================
# Response Models
# ============================================================================

class RewardCard(BaseModel):
    """Reward card model"""
    message: str = Field(..., max_length=100, description="Reward message")
    background_mood: RewardMood = Field(..., description="Background mood")
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": "킹받는 일이 있어도 엄마는 네 편이야!",
                "background_mood": "warm"
            }
        }


class QuestionData(BaseModel):
    """Question data model (without answer)"""
    question_number: int = Field(..., description="Question number in the game")
    word: str = Field(..., description="Slang word")
    question: str = Field(..., description="Question text")
    options: List[str] = Field(..., min_length=4, max_length=4, description="Answer options (4)")
    time_limit: int = Field(default=20, description="Time limit in seconds")
    
    class Config:
        json_schema_extra = {
            "example": {
                "question_number": 1,
                "word": "킹받네",
                "question": "자녀가 '킹받네'라고 했다면 무슨 뜻일까요?",
                "options": ["기분이 좋다", "화가 난다", "배가 고프다", "졸리다"],
                "time_limit": 20
            }
        }


class StartGameResponse(BaseModel):
    """Response model for starting a game"""
    game_id: int = Field(..., description="Game session ID")
    total_questions: int = Field(default=5, description="Total number of questions")
    current_question: int = Field(default=1, description="Current question number")
    question: QuestionData = Field(..., description="First question data")
    
    class Config:
        json_schema_extra = {
            "example": {
                "game_id": 123,
                "total_questions": 5,
                "current_question": 1,
                "question": {
                    "question_number": 1,
                    "word": "킹받네",
                    "question": "자녀가 '킹받네'라고 했다면 무슨 뜻일까요?",
                    "options": ["기분이 좋다", "화가 난다", "배가 고프다", "졸리다"],
                    "time_limit": 20
                }
            }
        }


class QuestionResponse(BaseModel):
    """Response model for getting a question"""
    question_number: int = Field(..., description="Question number")
    word: str = Field(..., description="Slang word")
    question: str = Field(..., description="Question text")
    options: List[str] = Field(..., min_length=4, max_length=4, description="Answer options")
    time_limit: int = Field(default=20, description="Time limit in seconds")


class SubmitAnswerResponse(BaseModel):
    """Response model for submitting an answer"""
    is_correct: bool = Field(..., description="Whether the answer is correct")
    correct_answer_index: int = Field(..., description="Correct answer index")
    earned_score: int = Field(..., description="Score earned for this question")
    explanation: str = Field(..., description="Explanation text")
    reward_card: RewardCard = Field(..., description="Reward card")
    
    class Config:
        json_schema_extra = {
            "example": {
                "is_correct": True,
                "correct_answer_index": 1,
                "earned_score": 150,
                "explanation": "'킹받네'는 '열받네'를 강조한 표현이에요...",
                "reward_card": {
                    "message": "킹받는 일이 있어도 엄마는 네 편이야!",
                    "background_mood": "warm"
                }
            }
        }


class QuestionSummary(BaseModel):
    """Summary of a single question in the game"""
    question_number: int = Field(..., description="Question number")
    word: str = Field(..., description="Slang word")
    is_correct: Optional[bool] = Field(None, description="Whether answered correctly")
    earned_score: Optional[int] = Field(None, description="Score earned")


class EndGameResponse(BaseModel):
    """Response model for ending a game"""
    game_id: int = Field(..., description="Game session ID")
    total_questions: int = Field(..., description="Total number of questions")
    correct_count: int = Field(..., description="Number of correct answers")
    total_score: int = Field(..., description="Total score earned")
    total_time_seconds: Optional[int] = Field(None, description="Total time spent")
    questions_summary: List[QuestionSummary] = Field(..., description="Summary of all questions")
    
    class Config:
        json_schema_extra = {
            "example": {
                "game_id": 123,
                "total_questions": 5,
                "correct_count": 4,
                "total_score": 550,
                "total_time_seconds": 180,
                "questions_summary": [
                    {
                        "question_number": 1,
                        "word": "킹받네",
                        "is_correct": True,
                        "earned_score": 150
                    }
                ]
            }
        }


class GameHistory(BaseModel):
    """Game history item"""
    game_id: int = Field(..., description="Game session ID")
    level: str = Field(..., description="Difficulty level")
    quiz_type: str = Field(..., description="Quiz type")
    total_questions: int = Field(..., description="Total questions")
    correct_count: int = Field(..., description="Correct answers")
    total_score: int = Field(..., description="Total score")
    is_completed: bool = Field(..., description="Whether completed")
    created_at: datetime = Field(..., description="Game start time")


class HistoryResponse(BaseModel):
    """Response model for game history"""
    total: int = Field(..., description="Total number of games")
    games: List[GameHistory] = Field(..., description="List of games")


class Statistics(BaseModel):
    """Statistics model"""
    total_games: int = Field(..., description="Total number of games played")
    total_questions: int = Field(..., description="Total questions answered")
    correct_answers: int = Field(..., description="Total correct answers")
    accuracy_rate: float = Field(..., description="Overall accuracy rate (0-1)")
    total_score: int = Field(..., description="Total score earned")
    average_score: float = Field(..., description="Average score per game")
    best_score: int = Field(..., description="Best score in a single game")
    
    # By level
    beginner_accuracy: Optional[float] = Field(None, description="Beginner level accuracy")
    intermediate_accuracy: Optional[float] = Field(None, description="Intermediate level accuracy")
    advanced_accuracy: Optional[float] = Field(None, description="Advanced level accuracy")
    
    # By type
    word_to_meaning_accuracy: Optional[float] = Field(None, description="Word to meaning accuracy")
    meaning_to_word_accuracy: Optional[float] = Field(None, description="Meaning to word accuracy")


class StatisticsResponse(BaseModel):
    """Response model for statistics"""
    statistics: Statistics = Field(..., description="User statistics")


# ============================================================================
# Admin Models (for future use)
# ============================================================================

class GenerateQuestionsRequest(BaseModel):
    """Request model for generating questions (admin)"""
    level: QuizLevel = Field(..., description="Quiz difficulty level")
    quiz_type: QuizType = Field(..., description="Quiz type")
    count: int = Field(..., ge=1, le=50, description="Number of questions to generate")


class QuestionDetail(BaseModel):
    """Detailed question model (with answer)"""
    id: int = Field(..., description="Question ID")
    level: str = Field(..., description="Difficulty level")
    quiz_type: str = Field(..., description="Quiz type")
    word: str = Field(..., description="Slang word")
    question: str = Field(..., description="Question text")
    options: List[str] = Field(..., description="Answer options")
    answer_index: int = Field(..., description="Correct answer index")
    explanation: str = Field(..., description="Explanation")
    reward_message: str = Field(..., description="Reward message")
    reward_background_mood: str = Field(..., description="Reward background mood")
    is_active: bool = Field(..., description="Whether active")
    usage_count: int = Field(..., description="Usage count")
    created_at: datetime = Field(..., description="Creation time")

