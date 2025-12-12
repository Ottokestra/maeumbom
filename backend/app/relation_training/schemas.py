"""
Pydantic schemas for relation training service
Request/Response models for interactive scenario API
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime


# ============================================================================
# Option and Node Information Models
# ============================================================================

class OptionInfo(BaseModel):
    """
    Option information model
    
    Attributes:
        id: Option ID
        option_text: Text displayed to user
        option_code: Code for tracking (e.g., 'A', 'B', 'C')
    """
    id: int = Field(..., description="Option ID")
    option_text: str = Field(..., description="Option text")
    option_code: str = Field(..., description="Option code")
    
    class Config:
        from_attributes = True


class NodeInfo(BaseModel):
    """
    Node information model
    
    Attributes:
        id: Node ID
        step_level: Step level in scenario
        situation_text: Situation description
        image_url: Optional image URL
        options: Available options at this node
    """
    id: int = Field(..., description="Node ID")
    step_level: int = Field(..., description="Step level")
    situation_text: str = Field(..., description="Situation description")
    image_url: Optional[str] = Field(None, description="Image URL")
    options: List[OptionInfo] = Field(..., description="Available options")
    
    class Config:
        from_attributes = True


# ============================================================================
# Scenario List Models
# ============================================================================

class ScenarioListItem(BaseModel):
    """
    Scenario list item model
    
    Attributes:
        id: Scenario ID
        title: Scenario title
        target_type: Target relationship type
        category: Scenario category (TRAINING/DRAMA)
        start_image_url: Optional start image URL for thumbnail
        user_id: User ID (NULL for public scenarios)
    """
    id: int = Field(..., description="Scenario ID")
    title: str = Field(..., description="Scenario title")
    target_type: str = Field(..., description="Target relationship type")
    category: str = Field(..., description="Scenario category")
    start_image_url: Optional[str] = Field(None, description="Start image URL for thumbnail")
    user_id: Optional[int] = Field(None, description="User ID (NULL for public scenarios)")
    
    class Config:
        from_attributes = True


class ScenarioListResponse(BaseModel):
    """
    Scenario list response model
    
    Attributes:
        scenarios: List of scenarios
        total: Total number of scenarios
    """
    scenarios: List[ScenarioListItem] = Field(..., description="Scenario list")
    total: int = Field(..., description="Total count")


# ============================================================================
# Scenario Start Models
# ============================================================================

class ScenarioStartResponse(BaseModel):
    """
    Scenario start response model
    
    Attributes:
        scenario_id: Scenario ID
        scenario_title: Scenario title
        category: Scenario category
        start_image_url: Optional start image URL for the scenario
        first_node: First node information
    """
    scenario_id: int = Field(..., description="Scenario ID")
    scenario_title: str = Field(..., description="Scenario title")
    category: str = Field(..., description="Scenario category")
    start_image_url: Optional[str] = Field(None, description="Start image URL")
    first_node: NodeInfo = Field(..., description="First node information")


# ============================================================================
# Progress Models
# ============================================================================

class ProgressRequest(BaseModel):
    """
    Progress request model
    
    Attributes:
        scenario_id: Scenario ID
        current_node_id: Current node ID
        selected_option_code: Selected option code
        current_path: Current path taken (e.g., 'A-B-C')
    """
    scenario_id: int = Field(..., description="Scenario ID")
    current_node_id: int = Field(..., description="Current node ID")
    selected_option_code: str = Field(..., description="Selected option code")
    current_path: str = Field(..., description="Current path (e.g., 'A-B-C')")
    
    class Config:
        json_schema_extra = {
            "example": {
                "scenario_id": 1,
                "current_node_id": 1,
                "selected_option_code": "A",
                "current_path": "A"
            }
        }


class ResultStatItem(BaseModel):
    """
    Result statistics item for drama scenarios
    
    Attributes:
        result_id: Result ID
        result_code: Result code
        display_title: Result title
        percentage: Percentage of users who got this result
        count: Number of users who got this result
    """
    result_id: int = Field(..., description="Result ID")
    result_code: str = Field(..., description="Result code")
    display_title: str = Field(..., description="Result title")
    percentage: float = Field(..., description="Percentage (%)")
    count: int = Field(..., description="Count")


class ResultInfo(BaseModel):
    """
    Result information model
    
    Attributes:
        result_id: Result ID
        result_code: Result code
        display_title: Result title
        analysis_text: Detailed analysis
        atmosphere_image_type: Image type for atmosphere
        score: Score (0-100)
        image_url: Optional image URL for result (4컷만화 이미지)
        stats: Statistics (for drama scenarios only)
    """
    result_id: int = Field(..., description="Result ID")
    result_code: str = Field(..., description="Result code")
    display_title: str = Field(..., description="Result title")
    analysis_text: str = Field(..., description="Analysis text")
    atmosphere_image_type: Optional[str] = Field(None, description="Atmosphere image type")
    score: Optional[int] = Field(None, description="Score")
    image_url: Optional[str] = Field(None, description="Result image URL (4컷만화)")
    stats: Optional[List[ResultStatItem]] = Field(None, description="Statistics (drama only)")
    
    class Config:
        from_attributes = True


class ProgressResponse(BaseModel):
    """
    Progress response model
    
    Attributes:
        is_finished: Whether scenario is finished
        next_node: Next node information (if not finished)
        result: Result information (if finished)
        current_path: Updated path
    """
    is_finished: bool = Field(..., description="Whether scenario is finished")
    next_node: Optional[NodeInfo] = Field(None, description="Next node (if not finished)")
    result: Optional[ResultInfo] = Field(None, description="Result (if finished)")
    current_path: str = Field(..., description="Updated path")

