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
            "name": "search_emotion_cache",
            "description": """과거 유사한 감정 분석 결과를 검색합니다. 
            새로운 분석보다 빠르고 비용 효율적입니다.
            사용자가 감정을 표현할 때 먼저 호출하세요.""",
            "parameters": {
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "분석할 사용자 입력 텍스트"
                    }
                },
                "required": ["text"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "analyze_emotion",
            "description": """텍스트의 감정을 상세 분석합니다 (17개 감정 군집).
            비용과 시간이 소요되므로 캐시 검색 실패 시에만 사용하세요.""",
            "parameters": {
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "분석할 텍스트"
                    }
                },
                "required": ["text"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "recommend_routine",
            "description": """사용자의 감정 상태에 맞는 건강 루틴을 추천합니다.
            사용자가 어려움을 호소하거나 명시적으로 루틴을 요청할 때 사용하세요.""",
            "parameters": {
                "type": "object",
                "properties": {
                    "emotion_category": {
                        "type": "string",
                        "description": "감정 카테고리 (예: 'negative', 'stressed')"
                    },
                    "polarity": {
                        "type": "string",
                        "description": "감정 극성 (예: 'negative', 'positive', 'neutral')"
                    }
                },
                "required": ["emotion_category", "polarity"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "save_plan",
            "description": """사용자의 미래 계획이나 목표를 TB_AGENT_PLANS에 저장합니다.
            '내일 ~하려고 해', '~하기로 했어' 같은 의도 표현 시 사용하세요.""",
            "parameters": {
                "type": "object",
                "properties": {
                    "plan_type": {
                        "type": "string",
                        "enum": ["routine", "reminder", "goal", "suggestion"],
                        "description": "routine: 반복 활동, reminder: 일회성 알림, goal: 장기 목표, suggestion: AI 추천"
                    },
                    "target_date": {
                        "type": "string",
                        "description": "ISO 8601 형식 (예: 2025-12-05T07:00:00). null이면 즉시 제안"
                    },
                    "content": {
                        "type": "object",
                        "properties": {
                            "title": {"type": "string", "description": "계획 제목"},
                            "description": {"type": "string", "description": "상세 설명"}
                        },
                        "required": ["title", "description"]
                    }
                },
                "required": ["plan_type", "content"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "search_memory",
            "description": """사용자의 장기 기억(Global Memory)을 검색합니다.
            과거 대화 내용이나 사용자 정보가 필요할 때 사용하세요.""",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "검색 쿼리 (예: '가족관계', '건강상태')"
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
