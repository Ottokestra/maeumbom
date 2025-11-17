"""
Configuration settings for the emotion analysis RAG system
"""
import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from project root .env file
project_root = Path(__file__).parent.parent.parent.parent  # backend/
env_path = project_root / ".env"
load_dotenv(dotenv_path=env_path)

# Emotion categories
EMOTIONS = [
    "joy",        # 기쁨
    "calmness",   # 평온
    "sadness",    # 슬픔
    "anger",      # 분노
    "anxiety",    # 불안
    "loneliness", # 외로움
    "fatigue",    # 피로
    "confusion",  # 혼란
    "guilt",      # 죄책감
    "frustration" # 좌절
]

EMOTION_LABELS_KR = {
    "joy": "기쁨",
    "calmness": "평온",
    "sadness": "슬픔",
    "anger": "분노",
    "anxiety": "불안",
    "loneliness": "외로움",
    "fatigue": "피로",
    "confusion": "혼란",
    "guilt": "죄책감",
    "frustration": "좌절"
}

# Model settings
EMBEDDING_MODEL = "jhgan/ko-sroberta-multitask"
LLM_MODEL = "gpt-4o-mini"  # LLM for emotion analysis (OpenAI API)

# OpenAI API settings
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError(
        "OPENAI_API_KEY environment variable is not set. "
        "Please set it in your .env file or environment variables."
    )

# Vector DB settings
# Path relative to emotion-analysis folder
emotion_analysis_root = Path(__file__).parent.parent  # engine/emotion-analysis/
VECTORDB_PATH = str(emotion_analysis_root / "vectordb")
COLLECTION_NAME = "emotion_contexts"
TOP_K_RESULTS = 5

# Intensity scale
MIN_INTENSITY = 1
MAX_INTENSITY = 5

