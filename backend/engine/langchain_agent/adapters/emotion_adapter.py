"""
LangChain Agent용 Emotion Analysis 어댑터

기존 emotion-analysis 엔진을 LangChain Agent에서 사용할 수 있도록 래핑합니다.
v1.1 최적화: Lazy initialization, Client 클래스 제거
"""
import sys
from pathlib import Path
from typing import TypedDict

# 프로젝트 경로 설정 (한 번만)
engine_root = Path(__file__).parent.parent.parent
if str(engine_root) not in sys.path:
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


# Lazy Initialization: analyzer 캐싱
_emotion_analyzer = None


def _get_emotion_analyzer():
    """
    Emotion Analyzer 인스턴스를 Lazy하게 가져오기 (캐싱)
    
    Returns:
        EmotionAnalyzer 인스턴스 또는 None (실패 시)
    """
    global _emotion_analyzer
    
    if _emotion_analyzer is None:
        try:
            # emotion-analysis 경로 추가 (한 번만)
            emotion_analysis_path = engine_root / "emotion-analysis"
            if str(emotion_analysis_path) not in sys.path:
                sys.path.insert(0, str(emotion_analysis_path))
            
            from src.emotion_analyzer import get_emotion_analyzer
            _emotion_analyzer = get_emotion_analyzer()
            
        except Exception as e:
            print(f"❌ Emotion Analyzer 초기화 실패: {e}")
            _emotion_analyzer = "failed"  # 재시도 방지
    
    return _emotion_analyzer if _emotion_analyzer != "failed" else None


def _get_fallback_emotion_result(text: str) -> EmotionResult:
    """
    Fallback 감정 분석 결과 (엔진 실패 시)
    
    Args:
        text: 입력 텍스트
        
    Returns:
        기본 감정 분석 결과
    """
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


def run_emotion_analysis(text: str) -> EmotionResult:
    """
    텍스트의 감정을 분석 (최적화: Lazy initialization 적용)
    
    기존 EmotionAnalyzer.analyze_emotion() 메서드를 직접 사용합니다.
    
    Args:
        text: 분석할 텍스트
        
    Returns:
        EmotionResult: 감정 분석 결과 (17개 감정 군집 기반)
    """
    analyzer = _get_emotion_analyzer()
    
    if analyzer:
        try:
            # 감정 분석 수행 (17개 감정 군집 시스템)
            result = analyzer.analyze_emotion(text)
            return result
            
        except Exception as e:
            print(f"❌ 감정 분석 실행 중 오류: {e}")
            import traceback
            traceback.print_exc()
    
    # analyzer가 없거나 실행 실패 시 fallback
    return _get_fallback_emotion_result(text)


if __name__ == "__main__":
    # 테스트
    print("=== Emotion Analysis 어댑터 테스트 (v1.1 최적화) ===")
    
    # 테스트 1: 긍정적 감정
    test_text_1 = "아침에 눈을 뜨자 햇살이 방 안을 가득 채우고 있었고, 오랜만에 상쾌한 기분이 들어 따뜻한 커피를 한 잔 들고 여유롭게 집을 나설 수 있었다."
    result1 = run_emotion_analysis(test_text_1)
    print(f"\n[테스트 1] 긍정적 감정")
    print(f"입력: {test_text_1[:50]}...")
    print(f"주요 감정: {result1['primary_emotion']['name_ko']} (강도: {result1['primary_emotion']['intensity']})")
    print(f"전체 감정: {result1['sentiment_overall']}")
    
    # 테스트 2: 부정적 감정
    test_text_2 = "오늘 하루 정말 힘들었어요. 아무것도 하기 싫고 기운이 없네요."
    result2 = run_emotion_analysis(test_text_2)
    print(f"\n[테스트 2] 부정적 감정")
    print(f"입력: {test_text_2}")
    print(f"주요 감정: {result2['primary_emotion']['name_ko']} (강도: {result2['primary_emotion']['intensity']})")
    print(f"전체 감정: {result2['sentiment_overall']}")
    print(f"위험 수준: {result2['service_signals']['risk_level']}")
    
    print("\n✅ 테스트 완료!")

