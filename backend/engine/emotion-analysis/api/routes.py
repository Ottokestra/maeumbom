"""
API route handlers
"""
import sys
from pathlib import Path
from fastapi import APIRouter, HTTPException, Body, Depends

# 경로 설정
api_path = Path(__file__).parent
emotion_analysis_path = api_path.parent
backend_path = emotion_analysis_path.parent.parent

# sys.path에 경로 추가
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

# models import (절대 경로로)
import importlib.util
models_path = api_path / "models.py"
spec = importlib.util.spec_from_file_location("emotion_models", models_path)
emotion_models = importlib.util.module_from_spec(spec)
spec.loader.exec_module(emotion_models)
AnalyzeRequest = emotion_models.AnalyzeRequest
AnalyzeResponse = emotion_models.AnalyzeResponse
AnalyzeResponse17 = emotion_models.AnalyzeResponse17
HealthResponse = emotion_models.HealthResponse
InitResponse = emotion_models.InitResponse
ErrorResponse = emotion_models.ErrorResponse

# rag_pipeline import
rag_pipeline_path = emotion_analysis_path / "src" / "rag_pipeline.py"
spec = importlib.util.spec_from_file_location("rag_pipeline", rag_pipeline_path)
rag_pipeline_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rag_pipeline_module)
get_rag_pipeline = rag_pipeline_module.get_rag_pipeline

router = APIRouter()


@router.post("/analyze", response_model=AnalyzeResponse17)
async def analyze_emotion(request: AnalyzeRequest):
    """
    Analyze emotion in the provided text using 17 emotion clusters
    
    Args:
        request: AnalyzeRequest with text to analyze
        
    Returns:
        AnalyzeResponse17 with 17 emotion clusters analysis results
    """
    try:
        pipeline = get_rag_pipeline()
        result = pipeline.analyze_emotion(request.text)
        return AnalyzeResponse17(**result)
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error details: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")



# Import auth at module level to avoid issues
try:
    import sys as _sys
    from pathlib import Path as _Path
    _backend_path = _Path(__file__).parent.parent.parent.parent
    if str(_backend_path) not in _sys.path:
        _sys.path.insert(0, str(_backend_path))
    from app.auth.dependencies import get_current_user
    from app.db.models import User
except Exception as e:
    print(f"Warning: Could not import auth dependencies: {e}")
    get_current_user = None
    User = None


@router.post("/analyze-session")
async def analyze_session_emotion(
    session_id: str = Body(..., embed=True),
    current_user: User = Depends(get_current_user) if get_current_user else None
):
    """
    세션 기반 감정분석: 세션의 모든 사용자 메시지를 결합하여 분석
    
    Args:
        session_id: Session ID from request body
        current_user: Authenticated user
        
    Returns:
        AnalyzeResponse17 with emotion analysis results
    """
    try:
        # Get user_id from current_user
        if current_user is None:
            raise HTTPException(status_code=401, detail="Authentication required")
        
        user_id = current_user.ID if hasattr(current_user, 'ID') else current_user.id
        
        # Debug logging
        print(f"🔍 [Session Emotion] Querying session: user_id={user_id}, session_id={session_id}")
        
        # Import DB store
        import sys
        from pathlib import Path
        backend_path = Path(__file__).parent.parent.parent.parent
        if str(backend_path) not in sys.path:
            sys.path.insert(0, str(backend_path))
        
        from engine.langchain_agent.db_conversation_store import get_conversation_store
        
        store = get_conversation_store()
        messages = store.get_session_messages(
            user_id=user_id,
            session_id=session_id,  # Now using direct parameter
            role="user"
        )
        
        print(f"📝 [Session Emotion] Found {len(messages)} messages")
        if messages:
            print(f"📝 [Session Emotion] First message preview: {messages[0]['content'][:50]}...")
        
        if not messages:
            raise HTTPException(
                status_code=404, 
                detail=f"No user messages found in session: {session_id} for user {user_id}"
            )
        
        # Combine all messages
        combined_text = ". ".join([msg["content"] for msg in messages])
        
        # Analyze combined text
        pipeline = get_rag_pipeline()
        result = pipeline.analyze_emotion(combined_text)
        
        # Save to DB
        from sentence_transformers import SentenceTransformer
        import json
        
        embedder = SentenceTransformer('jhgan/ko-sroberta-multitask')
        embedding = embedder.encode(combined_text).tolist()
        embedding_json = json.dumps(embedding)
        
        analysis_id = store.save_emotion_analysis(
            user_id,
            combined_text,
            result,
            check_root="conversation",
            input_text_embedding=embedding_json
        )
        
        # Add analysis_id to result
        result_with_id = {**result, "analysis_id": analysis_id, "message_count": len(messages)}
        
        return AnalyzeResponse17(**result_with_id)
        
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error details: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Session analysis failed: {str(e)}")


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Check API health and readiness
    
    Returns:
        HealthResponse with status information
    """
    try:
        pipeline = get_rag_pipeline()
        status = pipeline.get_status()
        return HealthResponse(
            status="ok",
            vector_store_count=status['vector_store_count'],
            ready=status['ready']
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")


@router.post("/init", response_model=InitResponse)
async def initialize_system():
    """
    Initialize the vector store with emotion data
    
    Returns:
        InitResponse with initialization status
    """
    try:
        pipeline = get_rag_pipeline()
        result = pipeline.initialize_vector_store()
        
        if result['status'] == 'error':
            raise HTTPException(status_code=500, detail=result['message'])
        
        return InitResponse(**result)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Initialization failed: {str(e)}")

