"""
Pydantic models for API request/response validation
"""
from pydantic import BaseModel, Field
from typing import Dict, List, Optional


class AnalyzeRequest(BaseModel):
    """Request model for emotion analysis"""
    text: str = Field(..., description="Text to analyze", min_length=1)


class SimilarContext(BaseModel):
    """Model for similar context information"""
    text: str
    emotion: str
    intensity: int
    similarity: float


class AnalyzeResponse(BaseModel):
    """Response model for emotion analysis"""
    input: str
    emotions: Dict[str, int] = Field(..., description="Top 3 emotion percentages (sum=100%)")
    primary_emotion: str = Field(..., description="Primary detected emotion")
    primary_percentage: int = Field(..., description="Primary emotion percentage")
    primary_intensity: int = Field(default=0, description="Deprecated: use primary_percentage")
    similar_contexts: List[SimilarContext] = Field(default_factory=list)


class HealthResponse(BaseModel):
    """Response model for health check"""
    status: str
    vector_store_count: int
    ready: bool


class InitResponse(BaseModel):
    """Response model for initialization"""
    status: str
    message: str
    document_count: int


class ErrorResponse(BaseModel):
    """Response model for errors"""
    error: str
    detail: Optional[str] = None

