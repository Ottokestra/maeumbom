"""
Prompt loading and variable substitution utilities for Deep Agent Pipeline
"""
from pathlib import Path
from typing import Dict
import re


def load_prompt(prompt_file: str, variables: Dict[str, str]) -> str:
    """
    Load a prompt file and substitute variables.
    
    Args:
        prompt_file: Prompt filename (e.g., 'scenario_architect.md')
        variables: Dictionary of variables to substitute
                  e.g., {'TARGET': 'HUSBAND', 'TOPIC': '남편이 밥투정을 합니다'}
    
    Returns:
        Prompt string with variables substituted
    
    Example:
        >>> prompt = load_prompt(
        ...     'scenario_architect.md',
        ...     {'TARGET': 'HUSBAND', 'TOPIC': '남편이 밥투정을 합니다'}
        ... )
    """
    # Get prompts directory
    prompts_dir = Path(__file__).parent / "prompts"
    prompt_path = prompts_dir / prompt_file
    
    if not prompt_path.exists():
        raise FileNotFoundError(f"Prompt file not found: {prompt_path}")
    
    # Read prompt file
    with open(prompt_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Substitute variables [VARIABLE_NAME] format
    for key, value in variables.items():
        # Replace [KEY] with value
        content = content.replace(f"[{key}]", str(value))
    
    return content


def extract_json_from_response(response_text: str) -> str:
    """
    Extract JSON from LLM response (removes code blocks and extra text).
    
    Args:
        response_text: Raw LLM response
    
    Returns:
        Clean JSON string
    
    Example:
        >>> text = "```json\\n{...}\\n```"
        >>> json_str = extract_json_from_response(text)
    """
    # Method 1: Try to extract from markdown code blocks
    # Pattern: ```json ... ``` or ``` ... ```
    pattern = r'```(?:json)?\s*(.*?)\s*```'
    matches = re.findall(pattern, response_text, re.DOTALL)
    
    print(f"[DEBUG] extract_json_from_response - 매치 개수: {len(matches)}")
    
    if matches:
        # Return first JSON block found
        result = matches[0].strip()
        print(f"[DEBUG] 코드 블록에서 추출 - 길이: {len(result)}, 시작: {result[:100]}...")
        return result
    
    # Method 2: Try to find JSON by looking for { ... } pattern
    # Find the first { and last }
    first_brace = response_text.find('{')
    last_brace = response_text.rfind('}')
    
    if first_brace != -1 and last_brace != -1 and first_brace < last_brace:
        result = response_text[first_brace:last_brace + 1].strip()
        print(f"[DEBUG] 중괄호 패턴에서 추출 - 길이: {len(result)}, 시작: {result[:100]}...")
        return result
    
    # Method 3: If no pattern found, return as is (might be pure JSON)
    print(f"[DEBUG] 패턴 없음, 원본 반환 - 길이: {len(response_text)}")
    return response_text.strip()


def validate_scenario_json(data: dict) -> bool:
    """
    Validate scenario JSON structure.
    
    Args:
        data: Parsed JSON data
    
    Returns:
        True if valid, False otherwise
    
    Raises:
        ValueError: If validation fails with details
    """
    required_keys = ['scenario', 'nodes', 'options', 'results']
    
    # Check top-level keys
    for key in required_keys:
        if key not in data:
            raise ValueError(f"Missing required key: {key}")
    
    # Check scenario
    scenario = data['scenario']
    if 'title' not in scenario:
        raise ValueError("scenario.title is required")
    if 'target_type' not in scenario:
        raise ValueError("scenario.target_type is required")
    if 'category' not in scenario:
        raise ValueError("scenario.category is required")
    
    # Check nodes (should be 15)
    nodes = data['nodes']
    if not isinstance(nodes, list):
        raise ValueError("nodes must be a list")
    if len(nodes) != 15:
        print(f"[WARN] Expected 15 nodes, got {len(nodes)} - continuing anyway")
    
    # Check options (should be 30)
    options = data['options']
    if not isinstance(options, list):
        raise ValueError("options must be a list")
    if len(options) != 30:
        print(f"[WARN] Expected 30 options, got {len(options)} - continuing anyway")
    
    # Check results (should be 16)
    results = data['results']
    if not isinstance(results, list):
        raise ValueError("results must be a list")
    if len(results) != 16:
        print(f"[WARN] Expected 16 results, got {len(results)} - continuing anyway")
    
    # Check character_design if exists
    if 'character_design' in data:
        char_design = data['character_design']
        if 'protagonist_visual' not in char_design:
            raise ValueError("character_design.protagonist_visual is required")
        if 'target_visual' not in char_design:
            raise ValueError("character_design.target_visual is required")
    
    return True

