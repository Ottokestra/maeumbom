"""
LangChain Agent용 Routine Recommend 어댑터

기존 routine_recommend 엔진을 LangChain Agent에서 사용할 수 있도록 래핑합니다.
v1.1 최적화: Lazy initialization, Client 클래스 제거, Pydantic 자동 변환
"""
import sys
from pathlib import Path

# 프로젝트 경로 설정 (한 번만)
engine_root = Path(__file__).parent.parent.parent
if str(engine_root) not in sys.path:
    sys.path.insert(0, str(engine_root))


def run_routine_recommend(emotion_result: dict) -> list[dict]:
    """
    감정 분석 결과를 기반으로 루틴 추천 (최적화: Lazy initialization 적용)
    
    기존 RoutineRecommendFromEmotionEngine을 사용합니다.
    
    Args:
        emotion_result: 감정 분석 결과 (EmotionResult 형식)
        
    Returns:
        추천 루틴 리스트 [{"routine_id", "reason", "ui_message", ...}]
    """
    try:
        # Lazy import (필요 시점에만 로드)
        import asyncio
        from routine_recommend.engine import RoutineRecommendFromEmotionEngine
        from routine_recommend.models.schemas import EmotionAnalysisResult
        
        # Pydantic의 model_validate를 사용한 자동 변환 시도
        try:
            emotion_input = EmotionAnalysisResult.model_validate(emotion_result)
        except Exception:
            # 자동 변환 실패 시 수동 변환
            emotion_input = _convert_emotion_result_to_schema(emotion_result)
        
        # 루틴 추천 엔진 실행
        engine = RoutineRecommendFromEmotionEngine()
        
        # 비동기 메서드 실행을 위한 처리
        # 이미 실행 중인 이벤트 루프가 있는지 확인
        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                # 이미 루프가 실행 중이면 (FastAPI 등) create_task로 실행하고 기다려야 함
                # 하지만 여기는 동기 함수이므로, 비동기 래퍼가 필요함.
                # 임시방편: nest_asyncio를 사용하거나, 별도 스레드에서 실행
                # 가장 안전한 방법: 이 함수 자체를 async로 바꾸는 것이 좋지만, 
                # 호출 구조를 다 바꾸기 어려우므로 new_event_loop 사용 시도
                
                # 주의: FastAPI 내부에서 동기 함수가 호출될 때 asyncio.run()을 쓰면 에러 발생 가능
                # 여기서는 간단히 코루틴을 실행하는 헬퍼 사용
                import nest_asyncio
                nest_asyncio.apply()
                recommendations = loop.run_until_complete(engine.recommend(
                    emotion_input,
                    city="Seoul",  # 🌦️ Agent 테스트용 기본값
                    country="KR"
                ))
            else:
                recommendations = loop.run_until_complete(engine.recommend(
                    emotion_input,
                    city="Seoul",
                    country="KR"
                ))
        except RuntimeError:
            # 루프가 없으면 새로 생성
            recommendations = asyncio.run(engine.recommend(
                emotion_input,
                city="Seoul",
                country="KR"
            ))
        
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


def _convert_emotion_result_to_schema(emotion_result: dict) -> 'EmotionAnalysisResult':
    """
    EmotionResult를 EmotionAnalysisResult로 수동 변환 (Fallback)
    
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
    
    # 각 필드를 Pydantic 모델로 변환
    raw_distribution = [EmotionScore(**item) for item in emotion_result.get("raw_distribution", [])]
    primary_emotion = PrimaryEmotion(**emotion_result.get("primary_emotion", {}))
    secondary_emotions = [SecondaryEmotion(**item) for item in emotion_result.get("secondary_emotions", [])]
    service_signals = ServiceSignals(**emotion_result.get("service_signals", {}))
    
    # EmotionAnalysisResult 생성
    return EmotionAnalysisResult(
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


if __name__ == "__main__":
    # 테스트
    print("=== Routine Recommend 어댑터 테스트 (v1.1 최적화) ===")
    
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
    
    # 루틴 추천 테스트
    result = run_routine_recommend(dummy_emotion)
    print(f"\n추천 루틴 개수: {len(result)}")
    
    if result:
        for i, routine in enumerate(result, 1):
            print(f"\n{i}. {routine.get('title', 'N/A')}")
            print(f"   카테고리: {routine.get('category', 'N/A')}")
            print(f"   우선순위: {routine.get('priority', 'N/A')}")
            print(f"   이유: {routine.get('reason', 'N/A')}")
            print(f"   메시지: {routine.get('ui_message', 'N/A')}")
    else:
        print("추천된 루틴이 없습니다.")
    
    print("\n✅ 테스트 완료!")

