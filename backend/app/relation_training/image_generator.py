"""
Image generation module for Deep Agent Pipeline
Supports Gemini 2.5 Flash image generation with skip mode
"""
import os
from pathlib import Path
from typing import Optional, Dict
from PIL import Image, ImageDraw, ImageFont
import asyncio
import base64
import io


# Gemini client (initialized once)
_gemini_client = None


async def init_gemini_client():
    """
    Initialize Gemini client (called once at startup)
    
    Returns:
        Gemini client or None if skip mode
    """
    global _gemini_client
    
    # Skip if already initialized
    if _gemini_client is not None:
        return _gemini_client
    
    # Skip if in skip mode
    skip_images = os.getenv("USE_SKIP_IMAGES", "false").lower() == "true"
    if skip_images:
        print("[Image Generator] Skip mode enabled - no Gemini client initialization")
        return None
    
    gemini_api_key = os.getenv("GEMINI_API_KEY")
    if not gemini_api_key:
        print("[Image Generator] GEMINI_API_KEY not found - falling back to skip mode")
        return None
    
    try:
        import google.generativeai as genai
        genai.configure(api_key=gemini_api_key)
        _gemini_client = genai
        print("[Image Generator] Gemini client initialized successfully")
        return _gemini_client
    except ImportError:
        print("[Image Generator] google-generativeai not installed - falling back to skip mode")
        return None
    except Exception as e:
        print(f"[Image Generator] Failed to initialize Gemini client: {e}")
        return None


async def generate_image_with_gemini(prompt: str, output_path: Path) -> bool:
    """
    Generate image using Gemini 2.5 Flash
    
    Args:
        prompt: Text prompt (Korean or English)
        output_path: Output file path
    
    Returns:
        True if successful, False otherwise
    """
    global _gemini_client
    
    try:
        if _gemini_client is None:
            await init_gemini_client()
            if _gemini_client is None:
                print(f"[Image Generator] Gemini not available, skipping: {output_path.name}")
                return False
        
        # Use Gemini 2.5 Flash Image for image generation
        model = _gemini_client.GenerativeModel('gemini-2.5-flash-image')
        
        # Generate image
        response = await asyncio.to_thread(
            model.generate_content,
            [prompt],
            generation_config={
                "temperature": 0.8,
                "max_output_tokens": 8192,
            }
        )
        
        # Extract image from response
        # Note: Gemini 2.5 Flash returns images in the response
        if hasattr(response, 'candidates') and response.candidates:
            for part in response.candidates[0].content.parts:
                if hasattr(part, 'inline_data') and part.inline_data:
                    # Decode base64 image
                    image_data = base64.b64decode(part.inline_data.data)
                    image = Image.open(io.BytesIO(image_data))
                    
                    # Save image
                    output_path.parent.mkdir(parents=True, exist_ok=True)
                    image.save(output_path)
                    
                    print(f"[Image Generator] Generated: {output_path.name}")
                    return True
        
        print(f"[Image Generator] No image in response for: {output_path.name}")
        return False
        
    except Exception as e:
        print(f"[Image Generator] Error generating {output_path.name}: {e}")
        import traceback
        traceback.print_exc()
        return False


async def generate_image(prompt: str, output_path: Path) -> bool:
    """
    Generate image asynchronously
    
    Args:
        prompt: Text prompt (Korean or English)
        output_path: Output file path
    
    Returns:
        True if successful, False otherwise
    """
    return await generate_image_with_gemini(prompt, output_path)


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
    ], return_exceptions=True)
    
    # Convert exceptions to False
    return [r if isinstance(r, bool) else False for r in results]


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
            font = ImageFont.load_default()
        
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
# High-level API (compatible with existing code)
# ============================================================================

async def generate_start_image(
    scenario_json,
    folder_name: str,
    user_id: Optional[int]
) -> Optional[str]:
    """
    Generate start image for scenario
    
    Args:
        scenario_json: ScenarioJSON object with character design
        folder_name: Folder name
        user_id: User ID (None for public scenarios)
    
    Returns:
        Image URL or None if skipped
    """
    skip_images = os.getenv("USE_SKIP_IMAGES", "false").lower() == "true"
    
    if skip_images:
        print("[1/17] Start image - SKIPPED")
        return None
    
    print("[1/17] Start image 생성 중...")
    
    # Create prompt from character design
    prompt = f"따뜻하고 친근한 분위기의 한국 가정집 장면. {scenario_json.character_design.protagonist_visual}와 {scenario_json.character_design.target_visual}가 편안한 공간에 있는 모습. 부드러운 조명, 따뜻한 분위기, 4컷 만화 스타일"
    
    # Determine output path (공용 시나리오는 "public" 폴더 사용)
    images_dir = Path(__file__).parent / "images"
    user_folder = "public" if user_id is None else str(user_id)
    output_path = images_dir / user_folder / folder_name / "start.png"
    
    # Generate image
    success = await generate_image(prompt, output_path)
    
    if success:
        # Return URL
        return f"/api/service/relation-training/images/{user_folder}/{folder_name}/start.png"
    else:
        print("[Image Generator] Start image generation failed")
        return None


async def generate_result_images(
    scenario_json,
    folder_name: str,
    user_id: Optional[int]
) -> Dict[str, Optional[str]]:
    """
    Generate result images (16 images) for scenario
    
    Args:
        scenario_json: ScenarioJSON object with results
        folder_name: Folder name
        user_id: User ID
    
    Returns:
        Dict of {result_code: image_url or None}
    """
    skip_images = os.getenv("USE_SKIP_IMAGES", "false").lower() == "true"
    
    if skip_images:
        print("[2-17/17] Result images - SKIPPED")
        return {}
    
    print(f"[2-17/17] Result images 생성 중... (총 {len(scenario_json.results)}장)")
    
    # Prepare tasks
    images_dir = Path(__file__).parent / "images"
    tasks = []
    result_codes = []
    
    for idx, result in enumerate(scenario_json.results, start=2):
        # Create prompt from result data
        atmosphere_desc = {
            "STORM": "폭풍우 치는 어두운 분위기",
            "CLOUDY": "흐리고 우울한 분위기",
            "SUNNY": "밝고 화창한 분위기",
            "FLOWER": "꽃이 피어나는 아름다운 분위기"
        }.get(result.atmosphere_image_type, "중립적인 분위기")
        
        prompt = f"{result.display_title} - {atmosphere_desc}. {result.analysis_text[:100]}. 4컷 만화 스타일, 감정 표현이 풍부한 장면"
        
        # 공용 시나리오는 "public" 폴더 사용
        user_folder = "public" if user_id is None else str(user_id)
        output_path = images_dir / user_folder / folder_name / f"result_{result.result_code}.png"
        tasks.append((prompt, output_path))
        result_codes.append(result.result_code)
        print(f"[{idx}/17] Result {result.result_code} 준비...")
    
    # Generate in parallel
    max_concurrent = int(os.getenv("MAX_PARALLEL_IMAGE_GENERATION", "4"))
    results = await generate_images_batch(tasks, max_concurrent=max_concurrent)
    
    # Build result dict
    user_folder = "public" if user_id is None else str(user_id)
    image_urls = {}
    for result_code, success in zip(result_codes, results):
        if success:
            image_urls[result_code] = f"/api/service/relation-training/images/{user_folder}/{folder_name}/result_{result_code}.png"
        else:
            image_urls[result_code] = None
            print(f"[Image Generator] Result {result_code} generation failed")
    
    return image_urls


# Legacy function for backward compatibility
async def load_flux_model():
    """
    Legacy function - now initializes Gemini client instead
    
    Returns:
        Gemini client or None
    """
    return await init_gemini_client()
