"""
Pydantic schemas for Deep Agent Pipeline
Type-safe models for scenario generation and image creation
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime


# ============================================================================
# Request Models
# ============================================================================

class GenerateScenarioRequest(BaseModel):
    """
    Request model for scenario generation
    
    Attributes:
        target: Target relationship type (HUSBAND, CHILD, FRIEND, COLLEAGUE, ETC)
        topic: User's concern/topic description
    """
    target: str = Field(..., description="Target relationship type")
    topic: str = Field(..., description="User's concern description")
    
    class Config:
        json_schema_extra = {
            "example": {
                "target": "HUSBAND",
                "topic": "남편이 밥투정을 합니다"
            }
        }


# ============================================================================
# Scenario JSON Models (from LLM)
# ============================================================================

class CharacterDesign(BaseModel):
    """Character visual descriptions for image generation"""
    protagonist_visual: str = Field(..., description="Protagonist appearance (English)")
    target_visual: str = Field(..., description="Target person appearance (English)")


class ScenarioMeta(BaseModel):
    """Scenario metadata"""
    title: str = Field(..., description="Scenario title")
    target_type: str = Field(..., description="Target relationship type")
    category: str = Field(default="TRAINING", description="Scenario category")
    start_image_url: Optional[str] = Field(None, description="Start image URL")


class NodeData(BaseModel):
    """Node data from JSON"""
    id: str = Field(..., description="Node ID (e.g., 'node_1', 'node_2_a')")
    step_level: int = Field(..., description="Step level (1-4)")
    text: str = Field(..., description="Situation text")
    image_url: Optional[str] = Field(default="", description="Image URL")


class OptionData(BaseModel):
    """Option data from JSON"""
    from_node_id: str = Field(..., description="Source node ID")
    option_code: str = Field(..., description="Option code (A, B)")
    text: str = Field(..., description="Option text")
    to_node_id: Optional[str] = Field(None, description="Next node ID")
    result_code: Optional[str] = Field(None, description="Result code if ending")


class ResultData(BaseModel):
    """Result data from JSON"""
    result_code: str = Field(..., description="Result code (AAAA~BBBB)")
    display_title: str = Field(..., description="Result title")
    analysis_text: str = Field(..., description="Analysis text")
    atmosphere_image_type: str = Field(..., description="Atmosphere type (STORM, CLOUDY, SUNNY, FLOWER)")
    score: int = Field(..., description="Score (0-100)")
    image_url: Optional[str] = Field(None, description="Result image URL")


class ScenarioJSON(BaseModel):
    """
    Complete scenario JSON structure from LLM
    
    This matches the output format from scenario_architect.md
    """
    scenario: ScenarioMeta
    character_design: Optional[CharacterDesign] = None
    nodes: List[NodeData]
    options: List[OptionData]
    results: List[ResultData]
    
    def validate_structure(self) -> bool:
        """Validate scenario structure"""
        if len(self.nodes) != 15:
            raise ValueError(f"Expected 15 nodes, got {len(self.nodes)}")
        if len(self.options) != 30:
            raise ValueError(f"Expected 30 options, got {len(self.options)}")
        if len(self.results) != 16:
            raise ValueError(f"Expected 16 results, got {len(self.results)}")
        return True


# ============================================================================
# Image Generation Models
# ============================================================================

class ImageGenerationTask(BaseModel):
    """Task for image generation"""
    image_type: str = Field(..., description="Image type (start or result)")
    prompt: str = Field(..., description="English prompt for FLUX.1")
    output_path: str = Field(..., description="Output file path")
    result_code: Optional[str] = Field(None, description="Result code if result image")


# ============================================================================
# Response Models
# ============================================================================

class GenerateScenarioResponse(BaseModel):
    """
    Response model for scenario generation
    
    Attributes:
        scenario_id: Generated scenario ID
        status: Generation status
        image_count: Number of images generated
        folder_name: Folder name where images are stored
    """
    scenario_id: int = Field(..., description="Scenario ID")
    status: str = Field(..., description="Generation status")
    image_count: int = Field(..., description="Number of images generated")
    folder_name: str = Field(..., description="Folder name")
    message: Optional[str] = Field(None, description="Additional message")
    
    class Config:
        json_schema_extra = {
            "example": {
                "scenario_id": 123,
                "status": "completed",
                "image_count": 17,
                "folder_name": "husband_20231215_143022",
                "message": "시나리오와 이미지가 성공적으로 생성되었습니다."
            }
        }


# ============================================================================
# Internal Models
# ============================================================================

class NodePath(BaseModel):
    """Path information for result code"""
    result_code: str = Field(..., description="Result code (AAAA~BBBB)")
    node_ids: List[str] = Field(..., description="Node IDs in path")
    node_texts: List[str] = Field(..., description="Node texts in path")
    
    def get_summary(self) -> str:
        """Get summary of the path for image generation"""
        return " → ".join(self.node_texts)


class NodeIDMapping(BaseModel):
    """Mapping between JSON node IDs and DB IDs"""
    json_id: str = Field(..., description="JSON node ID (e.g., 'node_1')")
    db_id: int = Field(..., description="Database node ID")

