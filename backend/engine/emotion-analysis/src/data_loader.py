"""
Data loading and preprocessing module
"""
import sys
from pathlib import Path
import json
from typing import List, Dict, Any
import pandas as pd

# 경로 설정 및 import
src_path = Path(__file__).parent
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

import importlib.util

# config import
config_path = src_path / "config.py"
spec = importlib.util.spec_from_file_location("config", config_path)
config_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config_module)
# 17개 감정 코드 사용
EMOTIONS = config_module.EMOTION_CODES_17


class EmotionDataLoader:
    """Load and preprocess emotion data"""
    
    def __init__(self, data_path: str = None):
        """
        Initialize data loader
        
        Args:
            data_path: Path to the emotion data JSON file (relative to emotion-analysis folder)
        """
        if data_path is None:
            # Default path relative to emotion-analysis folder
            emotion_analysis_root = Path(__file__).parent.parent
            data_path = emotion_analysis_root / "data" / "raw" / "sample_emotions.json"
        self.data_path = Path(data_path)
    
    def load_data(self) -> List[Dict[str, Any]]:
        """
        Load emotion data from JSON file
        
        Returns:
            List of emotion data dictionaries
        """
        if not self.data_path.exists():
            raise FileNotFoundError(f"Data file not found: {self.data_path}")
        
        with open(self.data_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Validate data
        validated_data = []
        for item in data:
            if self._validate_item(item):
                validated_data.append(item)
            else:
                print(f"Warning: Invalid item skipped: {item}")
        
        print(f"Loaded {len(validated_data)} emotion samples")
        return validated_data
    
    def _validate_item(self, item: Dict[str, Any]) -> bool:
        """
        Validate a single data item
        
        Args:
            item: Data item dictionary
            
        Returns:
            True if valid, False otherwise
        """
        required_keys = ['text', 'emotion', 'intensity']
        
        # Check required keys
        if not all(key in item for key in required_keys):
            return False
        
        # Check emotion is valid
        if item['emotion'] not in EMOTIONS:
            return False
        
        # Check intensity is in valid range
        if not isinstance(item['intensity'], int) or not (1 <= item['intensity'] <= 5):
            return False
        
        # Check text is not empty
        if not item['text'] or not isinstance(item['text'], str):
            return False
        
        return True
    
    def get_dataframe(self) -> pd.DataFrame:
        """
        Load data as pandas DataFrame
        
        Returns:
            DataFrame with emotion data
        """
        data = self.load_data()
        df = pd.DataFrame(data)
        return df
    
    def get_texts_by_emotion(self, emotion: str) -> List[str]:
        """
        Get all texts for a specific emotion
        
        Args:
            emotion: Emotion category
            
        Returns:
            List of text strings
        """
        data = self.load_data()
        texts = [item['text'] for item in data if item['emotion'] == emotion]
        return texts
    
    def get_emotion_distribution(self) -> Dict[str, int]:
        """
        Get distribution of emotions in the dataset
        
        Returns:
            Dictionary mapping emotion to count
        """
        data = self.load_data()
        distribution = {}
        for emotion in EMOTIONS:
            count = sum(1 for item in data if item['emotion'] == emotion)
            distribution[emotion] = count
        return distribution

