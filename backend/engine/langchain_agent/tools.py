"""
Tool Calling Definitions for Orchestrator LLM

Defines available tools for the orchestrator to select from based on user intent.
Each tool represents a capability the AI can invoke dynamically.
"""
from typing import List, Dict, Optional

# Tool definitions for OpenAI function calling
TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "search_memory",
            "description": """사용자의 장기 기억(Global Memory)을 검색합니다.
            과거 대화 내용이나 사용자 정보가 필요할 때 사용하세요.
            
            예시:
            - "지난주에 뭐라고 했지?" → search_memory(query="지난주")
            - "내 가족 이야기 기억해?" → search_memory(query="가족")""",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "검색 쿼리 (예: '가족관계', '건강상태', '지난주')"
                    }
                },
                "required": ["query"]
            }
        }
    }
]


def get_tool_by_name(name: str) -> Optional[Dict]:
    """
    도구 이름으로 도구 정의 반환
    
    Args:
        name: 도구 이름
        
    Returns:
        도구 정의 딕셔너리 또는 None
    """
    for tool in TOOLS:
        if tool["function"]["name"] == name:
            return tool
    return None


def get_tool_names() -> List[str]:
    """사용 가능한 모든 도구 이름 반환"""
    return [tool["function"]["name"] for tool in TOOLS]
