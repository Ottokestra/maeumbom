"""
일일 이미지 선택 감정 분석 서비스 로직
"""
import random
import time
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime, date
import sys
from sqlalchemy.orm import Session
from sqlalchemy import and_

# emotion-analysis 엔진 import
backend_path = Path(__file__).parent.parent.parent
sys.path.insert(0, str(backend_path))

# 현재 디렉토리를 sys.path에 추가 (storage 모듈 import용)
current_dir = Path(__file__).parent
if str(current_dir) not in sys.path:
    sys.path.insert(0, str(current_dir))

try:
    # 하이픈이 있는 모듈명은 직접 경로로 import
    import importlib.util
    rag_pipeline_path = backend_path / "engine" / "emotion-analysis" / "src" / "rag_pipeline.py"
    spec = importlib.util.spec_from_file_location("rag_pipeline", rag_pipeline_path)
    rag_pipeline_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(rag_pipeline_module)
    get_rag_pipeline = rag_pipeline_module.get_rag_pipeline
    EMOTION_ANALYSIS_AVAILABLE = True
except Exception as e:
    print(f"Warning: Emotion analysis not available: {e}")
    EMOTION_ANALYSIS_AVAILABLE = False
    get_rag_pipeline = None


# 이미지 설명 매핑 (감정별 기본 설명)
SENTIMENT_DESCRIPTIONS = {
    "negative": [
        "우울하고 힘든 기분이에요",
        "오늘 기분이 좋지 않아요",
        "마음이 무겁고 힘들어요",
        "슬프고 우울한 하루예요",
        "걱정이 많고 불안해요"
    ],
    "neutral": [
        "그냥 평범한 하루예요",
        "특별한 일 없이 지나가는 하루예요",
        "평온하게 하루를 보내고 있어요",
        "오늘은 그냥 그런 하루예요",
        "감정이 중간쯤인 것 같아요"
    ],
    "positive": [
        "기분이 좋고 행복해요",
        "오늘 하루가 즐거워요",
        "마음이 편안하고 좋아요",
        "행복한 하루를 보내고 있어요",
        "기쁘고 즐거운 기분이에요"
    ]
}


def get_images_base_path() -> Path:
    """이미지 폴더 경로 반환"""
    return Path(__file__).parent / "images"


def list_images_in_folder(sentiment: str) -> List[str]:
    """특정 감정 폴더의 이미지 파일 목록 반환"""
    base_path = get_images_base_path()
    sentiment_folder = base_path / sentiment
    
    if not sentiment_folder.exists():
        return []
    
    # 이미지 파일 확장자
    image_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
    
    images = []
    for file in sentiment_folder.iterdir():
        if file.is_file() and file.suffix.lower() in image_extensions:
            images.append(file.name)
    
    return sorted(images)


def get_daily_random_images() -> List[Dict]:
    """
    날짜 기반으로 각 감정별 랜덤 이미지 선택
    
    Returns:
        각 감정별로 선택된 이미지 정보 리스트
    """
    # 테스트 모드 확인
    from storage import TEST_MODE
    
    if TEST_MODE:
        # 테스트 모드일 때: 매번 다른 이미지를 위해 현재 시간 기반 시드 사용
        random.seed(int(time.time() * 1000000))  # 마이크로초 단위로 시드 설정
    else:
        # 테스트 모드가 아닐 때: 날짜 기반 시드 사용 (같은 날에는 같은 이미지)
        today = date.today()
        seed = hash(today)
        random.seed(seed)
    
    result = []
    image_id = 1
    
    for sentiment in ["negative", "neutral", "positive"]:
        images = list_images_in_folder(sentiment)
        
        if not images:
            # 이미지가 없으면 기본 정보만 반환
            result.append({
                "id": image_id,
                "sentiment": sentiment,
                "filename": None,
                "description": SENTIMENT_DESCRIPTIONS[sentiment][0],
                "url": None
            })
        else:
            # 랜덤 선택
            selected_filename = random.choice(images)
            
            # 설명 선택 (파일명 기반으로 랜덤)
            descriptions = SENTIMENT_DESCRIPTIONS[sentiment]
            selected_description = random.choice(descriptions)
            
            result.append({
                "id": image_id,
                "sentiment": sentiment,
                "filename": selected_filename,
                "description": selected_description,
                "url": f"/api/service/daily-mood-check/images/{sentiment}/{selected_filename}"
            })
        
        image_id += 1
    
    # 이미지 순서를 랜덤으로 섞기 (날짜 기반 시드는 이미 설정되어 있음)
    random.shuffle(result)
    
    return result


def analyze_emotion_from_image(image_info: Dict) -> Optional[Dict]:
    """
    이미지 정보를 기반으로 감정 분석 수행
    
    Args:
        image_info: 이미지 정보 딕셔너리
        
    Returns:
        감정 분석 결과 또는 None
    """
    if not EMOTION_ANALYSIS_AVAILABLE or get_rag_pipeline is None:
        return None
    
    try:
        description = image_info.get("description", "")
        if not description:
            return None
        
        pipeline = get_rag_pipeline()
        result = pipeline.analyze_emotion(description)
        
        return result
    except Exception as e:
        print(f"Error in emotion analysis: {e}")
        return None


def get_image_by_id(image_id: int, daily_images: List[Dict]) -> Optional[Dict]:
    """이미지 ID로 이미지 정보 찾기"""
    for img in daily_images:
        if img.get("id") == image_id:
            return img
    return None


# ============================================================================
# Database functions for daily mood selections
# ============================================================================

def save_daily_selection(
    db: Session,
    user_id: int,
    image_id: int,
    sentiment: str,
    filename: str,
    description: Optional[str],
    emotion_result: Optional[Dict]
) -> None:
    """
    Save daily mood selection to database
    
    Args:
        db: Database session
        user_id: User ID
        image_id: Selected image ID
        sentiment: Sentiment classification
        filename: Image filename
        description: Image description
        emotion_result: Emotion analysis result
    """
    from app.auth.models import DailyMoodSelection
    
    today = date.today()
    
    # Check if user already selected today
    existing = db.query(DailyMoodSelection).filter(
        and_(
            DailyMoodSelection.USER_ID == user_id,
            DailyMoodSelection.SELECTED_DATE == today
        )
    ).first()
    
    if existing:
        # Update existing record
        existing.IMAGE_ID = image_id
        existing.SENTIMENT = sentiment
        existing.FILENAME = filename
        existing.DESCRIPTION = description
        existing.EMOTION_RESULT = emotion_result
    else:
        # Create new record
        selection = DailyMoodSelection(
            USER_ID=user_id,
            SELECTED_DATE=today,
            IMAGE_ID=image_id,
            SENTIMENT=sentiment,
            FILENAME=filename,
            DESCRIPTION=description,
            EMOTION_RESULT=emotion_result
        )
        db.add(selection)
    
    db.commit()


def get_user_daily_status(db: Session, user_id: int) -> Dict:
    """
    Get user's daily check status from database
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        Dictionary with status information
    """
    from app.auth.models import DailyMoodSelection
    
    today = date.today()
    
    selection = db.query(DailyMoodSelection).filter(
        and_(
            DailyMoodSelection.USER_ID == user_id,
            DailyMoodSelection.SELECTED_DATE == today
        )
    ).first()
    
    if selection:
        return {
            "user_id": user_id,
            "completed": True,
            "last_check_date": selection.SELECTED_DATE.isoformat(),
            "selected_image_id": selection.IMAGE_ID
        }
    else:
        return {
            "user_id": user_id,
            "completed": False,
            "last_check_date": None,
            "selected_image_id": None
        }


def is_user_checked_today(db: Session, user_id: int) -> bool:
    """
    Check if user has already selected an image today
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        True if user has checked today, False otherwise
    """
    from app.auth.models import DailyMoodSelection
    
    today = date.today()
    
    selection = db.query(DailyMoodSelection).filter(
        and_(
            DailyMoodSelection.USER_ID == user_id,
            DailyMoodSelection.SELECTED_DATE == today
        )
    ).first()
    
    return selection is not None

