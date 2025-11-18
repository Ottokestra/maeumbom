"""
RAG (Retrieval-Augmented Generation) pipeline for emotion analysis
"""
import sys
from pathlib import Path
from typing import Dict, Any, List

# 경로 설정 및 import
src_path = Path(__file__).parent
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

import importlib.util

# vectorstore import
vectorstore_path = src_path / "vectorstore.py"
spec = importlib.util.spec_from_file_location("vectorstore", vectorstore_path)
vectorstore_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vectorstore_module)
get_vector_store = vectorstore_module.get_vector_store

# emotion_analyzer import
emotion_analyzer_path = src_path / "emotion_analyzer.py"
spec = importlib.util.spec_from_file_location("emotion_analyzer", emotion_analyzer_path)
emotion_analyzer_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(emotion_analyzer_module)
get_emotion_analyzer = emotion_analyzer_module.get_emotion_analyzer

# config import
config_path = src_path / "config.py"
spec = importlib.util.spec_from_file_location("config", config_path)
config_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config_module)
TOP_K_RESULTS = config_module.TOP_K_RESULTS

# utils import
utils_path = src_path / "utils.py"
spec = importlib.util.spec_from_file_location("utils", utils_path)
utils_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(utils_module)
convert_va_to_ui_labels = utils_module.convert_va_to_ui_labels


class RAGPipeline:
    """RAG pipeline combining retrieval and emotion analysis"""
    
    def __init__(self):
        """Initialize RAG pipeline"""
        self.vector_store = get_vector_store()
        self.emotion_analyzer = get_emotion_analyzer()
        print("RAG pipeline initialized")
    
    def analyze_emotion(self, text: str) -> Dict[str, Any]:
        """
        Analyze emotion using RAG approach
        
        Args:
            text: Input text to analyze
            
        Returns:
            Dictionary with analysis results
        """
        # Step 1: Retrieve similar contexts from vector store
        search_results = self.vector_store.search(
            query_text=text,
            n_results=TOP_K_RESULTS
        )
        
        # Step 2: Extract context information
        similar_contexts = []
        if search_results['metadatas']:
            for metadata, distance in zip(
                search_results['metadatas'],
                search_results['distances']
            ):
                similar_contexts.append({
                    "text": metadata.get('text', ''),
                    "emotion": metadata.get('emotion', ''),
                    "intensity": metadata.get('intensity', 0),
                    "similarity": 1 - distance  # Convert distance to similarity
                })
        
        # Step 3: Analyze emotion with context (17개 감정 군집 기반)
        # LLM은 raw_distribution만 생성하고, 나머지는 백엔드에서 계산
        analysis_result = self.emotion_analyzer.analyze_emotion(
            text=text,
            context_texts=similar_contexts
        )
        
        # Step 4: Return 17 emotion clusters analysis result
        # analyze_emotion이 이미 완전한 형식으로 반환하므로 그대로 사용
        # similar_contexts는 내부적으로만 사용하고 최종 응답에는 포함하지 않음
        return analysis_result
    
    def initialize_vector_store(self, data_path: str = "data/raw/sample_emotions.json") -> Dict[str, Any]:
        """
        Initialize vector store with emotion data
        
        Args:
            data_path: Path to emotion data file
            
        Returns:
            Dictionary with initialization status
        """
        try:
            self.vector_store.initialize_from_data(data_path)
            count = self.vector_store.get_count()
            return {
                "status": "success",
                "message": f"Vector store initialized with {count} documents",
                "document_count": count
            }
        except Exception as e:
            return {
                "status": "error",
                "message": f"Failed to initialize vector store: {str(e)}",
                "document_count": 0
            }
    
    def get_status(self) -> Dict[str, Any]:
        """
        Get pipeline status
        
        Returns:
            Dictionary with status information
        """
        return {
            "vector_store_count": self.vector_store.get_count(),
            "emotion_categories": self.emotion_analyzer.emotions,
            "ready": self.vector_store.get_count() > 0
        }


# Global instance
_rag_pipeline = None


def get_rag_pipeline() -> RAGPipeline:
    """
    Get or create the global RAG pipeline instance
    
    Returns:
        RAGPipeline instance
    """
    global _rag_pipeline
    if _rag_pipeline is None:
        _rag_pipeline = RAGPipeline()
    return _rag_pipeline

