"""
Conversation Vector Store

대화 히스토리를 벡터 DB에 저장하고 의미 기반 검색을 수행하는 시스템
- ChromaDB를 사용한 대화 임베딩 저장
- 현재 질문과 유사한 과거 대화 검색
- 서버 재시작 시 자동 초기화 (개발 단계)
- 세션별 필터링 지원
"""
import chromadb
from chromadb.config import Settings
from pathlib import Path
from typing import List, Dict, Any, Optional
from datetime import datetime
import atexit


# Vector DB 경로
VECTORDB_PATH = Path(__file__).parent / "vectordb" / "conversations"
VECTORDB_PATH.mkdir(parents=True, exist_ok=True)

# Collection 이름
COLLECTION_NAME = "conversation_history"


class ConversationVectorStore:
    """
    대화 히스토리를 벡터 DB에 저장 및 검색
    
    개발 단계: 서버 재시작 시 자동 초기화
    프로덕션: 영구 저장소로 마이그레이션 필요
    """
    
    def __init__(
        self, 
        persist_directory: str = str(VECTORDB_PATH),
        reset_on_init: bool = False  # 프로덕션: 영구 저장
    ):
        """
        초기화
        
        Args:
            persist_directory: ChromaDB 저장 경로
            reset_on_init: 초기화 시 기존 데이터 삭제 여부 (개발용)
        """
        self.persist_directory = Path(persist_directory)
        self.persist_directory.mkdir(parents=True, exist_ok=True)
        
        # ChromaDB 클라이언트 초기화
        self.client = chromadb.PersistentClient(
            path=str(self.persist_directory),
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        
        # 개발 단계: 서버 재시작 시 초기화
        if reset_on_init:
            try:
                self.client.delete_collection(COLLECTION_NAME)
                print(f"[Conversation RAG] 🔄 기존 대화 히스토리 초기화")
            except:
                pass
        
        # Collection 생성 또는 가져오기
        self.collection = self.client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"description": "Conversation history embeddings for context retrieval"}
        )
        
        print(f"[Conversation RAG] 📊 Vector store 초기화: {self.collection.count()}개 문서")
        
        # 종료 시 정리 (옵션)
        atexit.register(self._cleanup)
    
    def add_message(
        self,
        message_id: str,
        session_id: str,
        role: str,
        content: str,
        emotion_result: Optional[Dict] = None,
        timestamp: Optional[str] = None
    ) -> None:
        """
        대화 메시지를 벡터 DB에 추가
        
        Args:
            message_id: 메시지 ID (고유)
            session_id: 세션 ID
            role: 역할 ("user" 또는 "assistant")
            content: 메시지 내용
            emotion_result: 감정 분석 결과 (선택)
            timestamp: 타임스탬프 (선택)
        """
        if not content or len(content.strip()) == 0:
            return
        
        # 메타데이터 구성
        metadata = {
            "session_id": session_id,
            "role": role,
            "timestamp": timestamp or datetime.now().isoformat()
        }
        
        # 감정 정보 추가 (user 메시지만)
        if role == "user" and emotion_result:
            primary_emotion = emotion_result.get("primary_emotion", {})
            metadata["emotion_code"] = primary_emotion.get("code", "")
            metadata["emotion_name"] = primary_emotion.get("name_ko", "")
            metadata["sentiment"] = emotion_result.get("sentiment_overall", "")
            metadata["risk_level"] = emotion_result.get("service_signals", {}).get("risk_level", "")
        
        # ChromaDB에 추가
        try:
            self.collection.add(
                ids=[message_id],
                documents=[content],
                metadatas=[metadata]
            )
        except Exception as e:
            print(f"[Conversation RAG] ⚠️ 메시지 추가 실패: {e}")
    
    def search_similar_conversations(
        self,
        query_text: str,
        session_id: Optional[str] = None,
        n_results: int = 5,
        min_relevance: float = 0.3
    ) -> List[Dict[str, Any]]:
        """
        현재 질문과 유사한 과거 대화 검색
        
        Args:
            query_text: 검색 쿼리 (현재 사용자 입력)
            session_id: 세션 ID 필터 (선택)
            n_results: 반환할 결과 수
            min_relevance: 최소 관련성 점수 (0~1, 낮을수록 관련성 높음)
            
        Returns:
            관련 대화 리스트
        """
        if not query_text or len(query_text.strip()) == 0:
            return []
        
        # 세션별 필터 설정
        where_filter = {}
        if session_id:
            where_filter["session_id"] = session_id
        
        try:
            # ChromaDB 검색
            results = self.collection.query(
                query_texts=[query_text],
                n_results=n_results,
                where=where_filter if where_filter else None
            )
            
            # 결과가 없으면 빈 리스트 반환
            if not results or not results.get("ids") or len(results["ids"][0]) == 0:
                return []
            
            # 결과 포맷팅
            formatted_results = []
            ids = results["ids"][0]
            documents = results["documents"][0]
            metadatas = results["metadatas"][0]
            distances = results["distances"][0]
            
            for i in range(len(ids)):
                # 거리를 유사도로 변환 (거리가 작을수록 유사)
                # ChromaDB의 거리는 L2 distance (0~2 범위)
                similarity = max(0.0, 1.0 - distances[i])
                
                # 최소 관련성 필터
                if similarity < min_relevance:
                    continue
                
                formatted_results.append({
                    "message_id": ids[i],
                    "content": documents[i],
                    "metadata": metadatas[i],
                    "similarity": similarity,
                    "distance": distances[i]
                })
            
            return formatted_results
        
        except Exception as e:
            print(f"[Conversation RAG] ⚠️ 검색 실패: {e}")
            return []
    
    def format_for_llm(self, search_results: List[Dict]) -> str:
        """
        LLM 프롬프트용 포맷팅
        
        Args:
            search_results: 검색 결과 리스트
            
        Returns:
            포맷된 텍스트
        """
        if not search_results:
            return ""
        
        lines = ["관련 과거 대화 (RAG 검색 결과):"]
        
        for i, result in enumerate(search_results[:3], 1):  # 최대 3개
            content = result["content"]
            metadata = result.get("metadata", {})
            role = metadata.get("role", "")
            
            role_ko = "사용자" if role == "user" else "AI 봄이"
            
            # 감정 정보가 있으면 추가
            emotion_info = ""
            if role == "user" and metadata.get("emotion_name"):
                emotion_info = f" (감정: {metadata['emotion_name']})"
            
            # 내용이 너무 길면 자르기
            if len(content) > 100:
                content = content[:100] + "..."
            
            lines.append(f"{i}. {role_ko}: {content}{emotion_info}")
        
        return "\n".join(lines)
    
    def get_count(self) -> int:
        """저장된 메시지 수 반환"""
        return self.collection.count()
    
    def clear_session(self, session_id: str) -> int:
        """
        특정 세션의 대화 삭제
        
        Args:
            session_id: 세션 ID
            
        Returns:
            삭제된 메시지 수
        """
        try:
            # 세션 메시지 조회
            results = self.collection.get(
                where={"session_id": session_id}
            )
            
            if not results or not results.get("ids"):
                return 0
            
            ids_to_delete = results["ids"]
            
            # 삭제
            self.collection.delete(ids=ids_to_delete)
            
            print(f"[Conversation RAG] 🗑️  세션 {session_id} 대화 삭제: {len(ids_to_delete)}개")
            
            return len(ids_to_delete)
        
        except Exception as e:
            print(f"[Conversation RAG] ⚠️ 세션 삭제 실패: {e}")
            return 0
    
    def reset(self) -> None:
        """모든 대화 삭제 (초기화)"""
        try:
            self.client.delete_collection(COLLECTION_NAME)
            self.collection = self.client.create_collection(
                name=COLLECTION_NAME,
                metadata={"description": "Conversation history embeddings for context retrieval"}
            )
            print(f"[Conversation RAG] 🔄 전체 초기화 완료")
        except Exception as e:
            print(f"[Conversation RAG] ⚠️ 초기화 실패: {e}")
    
    def _cleanup(self):
        """종료 시 정리"""
        # 개발 단계에서는 별도 정리 불필요 (자동 persist)
        pass


# 전역 인스턴스
_conversation_vectorstore = None


def get_conversation_vectorstore(reset_on_init: bool = False) -> ConversationVectorStore:
    """
    전역 Conversation VectorStore 인스턴스 반환
    
    Args:
        reset_on_init: 초기화 시 리셋 여부 (개발용)
        
    Returns:
        ConversationVectorStore 인스턴스
    """
    global _conversation_vectorstore
    if _conversation_vectorstore is None:
        _conversation_vectorstore = ConversationVectorStore(reset_on_init=reset_on_init)
    return _conversation_vectorstore


# 편의 함수들
def add_message_to_rag(
    message_id: str,
    session_id: str,
    role: str,
    content: str,
    emotion_result: Optional[Dict] = None
) -> None:
    """대화 메시지를 RAG에 추가"""
    vectorstore = get_conversation_vectorstore()
    vectorstore.add_message(message_id, session_id, role, content, emotion_result)


def search_similar_messages(
    query: str,
    session_id: Optional[str] = None,
    n_results: int = 5
) -> List[Dict]:
    """유사한 과거 대화 검색"""
    vectorstore = get_conversation_vectorstore()
    return vectorstore.search_similar_conversations(query, session_id, n_results)


def get_rag_context_for_prompt(query: str, session_id: Optional[str] = None) -> str:
    """LLM 프롬프트용 RAG 컨텍스트 조회"""
    results = search_similar_messages(query, session_id)
    vectorstore = get_conversation_vectorstore()
    return vectorstore.format_for_llm(results)


if __name__ == "__main__":
    # 테스트
    print("=" * 80)
    print("Conversation VectorStore 테스트")
    print("=" * 80)
    
    # VectorStore 초기화
    vectorstore = get_conversation_vectorstore(reset_on_init=True)
    
    # 테스트 대화 추가
    test_messages = [
        {
            "message_id": "msg_001",
            "session_id": "test_session_1",
            "role": "user",
            "content": "요즘 잠을 잘 못 자서 힘들어요",
            "emotion_result": {
                "primary_emotion": {"code": "anxiety", "name_ko": "불안"},
                "sentiment_overall": "negative",
                "service_signals": {"risk_level": "watch"}
            }
        },
        {
            "message_id": "msg_002",
            "session_id": "test_session_1",
            "role": "assistant",
            "content": "잠을 못 주무시는 게 힘드시겠어요. 어떤 점이 가장 힘드신가요?"
        },
        {
            "message_id": "msg_003",
            "session_id": "test_session_1",
            "role": "user",
            "content": "밤에 계속 깨고, 새벽에 일찍 일어나게 돼요",
            "emotion_result": {
                "primary_emotion": {"code": "confusion", "name_ko": "혼란"},
                "sentiment_overall": "negative"
            }
        }
    ]
    
    print("\n[테스트 1] 메시지 추가")
    for msg in test_messages:
        vectorstore.add_message(**msg)
    
    print(f"총 {vectorstore.get_count()}개 메시지 저장됨")
    
    # 유사 대화 검색
    print("\n[테스트 2] 유사 대화 검색")
    query = "잠을 못 자서 피곤해요"
    results = vectorstore.search_similar_conversations(query, n_results=3)
    
    print(f"검색 쿼리: {query}")
    print(f"결과: {len(results)}개")
    for i, result in enumerate(results, 1):
        print(f"\n{i}. 유사도: {result['similarity']:.2f}")
        print(f"   내용: {result['content'][:50]}...")
        print(f"   메타: {result['metadata']}")
    
    # LLM 프롬프트 포맷팅
    print("\n[테스트 3] LLM 프롬프트 포맷")
    prompt_text = vectorstore.format_for_llm(results)
    print(prompt_text)
    
    print("\n" + "=" * 80)
    print("✅ 테스트 완료!")
    print("=" * 80)
