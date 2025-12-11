"""
API endpoints for slang quiz game
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.db.models import SlangQuizQuestion, SlangQuizGame, SlangQuizAnswer, User
from app.auth.dependencies import get_current_user

from .models import (
    StartGameRequest,
    StartGameResponse,
    QuestionResponse,
    SubmitAnswerRequest,
    SubmitAnswerResponse,
    EndGameResponse,
    HistoryResponse,
    GameHistory,
    StatisticsResponse,
    Statistics,
    QuestionData,
    RewardCard,
    QuestionSummary,
)
from .service import select_questions_for_user, calculate_score


router = APIRouter()


# ============================================================================
# Game Endpoints
# ============================================================================

@router.post("/start-game", response_model=StartGameResponse)
async def start_game(
    request: StartGameRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    게임 시작 (즉시 응답)
    
    사용자가 안 푼 문제 5개를 선택하여 게임 세션 생성
    
    Args:
        request: 게임 시작 요청 (level, quiz_type)
        db: Database session
        current_user: Current authenticated user
        
    Returns:
        StartGameResponse: 게임 ID 및 첫 번째 문제
    """
    try:
        # 1. Select 5 questions for user
        questions = select_questions_for_user(
            db=db,
            user_id=current_user.ID,  # User 모델의 ID 속성은 대문자
            level=request.level.value,
            quiz_type=request.quiz_type.value,
            count=5
        )
        
        if len(questions) < 5:
            raise HTTPException(
                status_code=404,
                detail=f"Not enough questions available. Found {len(questions)}/5"
            )
        
        # 2. Create game session
        game = SlangQuizGame(
            USER_ID=current_user.ID,  # User 모델의 ID 속성은 대문자
            LEVEL=request.level.value,
            QUIZ_TYPE=request.quiz_type.value,
            TOTAL_QUESTIONS=5,
            CORRECT_COUNT=0,
            TOTAL_SCORE=0,
            IS_COMPLETED=False,
            CREATED_BY=current_user.ID  # User 모델의 ID 속성은 대문자
        )
        db.add(game)
        db.commit()
        db.refresh(game)
        
        # 3. Create answer records for all 5 questions
        for idx, question in enumerate(questions, start=1):
            answer = SlangQuizAnswer(
                GAME_ID=game.ID,
                USER_ID=current_user.ID,  # User 모델의 ID 속성은 대문자
                QUESTION_ID=question.ID,
                QUESTION_NUMBER=idx,
                CREATED_BY=current_user.ID  # User 모델의 ID 속성은 대문자
            )
            db.add(answer)
            
            # Update usage count
            question.USAGE_COUNT += 1
        
        db.commit()
        
        # 4. Return first question
        first_question = questions[0]
        
        return StartGameResponse(
            game_id=game.ID,
            total_questions=5,
            current_question=1,
            question=QuestionData(
                question_number=1,
                word=first_question.WORD,
                question=first_question.QUESTION,
                options=first_question.OPTIONS,
                time_limit=40
            )
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to start game: {str(e)}")


@router.get("/games/{game_id}/questions/{question_number}", response_model=QuestionResponse)
async def get_question(
    game_id: int,
    question_number: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    특정 문제 조회
    
    Args:
        game_id: Game session ID
        question_number: Question number (1-5)
        db: Database session
        current_user: Current authenticated user
        
    Returns:
        QuestionResponse: Question data
    """
    try:
        # Verify game ownership
        game = db.query(SlangQuizGame).filter(
            SlangQuizGame.ID == game_id,
            SlangQuizGame.USER_ID == current_user.ID,
            SlangQuizGame.IS_DELETED == False
        ).first()
        
        if not game:
            raise HTTPException(status_code=404, detail="Game not found")
        
        # Get answer record (which contains question reference)
        answer = db.query(SlangQuizAnswer).filter(
            SlangQuizAnswer.GAME_ID == game_id,
            SlangQuizAnswer.QUESTION_NUMBER == question_number,
            SlangQuizAnswer.IS_DELETED == False
        ).first()
        
        if not answer:
            raise HTTPException(status_code=404, detail="Question not found")
        
        # Get question details
        question = db.query(SlangQuizQuestion).filter(
            SlangQuizQuestion.ID == answer.QUESTION_ID
        ).first()
        
        if not question:
            raise HTTPException(status_code=404, detail="Question data not found")
        
        return QuestionResponse(
            question_number=question_number,
            word=question.WORD,
            question=question.QUESTION,
            options=question.OPTIONS,
            time_limit=40
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get question: {str(e)}")


@router.post("/games/{game_id}/submit-answer", response_model=SubmitAnswerResponse)
async def submit_answer(
    game_id: int,
    request: SubmitAnswerRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    답안 제출 및 점수 계산
    
    Args:
        game_id: Game session ID
        request: Answer submission request
        db: Database session
        current_user: Current authenticated user
        
    Returns:
        SubmitAnswerResponse: Result with score and explanation
    """
    try:
        # Verify game ownership
        game = db.query(SlangQuizGame).filter(
            SlangQuizGame.ID == game_id,
            SlangQuizGame.USER_ID == current_user.ID,
            SlangQuizGame.IS_DELETED == False
        ).first()
        
        if not game:
            raise HTTPException(status_code=404, detail="Game not found")
        
        # Get answer record
        answer = db.query(SlangQuizAnswer).filter(
            SlangQuizAnswer.GAME_ID == game_id,
            SlangQuizAnswer.QUESTION_NUMBER == request.question_number,
            SlangQuizAnswer.IS_DELETED == False
        ).first()
        
        if not answer:
            raise HTTPException(status_code=404, detail="Answer record not found")
        
        # Check if already answered
        if answer.USER_ANSWER_INDEX is not None:
            raise HTTPException(status_code=400, detail="Question already answered")
        
        # Get question details
        question = db.query(SlangQuizQuestion).filter(
            SlangQuizQuestion.ID == answer.QUESTION_ID
        ).first()
        
        if not question:
            raise HTTPException(status_code=404, detail="Question not found")
        
        # Calculate correctness and score
        is_correct = (request.user_answer_index == question.ANSWER_INDEX)
        earned_score = calculate_score(is_correct, request.response_time_seconds)
        
        # Update answer record
        answer.USER_ANSWER_INDEX = request.user_answer_index
        answer.IS_CORRECT = is_correct
        answer.RESPONSE_TIME_SECONDS = request.response_time_seconds
        answer.EARNED_SCORE = earned_score
        answer.UPDATED_BY = current_user.ID
        
        # Update game statistics
        if is_correct:
            game.CORRECT_COUNT += 1
        game.TOTAL_SCORE += earned_score
        game.UPDATED_BY = current_user.ID
        
        db.commit()
        
        return SubmitAnswerResponse(
            is_correct=is_correct,
            correct_answer_index=question.ANSWER_INDEX,
            earned_score=earned_score,
            explanation=question.EXPLANATION,
            reward_card=RewardCard(
                message=question.REWARD_MESSAGE,
                background_mood=question.REWARD_BACKGROUND_MOOD
            )
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to submit answer: {str(e)}")


@router.post("/games/{game_id}/end", response_model=EndGameResponse)
async def end_game(
    game_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    게임 종료 및 결과 조회
    
    Args:
        game_id: Game session ID
        db: Database session
        current_user: Current authenticated user
        
    Returns:
        EndGameResponse: Game result summary
    """
    try:
        # Verify game ownership
        game = db.query(SlangQuizGame).filter(
            SlangQuizGame.ID == game_id,
            SlangQuizGame.USER_ID == current_user.ID,
            SlangQuizGame.IS_DELETED == False
        ).first()
        
        if not game:
            raise HTTPException(status_code=404, detail="Game not found")
        
        # Get all answers
        answers = db.query(SlangQuizAnswer).join(
            SlangQuizQuestion,
            SlangQuizAnswer.QUESTION_ID == SlangQuizQuestion.ID
        ).filter(
            SlangQuizAnswer.GAME_ID == game_id,
            SlangQuizAnswer.IS_DELETED == False
        ).order_by(SlangQuizAnswer.QUESTION_NUMBER).all()
        
        # Recalculate totals from answers (ensure consistency)
        total_time = sum(
            a.RESPONSE_TIME_SECONDS for a in answers 
            if a.RESPONSE_TIME_SECONDS is not None
        )
        
        correct_count = sum(1 for a in answers if a.IS_CORRECT is True)
        total_score = sum(
            a.EARNED_SCORE for a in answers 
            if a.EARNED_SCORE is not None
        )
        
        # Update game with recalculated values
        game.IS_COMPLETED = True
        game.TOTAL_TIME_SECONDS = total_time
        game.CORRECT_COUNT = correct_count
        game.TOTAL_SCORE = total_score
        game.UPDATED_BY = current_user.ID
        db.commit()
        
        # Build questions summary
        questions_summary = []
        for answer in answers:
            question = db.query(SlangQuizQuestion).filter(
                SlangQuizQuestion.ID == answer.QUESTION_ID
            ).first()
            
            questions_summary.append(QuestionSummary(
                question_number=answer.QUESTION_NUMBER,
                word=question.WORD if question else "",
                is_correct=answer.IS_CORRECT,
                earned_score=answer.EARNED_SCORE
            ))
        
        return EndGameResponse(
            game_id=game.ID,
            total_questions=game.TOTAL_QUESTIONS,
            correct_count=game.CORRECT_COUNT,
            total_score=game.TOTAL_SCORE,
            total_time_seconds=game.TOTAL_TIME_SECONDS,
            questions_summary=questions_summary
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to end game: {str(e)}")


@router.get("/history", response_model=HistoryResponse)
async def get_history(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    게임 히스토리 조회
    
    Args:
        limit: Maximum number of games to return
        offset: Offset for pagination
        db: Database session
        current_user: Current authenticated user
        
    Returns:
        HistoryResponse: List of game history
    """
    try:
        # Get total count
        total = db.query(SlangQuizGame).filter(
            SlangQuizGame.USER_ID == current_user.ID,
            SlangQuizGame.IS_DELETED == False
        ).count()
        
        # Get games
        games = db.query(SlangQuizGame).filter(
            SlangQuizGame.USER_ID == current_user.ID,
            SlangQuizGame.IS_DELETED == False
        ).order_by(SlangQuizGame.CREATED_AT.desc()).offset(offset).limit(limit).all()
        
        game_history_list = [
            GameHistory(
                game_id=game.ID,
                level=game.LEVEL,
                quiz_type=game.QUIZ_TYPE,
                total_questions=game.TOTAL_QUESTIONS,
                correct_count=game.CORRECT_COUNT,
                total_score=game.TOTAL_SCORE,
                is_completed=game.IS_COMPLETED,
                created_at=game.CREATED_AT
            )
            for game in games
        ]
        
        return HistoryResponse(
            total=total,
            games=game_history_list
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get history: {str(e)}")


@router.get("/statistics", response_model=StatisticsResponse)
async def get_statistics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    통계 조회
    
    Args:
        db: Database session
        current_user: Current authenticated user
        
    Returns:
        StatisticsResponse: User statistics
    """
    try:
        # Get all completed games
        games = db.query(SlangQuizGame).filter(
            SlangQuizGame.USER_ID == current_user.ID,
            SlangQuizGame.IS_COMPLETED == True,
            SlangQuizGame.IS_DELETED == False
        ).all()
        
        if not games:
            return StatisticsResponse(
                statistics=Statistics(
                    total_games=0,
                    total_questions=0,
                    correct_answers=0,
                    accuracy_rate=0.0,
                    total_score=0,
                    average_score=0.0,
                    best_score=0
                )
            )
        
        # Calculate overall statistics
        total_games = len(games)
        total_questions = sum(g.TOTAL_QUESTIONS for g in games)
        correct_answers = sum(g.CORRECT_COUNT for g in games)
        accuracy_rate = correct_answers / total_questions if total_questions > 0 else 0.0
        total_score = sum(g.TOTAL_SCORE for g in games)
        average_score = total_score / total_games if total_games > 0 else 0.0
        best_score = max(g.TOTAL_SCORE for g in games) if games else 0
        
        # Calculate by level
        beginner_games = [g for g in games if g.LEVEL == "beginner"]
        intermediate_games = [g for g in games if g.LEVEL == "intermediate"]
        advanced_games = [g for g in games if g.LEVEL == "advanced"]
        
        def calc_accuracy(game_list):
            if not game_list:
                return None
            total_q = sum(g.TOTAL_QUESTIONS for g in game_list)
            correct_q = sum(g.CORRECT_COUNT for g in game_list)
            return correct_q / total_q if total_q > 0 else 0.0
        
        beginner_accuracy = calc_accuracy(beginner_games)
        intermediate_accuracy = calc_accuracy(intermediate_games)
        advanced_accuracy = calc_accuracy(advanced_games)
        
        # Calculate by type
        word_to_meaning_games = [g for g in games if g.QUIZ_TYPE == "word_to_meaning"]
        meaning_to_word_games = [g for g in games if g.QUIZ_TYPE == "meaning_to_word"]
        
        word_to_meaning_accuracy = calc_accuracy(word_to_meaning_games)
        meaning_to_word_accuracy = calc_accuracy(meaning_to_word_games)
        
        return StatisticsResponse(
            statistics=Statistics(
                total_games=total_games,
                total_questions=total_questions,
                correct_answers=correct_answers,
                accuracy_rate=accuracy_rate,
                total_score=total_score,
                average_score=average_score,
                best_score=best_score,
                beginner_accuracy=beginner_accuracy,
                intermediate_accuracy=intermediate_accuracy,
                advanced_accuracy=advanced_accuracy,
                word_to_meaning_accuracy=word_to_meaning_accuracy,
                meaning_to_word_accuracy=meaning_to_word_accuracy
            )
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get statistics: {str(e)}")


@router.delete("/games/{game_id}")
async def delete_game(
    game_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    게임 삭제 (Soft Delete)
    
    Args:
        game_id: Game session ID
        db: Database session
        current_user: Current authenticated user
        
    Returns:
        Success message
    """
    try:
        # Verify game ownership
        game = db.query(SlangQuizGame).filter(
            SlangQuizGame.ID == game_id,
            SlangQuizGame.USER_ID == current_user.ID,
            SlangQuizGame.IS_DELETED == False
        ).first()
        
        if not game:
            raise HTTPException(status_code=404, detail="Game not found")
        
        # Soft delete game
        game.IS_DELETED = True
        game.UPDATED_BY = current_user.ID
        
        # Soft delete all answers
        answers = db.query(SlangQuizAnswer).filter(
            SlangQuizAnswer.GAME_ID == game_id,
            SlangQuizAnswer.IS_DELETED == False
        ).all()
        
        for answer in answers:
            answer.IS_DELETED = True
            answer.UPDATED_BY = current_user.ID
        
        db.commit()
        
        return {
            "success": True,
            "message": f"Game {game_id} deleted successfully",
            "game_id": game_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete game: {str(e)}")


# ============================================================================
# Admin Endpoints (for future use)
# ============================================================================

@router.post("/admin/questions/generate")
async def generate_questions_admin(
    level: str = Query(..., description="Difficulty level"),
    quiz_type: str = Query(..., description="Quiz type"),
    count: int = Query(default=10, ge=1, le=50, description="Number of questions"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    관리자용 문제 생성 API (나중에 사용)
    
    Args:
        level: Difficulty level
        quiz_type: Quiz type
        count: Number of questions to generate
        db: Database session
        current_user: Current authenticated user
        
    Returns:
        Generation result
    """
    try:
        # TODO: Add admin permission check
        # if not current_user.is_admin:
        #     raise HTTPException(status_code=403, detail="Admin permission required")
        
        from .service import generate_quiz_with_openai, save_questions_to_db, save_questions_to_json
        
        # Get existing words from DB to avoid duplicates
        existing_questions = db.query(SlangQuizQuestion).filter(
            SlangQuizQuestion.LEVEL == level,
            SlangQuizQuestion.QUIZ_TYPE == quiz_type,
            SlangQuizQuestion.IS_DELETED == False
        ).all()
        
        exclude_words = [q.WORD for q in existing_questions]
        
        # Generate questions
        questions = await generate_quiz_with_openai(
            level=level,
            quiz_type=quiz_type,
            count=count,
            exclude_words=exclude_words
        )
        
        # Save to DB
        db_questions = save_questions_to_db(
            db=db,
            questions=questions,
            level=level,
            quiz_type=quiz_type,
            created_by=current_user.ID  # User 모델의 ID 속성은 대문자
        )
        
        # Save to JSON (backup)
        save_questions_to_json(
            questions=questions,
            level=level,
            quiz_type=quiz_type
        )
        
        return {
            "success": True,
            "message": f"Generated {len(questions)} questions",
            "count": len(questions),
            "level": level,
            "quiz_type": quiz_type
        }
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to generate questions: {str(e)}")


# ============================================================================
# Health Check
# ============================================================================

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "slang-quiz"
    }

