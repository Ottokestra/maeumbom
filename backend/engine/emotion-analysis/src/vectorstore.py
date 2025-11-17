"""
Vector database management using ChromaDB
"""
import sys
from pathlib import Path
import chromadb
from chromadb.config import Settings
from typing import List, Dict, Any, Optional
import numpy as np

# 경로 설정 및 import
src_path = Path(__file__).parent
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

import importlib.util

# config import
config_path = src_path / "config.py"
spec = importlib.util.spec_from_file_location("config", config_path)
config_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config_module)
VECTORDB_PATH = config_module.VECTORDB_PATH
COLLECTION_NAME = config_module.COLLECTION_NAME
TOP_K_RESULTS = config_module.TOP_K_RESULTS

# embeddings import
embeddings_path = src_path / "embeddings.py"
spec = importlib.util.spec_from_file_location("embeddings", embeddings_path)
embeddings_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(embeddings_module)
get_embedding_generator = embeddings_module.get_embedding_generator

# data_loader import
data_loader_path = src_path / "data_loader.py"
spec = importlib.util.spec_from_file_location("data_loader", data_loader_path)
data_loader_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(data_loader_module)
EmotionDataLoader = data_loader_module.EmotionDataLoader


class VectorStore:
    """Manage emotion context vectors using ChromaDB"""
    
    def __init__(self, persist_directory: str = VECTORDB_PATH):
        """
        Initialize vector store
        
        Args:
            persist_directory: Directory to persist ChromaDB data
        """
        self.persist_directory = Path(persist_directory)
        self.persist_directory.mkdir(parents=True, exist_ok=True)
        
        # Initialize ChromaDB client
        self.client = chromadb.PersistentClient(
            path=str(self.persist_directory),
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        
        # Get or create collection
        self.collection = self.client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"description": "Emotion context embeddings for RAG"}
        )
        
        print(f"Vector store initialized at: {self.persist_directory}")
        print(f"Collection '{COLLECTION_NAME}' ready with {self.collection.count()} items")
    
    def add_documents(
        self,
        texts: List[str],
        emotions: List[str],
        intensities: List[int],
        ids: Optional[List[str]] = None
    ) -> None:
        """
        Add documents to the vector store
        
        Args:
            texts: List of text strings
            emotions: List of emotion labels
            intensities: List of intensity scores
            ids: Optional list of document IDs
        """
        if not texts:
            print("No documents to add")
            return
        
        # Generate IDs if not provided
        if ids is None:
            start_id = self.collection.count()
            ids = [f"doc_{start_id + i}" for i in range(len(texts))]
        
        # Generate embeddings
        embedding_gen = get_embedding_generator()
        embeddings = embedding_gen.generate_embeddings(texts)
        
        # Prepare metadata
        metadatas = [
            {
                "emotion": emotion,
                "intensity": intensity,
                "text": text
            }
            for emotion, intensity, text in zip(emotions, intensities, texts)
        ]
        
        # Add to collection
        self.collection.add(
            ids=ids,
            embeddings=embeddings.tolist(),
            documents=texts,
            metadatas=metadatas
        )
        
        print(f"Added {len(texts)} documents to vector store")
    
    def search(
        self,
        query_text: str,
        n_results: int = TOP_K_RESULTS,
        emotion_filter: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Search for similar contexts
        
        Args:
            query_text: Query text string
            n_results: Number of results to return
            emotion_filter: Optional emotion to filter by
            
        Returns:
            Dictionary with search results
        """
        # Generate query embedding
        embedding_gen = get_embedding_generator()
        query_embedding = embedding_gen.generate_embedding(query_text)
        
        # Prepare filter
        where_filter = None
        if emotion_filter:
            where_filter = {"emotion": emotion_filter}
        
        # Search
        results = self.collection.query(
            query_embeddings=[query_embedding.tolist()],
            n_results=n_results,
            where=where_filter
        )
        
        # Format results
        formatted_results = {
            "texts": results['documents'][0] if results['documents'] else [],
            "metadatas": results['metadatas'][0] if results['metadatas'] else [],
            "distances": results['distances'][0] if results['distances'] else []
        }
        
        return formatted_results
    
    def initialize_from_data(self, data_path: str = "data/raw/sample_emotions.json") -> None:
        """
        Initialize vector store from emotion data file
        
        Args:
            data_path: Path to emotion data JSON file
        """
        # Load data
        loader = EmotionDataLoader(data_path)
        data = loader.load_data()
        
        if not data:
            print("No data to initialize")
            return
        
        # Clear existing data
        if self.collection.count() > 0:
            print(f"Clearing existing {self.collection.count()} documents")
            self.client.delete_collection(COLLECTION_NAME)
            self.collection = self.client.create_collection(
                name=COLLECTION_NAME,
                metadata={"description": "Emotion context embeddings for RAG"}
            )
        
        # Extract data
        texts = [item['text'] for item in data]
        emotions = [item['emotion'] for item in data]
        intensities = [item['intensity'] for item in data]
        
        # Add to vector store
        self.add_documents(texts, emotions, intensities)
        
        print(f"Vector store initialized with {len(data)} documents")
        
        # Print distribution
        distribution = {}
        for emotion in emotions:
            distribution[emotion] = distribution.get(emotion, 0) + 1
        print("Emotion distribution:")
        for emotion, count in sorted(distribution.items()):
            print(f"  {emotion}: {count}")
    
    def get_count(self) -> int:
        """
        Get the number of documents in the vector store
        
        Returns:
            Document count
        """
        return self.collection.count()
    
    def reset(self) -> None:
        """Reset the vector store (delete all data)"""
        self.client.delete_collection(COLLECTION_NAME)
        self.collection = self.client.create_collection(
            name=COLLECTION_NAME,
            metadata={"description": "Emotion context embeddings for RAG"}
        )
        print("Vector store reset")


# Global instance
_vector_store = None


def get_vector_store() -> VectorStore:
    """
    Get or create the global vector store instance
    
    Returns:
        VectorStore instance
    """
    global _vector_store
    if _vector_store is None:
        _vector_store = VectorStore()
    return _vector_store

