"""
Conversation RAG V2
Stores and retrieves conversation history using ChromaDB for context-aware responses.
"""
import os
import sys
import uuid
import logging
import chromadb
from pathlib import Path
from typing import List, Dict, Any, Optional
from datetime import datetime

# Configure logging
logger = logging.getLogger(__name__)

# Path setup to reuse embedding generator from emotion-analysis
current_file = Path(__file__).resolve()
backend_root = current_file.parent.parent.parent
emotion_src = backend_root / "engine" / "emotion-analysis" / "src"

if str(emotion_src) not in sys.path:
    sys.path.insert(0, str(emotion_src))

try:
    from embeddings import get_embedding_generator
except ImportError:
    # Fallback if path setup fails
    logger.error("Failed to import embedding generator. RAG will not work.")
    get_embedding_generator = None

# ChromaDB Settings
CHROMA_DB_DIR = current_file.parent / "chroma_db"
COLLECTION_NAME = "conversation_history"

class ConversationRAG:
    def __init__(self):
        self.client = chromadb.PersistentClient(path=str(CHROMA_DB_DIR))
        self.collection = self.client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"description": "User conversation history for RAG"}
        )
        self.embedding_generator = get_embedding_generator() if get_embedding_generator else None
        
        if not self.embedding_generator:
            logger.warning("⚠️ Embedding generator not available. RAG features disabled.")

    def add_message(
        self, 
        user_id: int, 
        session_id: str, 
        role: str, 
        content: str, 
        metadata: Optional[Dict] = None
    ):
        """
        Add a message to the vector store.
        """
        if not self.embedding_generator:
            return

        try:
            # Generate embedding
            embedding = self.embedding_generator.generate_embedding(content)
            
            # Prepare metadata
            meta = {
                "user_id": user_id,
                "session_id": session_id,
                "role": role,
                "timestamp": datetime.now().isoformat()
            }
            if metadata:
                meta.update(metadata)
            
            # Add to ChromaDB
            msg_id = f"{session_id}_{uuid.uuid4().hex[:8]}"
            self.collection.add(
                ids=[msg_id],
                embeddings=[embedding.tolist()],
                documents=[content],
                metadatas=[meta]
            )
            logger.info(f"✅ [RAG] Added message to vector store: {msg_id}")
            
        except Exception as e:
            logger.error(f"❌ [RAG] Failed to add message: {e}")

    def search_similar(
        self, 
        user_id: int, 
        query_text: str, 
        current_session_id: str,
        k: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Search for similar messages from past sessions (excluding current session).
        """
        if not self.embedding_generator:
            return []

        try:
            embedding = self.embedding_generator.generate_embedding(query_text)
            
            # Filter: Same user, BUT different session (to avoid retrieving immediate context)
            where_filter = {
                "$and": [
                    {"user_id": {"$eq": user_id}},
                    {"session_id": {"$ne": current_session_id}}
                ]
            }
            
            results = self.collection.query(
                query_embeddings=[embedding.tolist()],
                n_results=k,
                where=where_filter
            )
            
            # Format results
            formatted_results = []
            if results['documents']:
                for i, doc in enumerate(results['documents'][0]):
                    meta = results['metadatas'][0][i]
                    formatted_results.append({
                        "content": doc,
                        "role": meta.get("role"),
                        "session_id": meta.get("session_id"),
                        "timestamp": meta.get("timestamp")
                    })
            
            return formatted_results
            
        except Exception as e:
            logger.error(f"❌ [RAG] Search failed: {e}")
            return []

# Global instance
_rag_instance = None

def get_conversation_rag() -> ConversationRAG:
    global _rag_instance
    if _rag_instance is None:
        _rag_instance = ConversationRAG()
    return _rag_instance
