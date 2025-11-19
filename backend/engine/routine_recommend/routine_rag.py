"""
RAG (Retrieval-Augmented Generation) 모듈
감정 분석 결과를 기반으로 ChromaDB에서 관련 루틴을 검색합니다.
"""
from pathlib import Path
from typing import List
from sentence_transformers import SentenceTransformer
import chromadb


from .models.schemas import EmotionAnalysisResult, RoutineCandidate
from engine.routine_recommend.models.schemas import (
    EmotionAnalysisResult,
    RoutineCandidate,
)
# 전역 초기화 (모듈 로드 시 한 번만 실행)
_script_path = Path(__file__).parent
_chroma_path = _script_path / "chroma" / "routines"

# 임베딩 모델 초기화
print("RAG 모듈: 임베딩 모델 로딩 중...")
_model = SentenceTransformer("jhgan/ko-sroberta-multitask")

# ChromaDB 클라이언트 초기화
_client = chromadb.PersistentClient(path=str(_chroma_path))
_collection = _client.get_or_create_collection("routine_kb")


def build_query_from_emotion(emotion: EmotionAnalysisResult) -> str:
    """
    감정 분석 결과로부터 검색 쿼리 텍스트를 생성합니다.
    
    Args:
        emotion: 감정 분석 결과
        
    Returns:
        검색 쿼리 텍스트 (한국어)
    """
    # 주요 감정 정보
    primary_name = emotion.primary_emotion.name_ko
    primary_code = emotion.primary_emotion.code
    
    # 보조 감정들 (상위 2개)
    secondary_names = [sec.name_ko for sec in emotion.secondary_emotions[:2]]
    
    # 전체 감정 극성
    sentiment = emotion.sentiment_overall
    sentiment_ko = {
        "positive": "긍정적인",
        "negative": "부정적인",
        "neutral": "중립적인"
    }.get(sentiment, sentiment)
    
    # 추천 태그
    recommended_tags = emotion.recommended_routine_tags
    
    # 쿼리 텍스트 구성
    query_parts = []
    
    # 감정 상태 설명
    if secondary_names:
        emotion_desc = f"{primary_name}과 {', '.join(secondary_names)}이(가) 섞인 {sentiment_ko} 상태"
    else:
        emotion_desc = f"{primary_name}이(가) 주된 {sentiment_ko} 상태"
    
    query_parts.append(emotion_desc)
    
    # 추천 태그 기반 요구사항
    tag_requirements = []
    tag_map = {
        "maintain_positive": "긍정을 유지하고",
        "gratitude": "감사",
        "social_activity": "사회적 활동",
        "light_walk": "가벼운 산책",
        "breathing": "호흡 운동",
        "journaling": "일기 쓰기",
        "meditation": "명상",
        "self_care": "자기 돌봄",
        "relaxation": "이완",
        "calm": "진정"
    }
    
    for tag in recommended_tags[:3]:  # 상위 3개 태그만 사용
        if tag in tag_map:
            tag_requirements.append(tag_map[tag])
    
    if tag_requirements:
        query_parts.append(f"{', '.join(tag_requirements)}을(를) 돕는")
    
    query_parts.append("가벼운 루틴을 추천해 주세요")
    
    query_text = " ".join(query_parts)
    
    return query_text


def retrieve_candidates(
    emotion: EmotionAnalysisResult,
    top_k: int = 10
) -> List[RoutineCandidate]:
    """
    감정 분석 결과를 기반으로 ChromaDB에서 관련 루틴 후보를 검색합니다.
    
    Args:
        emotion: 감정 분석 결과
        top_k: 반환할 후보 개수
        
    Returns:
        루틴 후보 리스트 (유사도 점수 포함)
    """
    # 1. 쿼리 텍스트 생성
    query_text = build_query_from_emotion(emotion)
    print(f"검색 쿼리: {query_text}")
    
    # 2. 쿼리 임베딩 생성
    query_emb = _model.encode([query_text], convert_to_numpy=True).tolist()
    
    # 3. ChromaDB 검색
    result = _collection.query(
        query_embeddings=query_emb,
        n_results=top_k,
    )
    
    # 4. 결과를 RoutineCandidate 리스트로 변환
    candidates: List[RoutineCandidate] = []
    
    if result["ids"] and len(result["ids"][0]) > 0:
        ids = result["ids"][0]
        documents = result["documents"][0]
        metadatas = result["metadatas"][0]
        distances = result["distances"][0] if "distances" in result else None
        
        for i, routine_id in enumerate(ids):
            metadata = metadatas[i] if i < len(metadatas) else {}
            document = documents[i] if i < len(documents) else ""
            
            # 거리를 점수로 변환 (거리가 작을수록 유사도가 높음)
            # 거리를 0~1 범위의 점수로 변환 (1에 가까울수록 유사)
            if distances is not None:
                # 거리를 점수로 변환: score = 1 / (1 + distance)
                # 또는 더 간단하게: score = max(0, 1 - distance)
                distance = distances[i]
                score = max(0.0, 1.0 - distance)  # 거리가 0이면 점수 1.0
            else:
                score = 1.0 - (i / len(ids))  # 순위 기반 점수
            
            # 문서에서 title과 description 추출
            # 문서 형식: "{title} - {description}"
            parts = document.split(" - ", 1)
            title = parts[0] if parts else routine_id
            description = parts[1] if len(parts) > 1 else ""
            
            candidate = RoutineCandidate(
                id=routine_id,
                title=title,
                description=description,
                group=metadata.get("group", ""),
                sub_group=metadata.get("sub_group", ""),
                tags=metadata.get("tags", "").split(",") if metadata.get("tags") else [],
                score=score
            )
            candidates.append(candidate)
    
    # 점수 내림차순 정렬 (높은 점수부터)
    candidates.sort(key=lambda x: x.score, reverse=True)
    
    return candidates

