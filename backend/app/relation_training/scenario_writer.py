"""
Scenario Writer Module - Qwen 2.5 14B GGUF
Local scenario generation for Deep Agent Pipeline
Orchestrated by GPT-4o-mini
"""
import os
import asyncio
from typing import Optional
from pathlib import Path

# Global model instance (loaded once at startup)
_qwen_model = None
_model_lock = asyncio.Lock()


async def load_qwen_model():
    """
    Load Qwen 2.5 14B GGUF model (lazy loading)
    
    Model will be automatically downloaded from Hugging Face on first use
    and cached in ~/.cache/huggingface/
    
    Returns:
        Llama model instance or None if loading fails
    
    Raises:
        RuntimeError: If model loading fails
    """
    global _qwen_model
    
    async with _model_lock:
        if _qwen_model is not None:
            return _qwen_model
        
        print("[Scenario Writer] Loading Qwen 2.5 14B GGUF model...")
        print("[Scenario Writer] This may take a few minutes on first run (downloading ~8GB)")
        
        try:
            from llama_cpp import Llama
            from huggingface_hub import hf_hub_download
            
            # Check if model exists locally
            cache_dir = Path.home() / ".cache" / "huggingface" / "hub"
            print(f"[Scenario Writer] Model cache directory: {cache_dir}")
            
            # Download model file (will use cache if already downloaded)
            print("[Scenario Writer] Downloading/loading model file...")
            model_path = hf_hub_download(
                repo_id="SimmonsSongHW/Qwen2.5-14B-Instruct-Q4_K_M-GGUF",
                filename="qwen2.5-14b-instruct-q4_k_m.gguf"
            )
            
            print(f"[Scenario Writer] Model file path: {model_path}")
            
            # Load model directly from file path
            _qwen_model = Llama(
                model_path=model_path,
                n_ctx=4096,  # Context window
                n_threads=8,  # CPU threads (Ryzen AI 7 = 8 cores)
                n_gpu_layers=0,  # CPU only
                verbose=False
            )
            
            print("[Scenario Writer] ✅ Qwen 2.5 14B loaded successfully")
            print(f"[Scenario Writer] Model size: ~8GB (Q4_K_M quantized)")
            print(f"[Scenario Writer] Context window: 4096 tokens")
            print(f"[Scenario Writer] Threads: 8 (CPU)")
            
            return _qwen_model
            
        except ImportError:
            raise RuntimeError(
                "llama-cpp-python not installed. "
                "Please install: pip install llama-cpp-python==0.2.90"
            )
        except Exception as e:
            raise RuntimeError(f"Failed to load Qwen 2.5 14B model: {e}")


async def generate_with_qwen(
    system_prompt: str,
    user_prompt: str,
    max_tokens: int = 3000,
    temperature: float = 0.7
) -> str:
    """
    Generate scenario text using Qwen 2.5 14B
    
    This function is called by the Orchestrator (GPT-4o-mini) after preparing
    the prompts and variables.
    
    Args:
        system_prompt: System instruction for Qwen
        user_prompt: User request for Qwen
        max_tokens: Maximum tokens to generate
        temperature: Sampling temperature (0.0-1.0)
    
    Returns:
        Generated text (JSON or plain text)
    
    Raises:
        RuntimeError: If model is not loaded or generation fails
    """
    model = await load_qwen_model()
    
    if model is None:
        raise RuntimeError("Qwen model not loaded")
    
    # Qwen 2.5 chat format
    # Reference: https://huggingface.co/Qwen/Qwen2.5-14B-Instruct
    prompt = f"""<|im_start|>system
{system_prompt}<|im_end|>
<|im_start|>user
{user_prompt}<|im_end|>
<|im_start|>assistant
"""
    
    print(f"[Scenario Writer] Generating with Qwen 2.5 14B...")
    print(f"[Scenario Writer] System prompt length: {len(system_prompt)} chars")
    print(f"[Scenario Writer] User prompt length: {len(user_prompt)} chars")
    print(f"[Scenario Writer] Max tokens: {max_tokens}")
    
    try:
        # Run in thread pool to avoid blocking
        loop = asyncio.get_event_loop()
        
        def _generate():
            response = model(
                prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                top_p=0.9,
                stop=["<|im_end|>"],
                echo=False
            )
            return response["choices"][0]["text"].strip()
        
        # Execute in thread pool
        from concurrent.futures import ThreadPoolExecutor
        with ThreadPoolExecutor() as executor:
            result = await loop.run_in_executor(executor, _generate)
        
        print(f"[Scenario Writer] ✅ Generated {len(result)} characters")
        
        return result
        
    except Exception as e:
        raise RuntimeError(f"Qwen generation failed: {e}")


def is_qwen_available() -> bool:
    """
    Check if Qwen model can be loaded
    
    Returns:
        True if llama-cpp-python is installed, False otherwise
    """
    try:
        import llama_cpp
        return True
    except ImportError:
        return False


async def test_qwen_model():
    """
    Test function to verify Qwen model loading and generation
    
    Usage:
        python -c "import asyncio; from backend.app.relation_training.scenario_writer import test_qwen_model; asyncio.run(test_qwen_model())"
    """
    print("=" * 80)
    print("Testing Qwen 2.5 14B Model")
    print("=" * 80)
    
    try:
        # Test loading
        model = await load_qwen_model()
        print("✅ Model loaded successfully")
        
        # Test generation
        system_prompt = "You are a helpful assistant."
        user_prompt = "안녕하세요. 간단한 한국어 인사말을 해주세요."
        
        result = await generate_with_qwen(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            max_tokens=100
        )
        
        print("\n" + "=" * 80)
        print("Test Generation Result:")
        print("=" * 80)
        print(result)
        print("=" * 80)
        print("✅ Test completed successfully")
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        raise


if __name__ == "__main__":
    # Run test
    asyncio.run(test_qwen_model())

