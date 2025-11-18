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

# 논문 기반 감정 군집 정의 (Valence/Arousal 차원)
# Russell & Mehrabian (1977) 이론 기반
# Valence: -1.0 (불쾌) ~ +1.0 (쾌)
# Arousal: -1.0 (저각성/안정) ~ +1.0 (고각성/흥분)

# Polarity 경계값 (valence 기준)
VALENCE_THRESHOLD = 0.2  # ±0.2 범위는 neutral로 분류

# 감정 군집 정의
EMOTION_CLUSTERS = [
    # 긍정 군집
    {
        "id": 1,
        "label": "안심/평온",
        "valence": 0.6,
        "arousal": -0.4,
        "polarity": "positive",
        "related_emotions": ["calmness"]
    },
    {
        "id": 2,
        "label": "흥미/관심",
        "valence": 0.7,
        "arousal": 0.5,
        "polarity": "positive",
        "related_emotions": ["joy"]
    },
    {
        "id": 3,
        "label": "애틋/그리움",
        "valence": 0.3,
        "arousal": 0.2,
        "polarity": "positive",
        "related_emotions": ["loneliness"]  # 긍정적 그리움
    },
    
    # 부정 군집
    {
        "id": 4,
        "label": "불만",
        "valence": -0.5,
        "arousal": 0.3,
        "polarity": "negative",
        "related_emotions": ["frustration"]
    },
    {
        "id": 5,
        "label": "수치",
        "valence": -0.6,
        "arousal": 0.4,
        "polarity": "negative",
        "related_emotions": ["guilt"]
    },
    {
        "id": 6,
        "label": "슬픔/비애",
        "valence": -0.7,
        "arousal": -0.3,
        "polarity": "negative",
        "related_emotions": ["sadness"]
    },
    {
        "id": 7,
        "label": "분노",
        "valence": -0.8,
        "arousal": 0.8,
        "polarity": "negative",
        "related_emotions": ["anger"]
    },
    {
        "id": 8,
        "label": "불안/공포",
        "valence": -0.6,
        "arousal": 0.7,
        "polarity": "negative",
        "related_emotions": ["anxiety"]
    },
    {
        "id": 9,
        "label": "피로/무기력",
        "valence": -0.4,
        "arousal": -0.6,
        "polarity": "negative",
        "related_emotions": ["fatigue"]
    },
    {
        "id": 10,
        "label": "혼란",
        "valence": -0.3,
        "arousal": 0.5,
        "polarity": "negative",
        "related_emotions": ["confusion"]
    }
]

# 기존 감정 카테고리와 군집 매핑 (하위 호환성)
EMOTION_TO_CLUSTER_MAP = {
    "joy": 2,
    "calmness": 1,
    "sadness": 6,
    "anger": 7,
    "anxiety": 8,
    "loneliness": 3,  # 긍정적 그리움으로 분류
    "fatigue": 9,
    "confusion": 10,
    "guilt": 5,
    "frustration": 4
}

# 17개 감정 군집 정의 (갱년기 여성 대상 감정 분석 시스템)
EMOTION_CLUSTERS_17 = [
    # 긍정 그룹 (positive)
    {"code": "joy", "name_ko": "기쁨", "group": "positive"},
    {"code": "excitement", "name_ko": "흥분", "group": "positive"},
    {"code": "confidence", "name_ko": "자신감", "group": "positive"},
    {"code": "love", "name_ko": "사랑", "group": "positive"},
    {"code": "relief", "name_ko": "안심", "group": "positive"},
    {"code": "enlightenment", "name_ko": "깨달음", "group": "positive"},
    {"code": "interest", "name_ko": "흥미", "group": "positive"},
    
    # 부정 그룹 (negative)
    {"code": "discontent", "name_ko": "불만", "group": "negative"},
    {"code": "shame", "name_ko": "수치", "group": "negative"},
    {"code": "sadness", "name_ko": "슬픔", "group": "negative"},
    {"code": "guilt", "name_ko": "죄책감", "group": "negative"},
    {"code": "depression", "name_ko": "우울", "group": "negative"},
    {"code": "boredom", "name_ko": "무료", "group": "negative"},
    {"code": "contempt", "name_ko": "경멸", "group": "negative"},
    {"code": "anger", "name_ko": "화", "group": "negative"},
    {"code": "fear", "name_ko": "공포", "group": "negative"},
    {"code": "confusion", "name_ko": "혼란", "group": "negative"},
]

# 감정 코드 리스트 (17개)
EMOTION_CODES_17 = [emotion["code"] for emotion in EMOTION_CLUSTERS_17]

# 감정 코드 → 한국어 이름 매핑
EMOTION_CODE_TO_NAME_KO = {emotion["code"]: emotion["name_ko"] for emotion in EMOTION_CLUSTERS_17}

# 감정 코드 → 그룹 매핑
EMOTION_CODE_TO_GROUP = {emotion["code"]: emotion["group"] for emotion in EMOTION_CLUSTERS_17}

# Intensity 매핑 규칙 (score → intensity)
INTENSITY_MAPPING = [
    (0.70, 5),   # score >= 0.70 → intensity = 5 (매우 강함)
    (0.45, 4),   # 0.45 <= score < 0.70 → intensity = 4 (강함)
    (0.25, 3),   # 0.25 <= score < 0.45 → intensity = 3 (중간)
    (0.10, 2),   # 0.10 <= score < 0.25 → intensity = 2 (약함)
    (0.00, 1),   # score < 0.10 → intensity = 1 (매우 약함)
]

# Sentiment overall 경계값
SENTIMENT_DELTA_THRESHOLD = 0.2

