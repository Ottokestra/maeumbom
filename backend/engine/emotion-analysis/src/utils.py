"""
Utility functions for emotion analysis
"""
from typing import Dict


def convert_va_to_ui_labels(valence: float, arousal: float) -> Dict[str, str]:
    """
    Convert Valence/Arousal values to UI-friendly labels
    
    Args:
        valence: Valence value (-1.0 ~ +1.0)
        arousal: Arousal value (-1.0 ~ +1.0)
        
    Returns:
        Dictionary with mood_direction and emotion_intensity
    """
    # valence → mood_direction 변환
    if valence > 0.2:
        mood_direction = "긍정"
    elif valence < -0.2:
        mood_direction = "부정"
    else:
        mood_direction = "중립"
    
    # arousal 절대값 → emotion_intensity 변환
    arousal_abs = abs(arousal)
    if arousal_abs >= 0.6:
        emotion_intensity = "높음"
    elif arousal_abs >= 0.3:
        emotion_intensity = "보통"
    else:
        emotion_intensity = "낮음"
    
    return {
        "mood_direction": mood_direction,
        "emotion_intensity": emotion_intensity
    }

