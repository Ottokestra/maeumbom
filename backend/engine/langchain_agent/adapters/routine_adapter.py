"""
LangChain Agent용 Routine Recommend 어댑터

기존 routine_recommend 엔진을 LangChain Agent에서 사용할 수 있도록 래핑합니다.
"""
import sys
from pathlib import Path
from typing import Optional

# 프로젝트 경로 설정
engine_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(engine_root))


def run_routine_recommend(emotion_result: dict) -> list[dict]:
    """
    감정 분석 결과를 기반으로 루틴 추천
    
    기존 RoutineRecommendFromEmotionEngine을 사용합니다.
    
    Args:
        emotion_result: 감정 분석 결과 (EmotionResult 형식)
        
    Returns:
        추천 루틴 리스트 [{"routine_id", "reason", "ui_message", ...}]
    """
    try:
        # routine_recommend 엔진 import
        from routine_recommend.engine import RoutineRecommendFromEmotionEngine
        from routine_recommend.models.schemas import EmotionAnalysisResult
        
        # EmotionResult를 EmotionAnalysisResult로 변환
        emotion_input = convert_emotion_result_to_schema(emotion_result)
        
        # 루틴 추천 엔진 실행
        engine = RoutineRecommendFromEmotionEngine()
        recommendations = engine.recommend(emotion_input)
        
        # Pydantic 모델을 dict로 변환
        result = [rec.model_dump() for rec in recommendations]
        
        print(f"✅ 루틴 추천 완료: {len(result)}개")
        return result
        
    except Exception as e:
        print(f"❌ 루틴 추천 중 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        
        # 오류 발생 시 빈 리스트 반환 (graceful degradation)
        return []


def convert_emotion_result_to_schema(emotion_result: dict) -> 'EmotionAnalysisResult':
    """
    EmotionResult (emotion-analysis 출력)를 EmotionAnalysisResult (routine-recommend 입력)로 변환
    
    Args:
        emotion_result: emotion-analysis의 출력 형식
        
    Returns:
        EmotionAnalysisResult: routine-recommend의 입력 형식
    """
    from routine_recommend.models.schemas import (
        EmotionAnalysisResult,
        EmotionScore,
        PrimaryEmotion,
        SecondaryEmotion,
        ServiceSignals
    )
    
    # raw_distribution 변환
    raw_distribution = [
        EmotionScore(**item) for item in emotion_result.get("raw_distribution", [])
    ]
    
    # primary_emotion 변환
    primary_data = emotion_result.get("primary_emotion", {})
    primary_emotion = PrimaryEmotion(**primary_data)
    
    # secondary_emotions 변환
    secondary_emotions = [
        SecondaryEmotion(**item) for item in emotion_result.get("secondary_emotions", [])
    ]
    
    # service_signals 변환
    signals_data = emotion_result.get("service_signals", {})
    service_signals = ServiceSignals(**signals_data)
    
    # EmotionAnalysisResult 생성
    emotion_analysis = EmotionAnalysisResult(
        text=emotion_result.get("text", ""),
        language=emotion_result.get("language", "ko"),
        raw_distribution=raw_distribution,
        primary_emotion=primary_emotion,
        secondary_emotions=secondary_emotions,
        sentiment_overall=emotion_result.get("sentiment_overall", "neutral"),
        service_signals=service_signals,
        recommended_response_style=emotion_result.get("recommended_response_style", []),
        recommended_routine_tags=emotion_result.get("recommended_routine_tags", []),
        report_tags=emotion_result.get("report_tags", [])
    )
    
    return emotion_analysis


class RoutineRecommendClient:
    """
    Routine Recommend 클라이언트 (인터페이스)
    
    나중에 다른 루틴 추천 엔진으로 교체 가능하도록 인터페이스를 정의합니다.
    """
    
    def __init__(self):
        """초기화"""
        pass
        
    def run(self, emotion_result: dict) -> list[dict]:
        """
        감정 분석 결과를 기반으로 루틴 추천
        
        Args:
            emotion_result: 감정 분석 결과
            
        Returns:
            추천 루틴 리스트
        """
        return run_routine_recommend(emotion_result)


# 편의를 위한 전역 함수
def create_routine_client() -> RoutineRecommendClient:
    """
    Routine Recommend 클라이언트 생성
    
    Returns:
        RoutineRecommendClient 인스턴스
    """
    return RoutineRecommendClient()


if __name__ == "__main__":
    # 테스트
    print("=== Routine Recommend 어댑터 테스트 ===")
    
    # 더미 감정 분석 결과
    dummy_emotion = {
        "text": "오늘 하루 정말 힘들었어요",
        "language": "ko",
        "raw_distribution": [
            {"code": "sadness", "name_ko": "슬픔", "group": "negative", "score": 0.4},
            {"code": "depression", "name_ko": "우울", "group": "negative", "score": 0.3},
        ],
        "primary_emotion": {
            "code": "sadness",
            "name_ko": "슬픔",
            "group": "negative",
            "intensity": 4,
            "confidence": 0.85
        },
        "secondary_emotions": [
            {"code": "depression", "name_ko": "우울", "intensity": 3}
        ],
        "sentiment_overall": "negative",
        "service_signals": {
            "need_empathy": True,
            "need_routine_recommend": True,
            "need_health_check": False,
            "need_voice_analysis": False,
            "risk_level": "watch"
        },
        "recommended_response_style": ["부드럽고 공감 중심의 답변"],
        "recommended_routine_tags": ["breathing", "light_walk"],
        "report_tags": ["슬픔 증가"]
    }
    
    # 함수 방식 테스트
    result = run_routine_recommend(dummy_emotion)
    print(f"\n추천 루틴 개수: {len(result)}")
    for i, routine in enumerate(result, 1):
        print(f"\n{i}. {routine.get('routine_name', 'N/A')}")
        print(f"   이유: {routine.get('reason', 'N/A')}")
        print(f"   메시지: {routine.get('ui_message', 'N/A')}")

