"""RAG VectorStore 저장 확인 스크립트"""
import sys
import os
from pathlib import Path

# 프로젝트 루트 경로 설정
current_file = Path(__file__).resolve()
project_root = current_file.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from backend.engine.langchain_agent.conversation_vectorstore import get_conversation_vectorstore
except ImportError:
    sys.path.insert(0, str(current_file.parent))
    from conversation_vectorstore import get_conversation_vectorstore

# VectorStore 가져오기
store = get_conversation_vectorstore()

# 저장된 메시지 개수
count = store.collection.count()
print(f"\n{'='*60}")
print(f"RAG VectorStore 저장 상태")
print(f"{'='*60}")
print(f"총 저장된 메시지: {count}개\n")

if count > 0:
    # 저장된 메시지 조회
    result = store.collection.get()
    
    print(f"저장된 메시지 ID 목록:")
    for i, msg_id in enumerate(result['ids'], 1):
        print(f"  {i}. {msg_id}")
    
    print(f"\n첫 번째 메시지 내용:")
    if result['documents']:
        print(f"  {result['documents'][0][:100]}...")
    
    print(f"\n✅ RAG 저장 성공!")
else:
    print("⚠️  저장된 메시지가 없습니다.")
    
print(f"{'='*60}\n")
