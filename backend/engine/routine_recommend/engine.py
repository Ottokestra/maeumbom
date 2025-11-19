"""
Routine Recommendation Engine (RAG + LLM)
감정 분석 결과를 기반으로 루틴을 추천하는 최종 엔진
"""
from typing import List
from .models.schemas import EmotionAnalysisResult, RoutineRecommendationItem
from .routine_rag import retrieve_candidates
from .llm_selector import select_and_explain_routines


class RoutineRecommendFromEmotionEngine:
    """
    감정 분석 결과를 기반으로 루틴을 추천하는 엔진
    
    프로세스:
    1. RAG를 사용하여 ChromaDB에서 관련 루틴 후보 검색
    2. LLM을 사용하여 최종 추천 루틴 선택 및 설명 생성
    """
    
    def __init__(self):
        """엔진 초기화"""
        pass
    
    def recommend(
        self,
        emotion: EmotionAnalysisResult
    ) -> List[RoutineRecommendationItem]:
        """
        감정 분석 결과를 기반으로 루틴을 추천합니다.
        
        Args:
            emotion: 감정 분석 결과
            
        Returns:
            추천된 루틴 리스트 (reason, ui_message 포함)
        """
        # 1) RAG로 후보 검색
        print("RAG 검색 중...")
        candidates = retrieve_candidates(emotion, top_k=10)
        print(f"후보 {len(candidates)}개 검색 완료")
        
        # 2) LLM으로 최종 선택 및 reason/ui_message 생성
        print("LLM으로 최종 추천 생성 중...")
        recommendations = select_and_explain_routines(
            emotion=emotion,
            candidates=candidates,
            max_recommend=3,
        )
        print(f"최종 추천 {len(recommendations)}개 생성 완료")
        
        return recommendations
