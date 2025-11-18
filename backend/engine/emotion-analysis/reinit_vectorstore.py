"""
벡터 스토어 재초기화 스크립트
sample_emotions.json의 변경된 데이터로 벡터 스토어를 재초기화합니다.
"""
import sys
from pathlib import Path

# 경로 설정
script_dir = Path(__file__).parent
src_path = script_dir / "src"
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

# RAG pipeline import
import importlib.util
rag_pipeline_path = src_path / "rag_pipeline.py"
spec = importlib.util.spec_from_file_location("rag_pipeline", rag_pipeline_path)
rag_pipeline_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rag_pipeline_module)
get_rag_pipeline = rag_pipeline_module.get_rag_pipeline


def reinitialize_vectorstore():
    """벡터 스토어를 재초기화"""
    print("=" * 50)
    print("벡터 스토어 재초기화 시작")
    print("=" * 50)
    
    try:
        # RAG pipeline 가져오기
        pipeline = get_rag_pipeline()
        
        # 현재 벡터 스토어 상태 확인
        current_count = pipeline.vector_store.get_count()
        print(f"\n현재 벡터 스토어 문서 수: {current_count}")
        
        if current_count > 0:
            print("기존 데이터를 삭제하고 새 데이터로 재초기화합니다...")
        
        # 벡터 스토어 재초기화
        result = pipeline.initialize_vector_store()
        
        if result['status'] == 'success':
            print("\n" + "=" * 50)
            print("✅ 벡터 스토어 재초기화 완료!")
            print("=" * 50)
            print(f"문서 수: {result['document_count']}")
            print(f"메시지: {result['message']}")
            print("\n이제 17개 감정 데이터로 RAG 검색이 가능합니다.")
        else:
            print("\n" + "=" * 50)
            print("❌ 벡터 스토어 재초기화 실패")
            print("=" * 50)
            print(f"에러: {result['message']}")
            return False
            
    except Exception as e:
        print("\n" + "=" * 50)
        print("❌ 오류 발생")
        print("=" * 50)
        print(f"에러: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
    
    return True


if __name__ == "__main__":
    success = reinitialize_vectorstore()
    sys.exit(0 if success else 1)

