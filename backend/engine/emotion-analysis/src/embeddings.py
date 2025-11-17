"""
Embedding generation module using Korean sentence transformers
"""
import sys
from pathlib import Path
from sentence_transformers import SentenceTransformer
from typing import List, Union
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
EMBEDDING_MODEL = config_module.EMBEDDING_MODEL


class EmbeddingGenerator:
    """Generate embeddings for Korean text using sentence transformers"""
    
    def __init__(self, model_name: str = EMBEDDING_MODEL):
        """
        Initialize the embedding generator
        
        Args:
            model_name: Name of the sentence transformer model
        """
        print(f"Loading embedding model: {model_name}")
        self.model = SentenceTransformer(model_name)
        print("Embedding model loaded successfully")
    
    def generate_embedding(self, text: str) -> np.ndarray:
        """
        Generate embedding for a single text
        
        Args:
            text: Input text string
            
        Returns:
            Numpy array of embedding vector
        """
        embedding = self.model.encode(text, convert_to_numpy=True)
        return embedding
    
    def generate_embeddings(self, texts: List[str]) -> np.ndarray:
        """
        Generate embeddings for multiple texts
        
        Args:
            texts: List of input text strings
            
        Returns:
            Numpy array of embedding vectors
        """
        embeddings = self.model.encode(texts, convert_to_numpy=True, show_progress_bar=True)
        return embeddings
    
    def get_embedding_dimension(self) -> int:
        """
        Get the dimension of the embedding vectors
        
        Returns:
            Embedding dimension
        """
        return self.model.get_sentence_embedding_dimension()


# Global instance (lazy loading)
_embedding_generator = None


def get_embedding_generator() -> EmbeddingGenerator:
    """
    Get or create the global embedding generator instance
    
    Returns:
        EmbeddingGenerator instance
    """
    global _embedding_generator
    if _embedding_generator is None:
        _embedding_generator = EmbeddingGenerator()
    return _embedding_generator

