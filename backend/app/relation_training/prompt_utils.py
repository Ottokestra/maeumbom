"""
Prompt loading and variable substitution utilities for Deep Agent Pipeline
"""
from pathlib import Path
from typing import Dict, Tuple
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


def load_prompt_sections(prompt_file: str, variables: Dict[str, str]) -> Tuple[str, str]:
    """
    Load a prompt file and extract system/user sections separately.
    
    Expects the prompt file to have markers:
    - # --- SYSTEM_PROMPT_START --- ... # --- SYSTEM_PROMPT_END ---
    - # --- USER_PROMPT_START --- ... # --- USER_PROMPT_END ---
    
    Args:
        prompt_file: Prompt filename (e.g., 'scenario_architect.md')
        variables: Dictionary of variables to substitute (applied to user prompt)
                  e.g., {'target': 'HUSBAND', 'topic': '남편이 밥투정을 합니다'}
    
    Returns:
        Tuple of (system_prompt, user_prompt)
    
    Example:
        >>> system, user = load_prompt_sections(
        ...     'scenario_architect.md',
        ...     {'target': 'HUSBAND', 'topic': '남편이 밥투정을 합니다'}
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
    
    # Extract system prompt
    system_pattern = r'# --- SYSTEM_PROMPT_START ---\s*(.*?)\s*# --- SYSTEM_PROMPT_END ---'
    system_match = re.search(system_pattern, content, re.DOTALL)
    
    if not system_match:
        raise ValueError(f"SYSTEM_PROMPT section not found in {prompt_file}")
    
    system_prompt = system_match.group(1).strip()
    
    # Extract user prompt
    user_pattern = r'# --- USER_PROMPT_START ---\s*(.*?)\s*# --- USER_PROMPT_END ---'
    user_match = re.search(user_pattern, content, re.DOTALL)
    
    if not user_match:
        raise ValueError(f"USER_PROMPT section not found in {prompt_file}")
    
    user_prompt = user_match.group(1).strip()
    
    # Substitute variables in user prompt using .format()
    user_prompt = user_prompt.format(**variables)
    
    return system_prompt, user_prompt


def extract_json_from_response(response_text: str) -> str:
    """
    Extract JSON from LLM response.
    
    When using response_format={"type":"json_object"}, OpenAI returns pure JSON.
    This function now simply strips whitespace and returns the content.
    
    Args:
        response_text: Raw LLM response
    
    Returns:
        Clean JSON string
    
    Example:
        >>> text = '{"key": "value"}'
        >>> json_str = extract_json_from_response(text)
    """
    # With JSON mode, response should be pure JSON
    # Just strip whitespace and return
    result = response_text.strip()
    
    print(f"[DEBUG] JSON 응답 수신 - 길이: {len(result)} 문자")
    
    # Fallback: if response still has code blocks (shouldn't happen with JSON mode)
    if result.startswith('```'):
        pattern = r'```(?:json)?\s*(.*?)\s*```'
        matches = re.findall(pattern, result, re.DOTALL)
        if matches:
            result = matches[0].strip()
            print(f"[DEBUG] 코드 블록 감지 (예상 밖) - 추출 완료")
    
    return result


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

