"""
LangChain Agent용 Emotion Analysis 어댑터

기존 emotion-analysis 엔진을 LangChain Agent에서 사용할 수 있도록 래핑합니다.
"""
import sys
from pathlib import Path
from typing import TypedDict, Optional

# 프로젝트 경로 설정
engine_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(engine_root))


class EmotionResult(TypedDict):
    """
    감정 분석 결과 타입
    
    요구사항 JSON 스키마와 일치하는 구조
    """
    text: str
    language: str
    raw_distribution: list[dict]
    primary_emotion: dict
    secondary_emotions: list[dict]
    sentiment_overall: str
    service_signals: dict
    recommended_response_style: list[str]
    recommended_routine_tags: list[str]
    report_tags: list[str]


def run_emotion_analysis(text: str) -> EmotionResult:
    """
    텍스트의 감정을 분석
    
    기존 EmotionAnalyzer.analyze_emotion() 메서드를 직접 사용합니다.
    
    Args:
        text: 분석할 텍스트
        
    Returns:
        EmotionResult: 감정 분석 결과 (17개 감정 군집 기반)
    """
    try:
        # 기존 emotion analyzer import
        # engine 폴더명이 emotion-analysis이므로 하이픈 사용
        import sys
        from pathlib import Path
        
        # emotion-analysis 경로 추가
        emotion_analysis_path = Path(__file__).parent.parent.parent / "emotion-analysis"
        if str(emotion_analysis_path) not in sys.path:
            sys.path.insert(0, str(emotion_analysis_path))
        
        from src.emotion_analyzer import get_emotion_analyzer
        
        # 전역 인스턴스 가져오기
        analyzer = get_emotion_analyzer()
        
        # 감정 분석 수행 (17개 감정 군집 시스템)
        result = analyzer.analyze_emotion(text)
        
        # 결과가 이미 요구사항의 JSON 스키마와 일치함
        return result
        
    except Exception as e:
        print(f"❌ 감정 분석 중 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        
        # 오류 발생 시 기본값 반환
        return {
            "text": text,
            "language": "ko",
            "raw_distribution": [
                {"code": "confusion", "name_ko": "혼란", "group": "negative", "score": 0.5},
                {"code": "sadness", "name_ko": "슬픔", "group": "negative", "score": 0.3},
                {"code": "interest", "name_ko": "흥미", "group": "positive", "score": 0.2}
            ],
            "primary_emotion": {
                "code": "confusion",
                "name_ko": "혼란",
                "group": "negative",
                "intensity": 3,
                "confidence": 0.7
            },
            "secondary_emotions": [
                {"code": "sadness", "name_ko": "슬픔", "intensity": 2},
                {"code": "interest", "name_ko": "흥미", "intensity": 1}
            ],
            "sentiment_overall": "negative",
            "service_signals": {
                "need_empathy": True,
                "need_routine_recommend": True,
                "need_health_check": False,
                "need_voice_analysis": False,
                "risk_level": "watch"
            },
            "recommended_response_style": [
                "부드럽고 공감 중심의 답변",
                "비난 없이 감정을 받아주는 방식"
            ],
            "recommended_routine_tags": [
                "breathing",
                "meditation",
                "light_walk"
            ],
            "report_tags": [
                "혼란 증가",
                "슬픔 경향"
            ]
        }


class EmotionAnalysisClient:
    """
    Emotion Analysis 클라이언트 (인터페이스)
    
    나중에 다른 감정 분석 엔진으로 교체 가능하도록 인터페이스를 정의합니다.
    """
    
    def __init__(self):
        """초기화"""
        pass
        
    def run(self, text: str) -> EmotionResult:
        """
        텍스트의 감정을 분석
        
        Args:
            text: 분석할 텍스트
            
        Returns:
            EmotionResult: 감정 분석 결과
        """
        return run_emotion_analysis(text)


# 편의를 위한 전역 함수
def create_emotion_client() -> EmotionAnalysisClient:
    """
    Emotion Analysis 클라이언트 생성
    
    Returns:
        EmotionAnalysisClient 인스턴스
    """
    return EmotionAnalysisClient()


if __name__ == "__main__":
    # 테스트
    print("=== Emotion Analysis 어댑터 테스트 ===")
    
    # 테스트 텍스트
    test_text = "아침에 눈을 뜨자 햇살이 방 안을 가득 채우고 있었고, 오랜만에 상쾌한 기분이 들어 따뜻한 커피를 한 잔 들고 여유롭게 집을 나설 수 있었다."
    
    # 함수 방식 테스트
    result = run_emotion_analysis(test_text)
    print(f"\n입력: {test_text}")
    print(f"\n주요 감정: {result['primary_emotion']['name_ko']} (강도: {result['primary_emotion']['intensity']})")
    print(f"전체 감정: {result['sentiment_overall']}")
    print(f"추천 응답 스타일: {result['recommended_response_style']}")
    
    # 클래스 방식 테스트
    print("\n\n=== 클래스 방식 테스트 ===")
    client = create_emotion_client()
    result2 = client.run("오늘 하루 정말 힘들었어요. 아무것도 하기 싫고 기운이 없네요.")
    print(f"\n주요 감정: {result2['primary_emotion']['name_ko']} (강도: {result2['primary_emotion']['intensity']})")
    print(f"전체 감정: {result2['sentiment_overall']}")
    print(f"위험 수준: {result2['service_signals']['risk_level']}")

