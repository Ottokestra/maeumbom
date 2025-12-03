"""
Business logic for relation training service
Handles scenario retrieval, progress processing, and statistics calculation
"""
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Dict, Optional, Any
from fastapi import HTTPException
from pathlib import Path
import json

from app.db.models import (
    Scenario, ScenarioNode, ScenarioOption, ScenarioResult, PlayLog
)
from .schemas import (
    ScenarioListItem, NodeInfo, OptionInfo, ResultInfo, ResultStatItem
)


# ============================================================================
# Scenario List Functions
# ============================================================================

def get_scenario_list(db: Session, category: Optional[str] = None, user_id: Optional[int] = None) -> List[Dict[str, Any]]:
    """
    Get list of scenarios
    
    Returns public scenarios (USER_ID IS NULL) and user's personalized scenarios (USER_ID = user_id)
    
    Args:
        db: Database session
        category: Optional category filter ('TRAINING' or 'DRAMA')
        user_id: Optional user ID for filtering personalized scenarios
        
    Returns:
        List of scenario dictionaries
    """
    from sqlalchemy import or_
    
    query = db.query(Scenario)
    
    # 공용 시나리오(USER_ID IS NULL) + 사용자 개인 시나리오(USER_ID = user_id)
    if user_id is not None:
        query = query.filter(
            or_(
                Scenario.USER_ID.is_(None),  # Public scenarios
                Scenario.USER_ID == user_id    # User's personalized scenarios
            )
        )
    else:
        # user_id가 없으면 공용 시나리오만 조회
        query = query.filter(Scenario.USER_ID.is_(None))
    
    if category:
        query = query.filter(Scenario.CATEGORY == category.upper())
    
    scenarios = query.all()
    
    # 디버깅 로그 (개발 모드)
    import os
    if os.getenv("DEBUG", "false").lower() == "true" or len(scenarios) == 0:
        print(f"[DEBUG] get_scenario_list: category={category}, user_id={user_id}, found {len(scenarios)} scenarios")
        if len(scenarios) == 0:
            # 시나리오가 없을 때 전체 시나리오 개수 확인
            total_count = db.query(Scenario).count()
            print(f"[DEBUG] Total scenarios in DB: {total_count}")
            if total_count > 0:
                all_scenarios = db.query(Scenario).all()
                print(f"[DEBUG] All scenarios: {[(s.ID, s.TITLE, s.CATEGORY, s.USER_ID) for s in all_scenarios]}")
    
    return [
        {
            "id": s.ID,
            "title": s.TITLE,
            "target_type": s.TARGET_TYPE,
            "category": s.CATEGORY,
            "start_image_url": s.START_IMAGE_URL
        }
        for s in scenarios
    ]


# ============================================================================
# Scenario Start Functions
# ============================================================================

def _get_start_image_url_from_json(scenario_title: str) -> Optional[str]:
    """
    JSON 파일에서 시나리오 시작 이미지 URL을 읽어옵니다.
    
    Args:
        scenario_title: 시나리오 제목
        
    Returns:
        시작 이미지 URL 또는 None
    """
    try:
        data_dir = Path(__file__).parent / "data"
        json_files = list(data_dir.glob("*.json"))
        
        for json_file in json_files:
            with open(json_file, 'r', encoding='utf-8') as f:
                json_data = json.load(f)
                
            if 'scenario' in json_data:
                scenario_data = json_data['scenario']
                if scenario_data.get('title') == scenario_title:
                    return scenario_data.get('start_image_url')
    except Exception:
        pass  # 파일을 찾지 못하거나 읽지 못해도 계속 진행
    
    return None


def get_first_node(db: Session, scenario_id: int) -> Dict[str, Any]:
    """
    Get first node of a scenario
    
    Args:
        db: Database session
        scenario_id: Scenario ID
        
    Returns:
        First node information with options
        
    Raises:
        HTTPException: If scenario or first node not found
    """
    # Check if scenario exists
    scenario = db.query(Scenario).filter(Scenario.ID == scenario_id).first()
    if not scenario:
        raise HTTPException(status_code=404, detail="Scenario not found")
    
    # Get start image URL from JSON file
    start_image_url = _get_start_image_url_from_json(scenario.TITLE)
    
    # Get first node (STEP_LEVEL = 1)
    first_node = db.query(ScenarioNode).filter(
        ScenarioNode.SCENARIO_ID == scenario_id,
        ScenarioNode.STEP_LEVEL == 1
    ).first()
    
    if not first_node:
        raise HTTPException(status_code=404, detail="First node not found for this scenario")
    
    # Get options for this node
    options = db.query(ScenarioOption).filter(
        ScenarioOption.NODE_ID == first_node.ID
    ).all()
    
    return {
        "scenario_id": scenario.ID,
        "scenario_title": scenario.TITLE,
        "category": scenario.CATEGORY,
        "start_image_url": start_image_url,
        "first_node": {
            "id": first_node.ID,
            "step_level": first_node.STEP_LEVEL,
            "situation_text": first_node.SITUATION_TEXT,
            "image_url": first_node.IMAGE_URL,
            "options": [
                {
                    "id": opt.ID,
                    "option_text": opt.OPTION_TEXT,
                    "option_code": opt.OPTION_CODE
                }
                for opt in options
            ]
        }
    }


# ============================================================================
# Progress Processing Functions
# ============================================================================

def process_progress(
    db: Session,
    user_id: int,
    scenario_id: int,
    current_node_id: int,
    selected_option_code: str,
    current_path: str
) -> Dict[str, Any]:
    """
    Process user's progress in scenario
    
    Args:
        db: Database session
        user_id: User ID
        scenario_id: Scenario ID
        current_node_id: Current node ID
        selected_option_code: Selected option code
        current_path: Current path (e.g., 'A-B')
        
    Returns:
        Next node information or final result
        
    Raises:
        HTTPException: If option not found or invalid
    """
    # Find selected option
    selected_option = db.query(ScenarioOption).filter(
        ScenarioOption.NODE_ID == current_node_id,
        ScenarioOption.OPTION_CODE == selected_option_code
    ).first()
    
    if not selected_option:
        raise HTTPException(
            status_code=404,
            detail=f"Option '{selected_option_code}' not found for node {current_node_id}"
        )
    
    # Update path
    updated_path = f"{current_path}-{selected_option_code}" if current_path else selected_option_code
    
    # Check if this is an ending option (NEXT_NODE_ID is NULL)
    if selected_option.NEXT_NODE_ID is None:
        # This is an ending - get result
        if not selected_option.RESULT_ID:
            raise HTTPException(
                status_code=500,
                detail="Ending option has no result assigned"
            )
        
        result = db.query(ScenarioResult).filter(
            ScenarioResult.ID == selected_option.RESULT_ID
        ).first()
        
        if not result:
            raise HTTPException(status_code=404, detail="Result not found")
        
        # Save play log
        save_play_log(db, user_id, scenario_id, result.ID, updated_path)
        
        # Get scenario to check category
        scenario = db.query(Scenario).filter(Scenario.ID == scenario_id).first()
        
        # Calculate stats if this is a drama scenario
        stats = None
        if scenario and scenario.CATEGORY == 'DRAMA':
            stats = calculate_stats(db, scenario_id)
        
        return {
            "is_finished": True,
            "next_node": None,
            "result": {
                "result_id": result.ID,
                "result_code": result.RESULT_CODE,
                "display_title": result.DISPLAY_TITLE,
                "analysis_text": result.ANALYSIS_TEXT,
                "atmosphere_image_type": result.ATMOSPHERE_IMAGE_TYPE,
                "score": result.SCORE,
                "image_url": result.IMAGE_URL,
                "stats": stats
            },
            "current_path": updated_path
        }
    
    # Not an ending - get next node
    next_node = db.query(ScenarioNode).filter(
        ScenarioNode.ID == selected_option.NEXT_NODE_ID
    ).first()
    
    if not next_node:
        raise HTTPException(status_code=404, detail="Next node not found")
    
    # Get options for next node
    next_options = db.query(ScenarioOption).filter(
        ScenarioOption.NODE_ID == next_node.ID
    ).all()
    
    return {
        "is_finished": False,
        "next_node": {
            "id": next_node.ID,
            "step_level": next_node.STEP_LEVEL,
            "situation_text": next_node.SITUATION_TEXT,
            "image_url": next_node.IMAGE_URL,
            "options": [
                {
                    "id": opt.ID,
                    "option_text": opt.OPTION_TEXT,
                    "option_code": opt.OPTION_CODE
                }
                for opt in next_options
            ]
        },
        "result": None,
        "current_path": updated_path
    }


# ============================================================================
# Statistics Functions
# ============================================================================

def calculate_stats(db: Session, scenario_id: int) -> List[Dict[str, Any]]:
    """
    Calculate statistics for drama scenarios
    Shows percentage of users who got each result
    
    Args:
        db: Database session
        scenario_id: Scenario ID
        
    Returns:
        List of result statistics
    """
    # Get total plays for this scenario
    total_plays = db.query(PlayLog).filter(
        PlayLog.SCENARIO_ID == scenario_id
    ).count()
    
    if total_plays == 0:
        # No plays yet - return all results with 0%
        results = db.query(ScenarioResult).filter(
            ScenarioResult.SCENARIO_ID == scenario_id
        ).all()
        
        return [
            {
                "result_id": r.ID,
                "result_code": r.RESULT_CODE,
                "display_title": r.DISPLAY_TITLE,
                "percentage": 0.0,
                "count": 0
            }
            for r in results
        ]
    
    # Get result counts
    result_counts = db.query(
        PlayLog.RESULT_ID,
        func.count(PlayLog.ID).label('count')
    ).filter(
        PlayLog.SCENARIO_ID == scenario_id
    ).group_by(PlayLog.RESULT_ID).all()
    
    # Create count dictionary
    count_dict = {result_id: count for result_id, count in result_counts}
    
    # Get all results for this scenario
    results = db.query(ScenarioResult).filter(
        ScenarioResult.SCENARIO_ID == scenario_id
    ).all()
    
    # Calculate percentages
    stats = []
    for result in results:
        count = count_dict.get(result.ID, 0)
        percentage = (count / total_plays * 100) if total_plays > 0 else 0.0
        
        stats.append({
            "result_id": result.ID,
            "result_code": result.RESULT_CODE,
            "display_title": result.DISPLAY_TITLE,
            "percentage": round(percentage, 2),
            "count": count
        })
    
    return stats


# ============================================================================
# Play Log Functions
# ============================================================================

def save_play_log(
    db: Session,
    user_id: int,
    scenario_id: int,
    result_id: int,
    path_code: str
) -> None:
    """
    Save play log to database
    
    Args:
        db: Database session
        user_id: User ID
        scenario_id: Scenario ID
        result_id: Result ID
        path_code: Path taken (e.g., 'A-B-C')
    """
    play_log = PlayLog(
        USER_ID=user_id,
        SCENARIO_ID=scenario_id,
        RESULT_ID=result_id,
        PATH_CODE=path_code
    )
    
    db.add(play_log)
    db.commit()
    db.refresh(play_log)

