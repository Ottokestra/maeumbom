"""
Image generation module for Deep Agent Pipeline
Supports FLUX.1-schnell with AMD/NVIDIA GPU and skip mode
"""
import os
import torch
from pathlib import Path
from typing import Optional
from PIL import Image, ImageDraw, ImageFont
import asyncio
from concurrent.futures import ThreadPoolExecutor


# Global model instance (loaded once at startup)
_flux_model = None
_model_lock = asyncio.Lock()


def get_device() -> str:
    """
    Determine which device to use for image generation
    
    Returns:
        Device string ('cuda' or 'cpu')
    """
    use_amd = os.getenv("USE_AMD_GPU", "false").lower() == "true"
    use_nvidia = os.getenv("USE_NVIDIA_GPU", "false").lower() == "true"
    
    if (use_amd or use_nvidia) and torch.cuda.is_available():
        return "cuda"
    return "cpu"


async def load_flux_model():
    """
    Load FLUX.1-schnell model (called once at startup)
    
    Returns:
        FluxPipeline instance or None if skip mode
    """
    global _flux_model
    
    # Skip if already loaded
    if _flux_model is not None:
        return _flux_model
    
    # Skip if in skip mode
    skip_images = os.getenv("USE_SKIP_IMAGES", "false").lower() == "true"
    if skip_images:
        print("[Image Generator] Skip mode enabled - no model loading")
        return None
    
    async with _model_lock:
        # Double-check after acquiring lock
        if _flux_model is not None:
            return _flux_model
        
        print("[Image Generator] Loading FLUX.1-schnell model...")
        
        try:
            from diffusers import FluxPipeline
            
            device = get_device()
            dtype = torch.float16 if device == "cuda" else torch.float32
            
            # Load model
            _flux_model = FluxPipeline.from_pretrained(
                "black-forest-labs/FLUX.1-schnell",
                torch_dtype=dtype
            )
            
            # Move to device
            _flux_model = _flux_model.to(device)
            
            # Enable CPU offload if using GPU (memory optimization)
            if device == "cuda":
                try:
                    _flux_model.enable_model_cpu_offload()
                    print("[Image Generator] CPU offload enabled")
                except Exception as e:
                    print(f"[Image Generator] CPU offload not available: {e}")
            
            print(f"[Image Generator] Model loaded successfully on {device}")
            return _flux_model
            
        except Exception as e:
            print(f"[Image Generator] Failed to load model: {e}")
            print("[Image Generator] Falling back to skip mode")
            return None


def generate_image_sync(prompt: str, output_path: Path) -> bool:
    """
    Generate image synchronously (blocking)
    
    Args:
        prompt: English prompt for FLUX.1
        output_path: Output file path
    
    Returns:
        True if successful, False otherwise
    """
    global _flux_model
    
    try:
        if _flux_model is None:
            print(f"[Image Generator] Model not loaded, skipping: {output_path.name}")
            return False
        
        # Generate image
        result = _flux_model(
            prompt=prompt,
            num_inference_steps=4,  # schnell uses 4 steps
            guidance_scale=0.0,
            num_images_per_prompt=1
        )
        
        image = result.images[0]
        
        # Save image
        output_path.parent.mkdir(parents=True, exist_ok=True)
        image.save(output_path)
        
        print(f"[Image Generator] Generated: {output_path.name}")
        return True
        
    except Exception as e:
        print(f"[Image Generator] Error generating {output_path.name}: {e}")
        return False


async def generate_image(prompt: str, output_path: Path) -> bool:
    """
    Generate image asynchronously
    
    Args:
        prompt: English prompt for FLUX.1
        output_path: Output file path
    
    Returns:
        True if successful, False otherwise
    """
    # Run in thread pool to avoid blocking
    loop = asyncio.get_event_loop()
    with ThreadPoolExecutor() as executor:
        return await loop.run_in_executor(
            executor,
            generate_image_sync,
            prompt,
            output_path
        )


async def generate_images_batch(
    tasks: list,
    max_concurrent: int = 4
) -> list:
    """
    Generate multiple images in parallel
    
    Args:
        tasks: List of (prompt, output_path) tuples
        max_concurrent: Maximum concurrent generations
    
    Returns:
        List of success flags
    """
    # Create semaphore for concurrency control
    semaphore = asyncio.Semaphore(max_concurrent)
    
    async def generate_with_semaphore(prompt: str, output_path: Path):
        async with semaphore:
            return await generate_image(prompt, output_path)
    
    # Generate all images concurrently
    results = await asyncio.gather(*[
        generate_with_semaphore(prompt, path)
        for prompt, path in tasks
    ])
    
    return results


def create_placeholder_image(output_path: Path, text: str = "No Image"):
    """
    Create a placeholder image (for development/testing)
    
    Args:
        output_path: Output file path
        text: Text to display on image
    """
    try:
        # Create image
        img = Image.new('RGB', (800, 600), color=(240, 240, 240))
        draw = ImageDraw.Draw(img)
        
        # Add text
        try:
            # Try to use a font
            font = ImageFont.truetype("arial.ttf", 40)
        except:
            # Fallback to default font
            font = ImageDraw.ImageFont.load_default()
        
        # Calculate text position
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        position = ((img.width - text_width) // 2, (img.height - text_height) // 2)
        
        # Draw text
        draw.text(position, text, fill=(150, 150, 150), font=font)
        
        # Save
        output_path.parent.mkdir(parents=True, exist_ok=True)
        img.save(output_path)
        
        print(f"[Image Generator] Created placeholder: {output_path.name}")
        
    except Exception as e:
        print(f"[Image Generator] Error creating placeholder: {e}")


# ============================================================================
# High-level API
# ============================================================================

async def generate_start_image(
    prompt: str,
    user_id: int,
    folder_name: str
) -> Optional[str]:
    """
    Generate start image
    
    Args:
        prompt: English prompt
        user_id: User ID
        folder_name: Folder name
    
    Returns:
        Image URL or None if skipped
    """
    skip_images = os.getenv("USE_SKIP_IMAGES", "false").lower() == "true"
    
    if skip_images:
        print("[1/17] Start image - SKIPPED")
        return None
    
    print("[1/17] Start image 생성 중...")
    
    # Determine output path
    images_dir = Path(__file__).parent / "images"
    output_path = images_dir / str(user_id) / folder_name / "start.png"
    
    # Generate image
    success = await generate_image(prompt, output_path)
    
    if success:
        # Return URL
        return f"/api/service/relation-training/images/{user_id}/{folder_name}/start.png"
    else:
        print("[Image Generator] Start image generation failed")
        return None


async def generate_result_images(
    prompts: dict,
    user_id: int,
    folder_name: str
) -> dict:
    """
    Generate result images (16 images)
    
    Args:
        prompts: Dict of {result_code: prompt}
        user_id: User ID
        folder_name: Folder name
    
    Returns:
        Dict of {result_code: image_url or None}
    """
    skip_images = os.getenv("USE_SKIP_IMAGES", "false").lower() == "true"
    
    if skip_images:
        print("[2-17/17] Result images - SKIPPED")
        return {code: None for code in prompts.keys()}
    
    print(f"[2-17/17] Result images 생성 중... (총 {len(prompts)}장)")
    
    # Prepare tasks
    images_dir = Path(__file__).parent / "images"
    tasks = []
    result_codes = []
    
    for idx, (result_code, prompt) in enumerate(prompts.items(), start=2):
        output_path = images_dir / str(user_id) / folder_name / f"result_{result_code}.png"
        tasks.append((prompt, output_path))
        result_codes.append(result_code)
        print(f"[{idx}/17] Result {result_code} 준비...")
    
    # Generate in parallel
    max_concurrent = int(os.getenv("MAX_PARALLEL_IMAGE_GENERATION", "4"))
    results = await generate_images_batch(tasks, max_concurrent=max_concurrent)
    
    # Build result dict
    image_urls = {}
    for result_code, success in zip(result_codes, results):
        if success:
            image_urls[result_code] = f"/api/service/relation-training/images/{user_id}/{folder_name}/result_{result_code}.png"
        else:
            image_urls[result_code] = None
            print(f"[Image Generator] Result {result_code} generation failed")
    
    return image_urls

