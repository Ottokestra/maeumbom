"""
루틴 벡터 DB 구축 스크립트
ChromaDB에 루틴 카탈로그를 임베딩하여 저장합니다.
"""
from pathlib import Path
from sentence_transformers import SentenceTransformer
import chromadb
from typing import List

# routine_catalog에서 루틴 데이터 import
from .routine_catalog import ALL_ROUTINES


def build_routine_vector_db():
    """
    루틴 카탈로그를 ChromaDB에 임베딩하여 저장합니다.
    """
    # 1. 임베딩 모델 초기화
    print("임베딩 모델 로딩 중...")
    model = SentenceTransformer("jhgan/ko-sroberta-multitask")
    
    # 2. ChromaDB 클라이언트 초기화
    # backend/engine/routine_recommend/chroma/routines 경로에 저장
    script_path = Path(__file__).parent
    chroma_path = script_path / "chroma" / "routines"
    chroma_path.mkdir(parents=True, exist_ok=True)
    
    print(f"ChromaDB 경로: {chroma_path}")
    client = chromadb.PersistentClient(path=str(chroma_path))
    
    # 3. 컬렉션 가져오기 또는 생성
    collection_name = "routine_kb"
    
    # 기존 컬렉션이 있으면 삭제하고 새로 생성
    try:
        existing_collection = client.get_collection(collection_name)
        print(f"기존 컬렉션 '{collection_name}' 삭제 중...")
        client.delete_collection(collection_name)
    except Exception:
        pass  # 컬렉션이 없으면 그냥 진행
    
    collection = client.create_collection(
        name=collection_name,
        metadata={"description": "루틴 추천을 위한 벡터 데이터베이스"}
    )
    
    # 4. 각 루틴에 대해 임베딩 생성 및 저장
    print(f"총 {len(ALL_ROUTINES)}개의 루틴을 처리 중...")
    
    ids = []
    documents = []
    metadatas = []
    
    for item in ALL_ROUTINES:
        # 텍스트 생성: "{title} - {description}"
        text = f"{item.title} - {item.description}"
        
        # ID, 문서, 메타데이터 저장
        ids.append(item.id)
        documents.append(text)
        metadatas.append({
            "group": item.group,
            "sub_group": item.sub_group,
            "tags": ",".join(item.tags),
        })
    
    # 5. 일괄 임베딩 생성
    print("임베딩 생성 중...")
    embeddings = model.encode(documents, convert_to_numpy=True, show_progress_bar=True)
    embeddings_list = embeddings.tolist()
    
    # 6. ChromaDB에 추가
    print("ChromaDB에 저장 중...")
    collection.add(
        ids=ids,
        documents=documents,
        metadatas=metadatas,
        embeddings=embeddings_list
    )
    
    # 7. 저장 확인
    count = collection.count()
    print(f"✅ routine_kb 구축 완료! (총 {count}개 루틴 저장)")


if __name__ == "__main__":
    build_routine_vector_db()

