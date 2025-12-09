"""
API route handlers
"""
import sys
from pathlib import Path
from fastapi import APIRouter, HTTPException

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

