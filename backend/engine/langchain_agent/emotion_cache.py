"""
Emotion Cache Module using ChromaDB

Provides similarity-based caching for emotion analysis results
to reduce redundant analysis and improve response time.
"""
import chromadb
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer
from typing import Optional, Dict, List
import json
from datetime import datetime, timedelta
import logging
import os

logger = logging.getLogger(__name__)

class EmotionCache:
    """
    ChromaDB-based emotion analysis cache
    
    Features:
    - Similarity search with cosine distance
    - 30-day freshness window
    - Configurable similarity threshold (default 0.85)
    """
    
    _instance = None
    _embedder = None
    
    def __new__(cls):
        """Singleton pattern"""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
            
        # ChromaDB client
        data_path = os.path.join(os.path.dirname(__file__), "..", "..", "data", "chroma_emotion_cache")
        os.makedirs(data_path, exist_ok=True)
        
        self.client = chromadb.PersistentClient(path=data_path)
        self.collection = self.client.get_or_create_collection(
            name="emotion_cache",
            metadata={"hnsw:space": "cosine"}
        )
        
        # Sentence Transformer (singleton)
        if EmotionCache._embedder is None:
            logger.info("🔄 Loading SentenceTransformer model (jhgan/ko-sroberta-multitask)...")
            EmotionCache._embedder = SentenceTransformer('jhgan/ko-sroberta-multitask')
            logger.info("✅ Model loaded successfully")
        
        self.embedder = EmotionCache._embedder
        self._initialized = True
        logger.info(f"✅ EmotionCache initialized (collection size: {self.collection.count()})")
    
    def search(
        self,
        query_text: str,
        user_id: int,
        threshold: float = 0.85,
        freshness_days: int = 30
    ) -> Optional[Dict]:
        """
        Search for similar emotion analysis in cache
        
        Args:
            query_text: Input text to search for
            user_id: User ID for filtering
            threshold: Minimum similarity score (0.85 = 85%)
            freshness_days: Maximum age in days (30 days default)
            
        Returns:
            {
                "cached": True,
                "similarity": 0.92,
                "result": {...},  # Emotion analysis result
                "age_days": 5,
                "original_text": "..."
            } or None if not found
        """
        try:
            # Generate embedding
            query_embedding = self.embedder.encode(query_text).tolist()
            
            # Calculate cutoff timestamp (Unix timestamp for ChromaDB)
            cutoff_datetime = datetime.now() - timedelta(days=freshness_days)
            cutoff_timestamp = int(cutoff_datetime.timestamp())
            
            # Query ChromaDB with timestamp filter
            results = self.collection.query(
                query_embeddings=[query_embedding],
                n_results=1,
                where={
                    "$and": [
                        {"user_id": user_id},
                        {"created_timestamp": {"$gte": cutoff_timestamp}}
                    ]
                }
            )
            
            # Check if results exist
            if not results["ids"][0]:
                return None
            
            # Calculate similarity (ChromaDB returns cosine distance)
            distance = results["distances"][0][0]
            similarity = 1 - distance  # Convert distance to similarity
            
            if similarity >= threshold:
                metadata = results["metadatas"][0][0]
                # Calculate age from stored timestamp
                created_timestamp = metadata.get("created_timestamp", 0)
                age_days = (datetime.now().timestamp() - created_timestamp) / 86400  # seconds to days
                
                logger.info(
                    f"💾 [Cache Hit] Similarity: {similarity:.2%}, Age: {age_days:.1f} days, "
                    f"Original: '{metadata['input_text'][:30]}...'"
                )
                
                return {
                    "cached": True,
                    "similarity": similarity,
                    "result": json.loads(metadata["emotion_result"]),
                    "age_days": int(age_days),
                    "original_text": metadata["input_text"]
                }
            else:
                logger.info(f"❌ [Cache Miss] Best similarity: {similarity:.2%} < {threshold:.2%}")
                return None
                
        except Exception as e:
            logger.error(f"❌ [Cache Error] {e}", exc_info=True)
            return None
    
    def save(
        self,
        user_id: int,
        input_text: str,
        emotion_result: Dict,
        analysis_id: int
    ):
        """
        Save emotion analysis result to cache
        
        Args:
            user_id: User ID
            input_text: Original input text
            emotion_result: Emotion analysis result dict
            analysis_id: TB_EMOTION_ANALYSIS.ID for reference
        """
        try:
            # Generate embedding
            embedding = self.embedder.encode(input_text).tolist()
            
            # Current timestamp
            now = datetime.now()
            created_timestamp = int(now.timestamp())
            
            # Add to ChromaDB
            self.collection.add(
                ids=[f"user_{user_id}_analysis_{analysis_id}"],
                embeddings=[embedding],
                metadatas=[{
                    "user_id": user_id,
                    "input_text": input_text,
                    "emotion_result": json.dumps(emotion_result, ensure_ascii=False),
                    "created_at": now.isoformat(),  # Keep for readability
                    "created_timestamp": created_timestamp,  # Use for filtering
                    "analysis_id": analysis_id
                }]
            )
            
            logger.info(f"💾 [Cache Save] Analysis ID: {analysis_id}, User: {user_id}")
            
        except Exception as e:
            logger.error(f"❌ [Cache Save Error] {e}", exc_info=True)
    
    def get_stats(self) -> Dict:
        """Get cache statistics"""
        return {
            "total_count": self.collection.count(),
            "collection_name": self.collection.name,
            "model": "jhgan/ko-sroberta-multitask"
        }


# Singleton instance
_emotion_cache = None

def get_emotion_cache() -> EmotionCache:
    """Get singleton EmotionCache instance"""
    global _emotion_cache
    if _emotion_cache is None:
        _emotion_cache = EmotionCache()
    return _emotion_cache
