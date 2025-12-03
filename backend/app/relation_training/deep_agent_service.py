"""
Deep Agent Service - Brain + Hands + Persistence
Orchestrates scenario generation, image creation, and database storage
"""
import os
import json
import asyncio
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional, Tuple
from sqlalchemy.orm import Session
from tenacity import retry, stop_after_attempt, wait_exponential
import openai

from .deep_agent_schemas import (
    GenerateScenarioRequest,
    ScenarioJSON,
    NodePath,
    CharacterDesign
)
from .prompt_utils import load_prompt, extract_json_from_response, validate_scenario_json
from .path_tracker import extract_all_paths, generate_result_code_list, summarize_path
from .image_generator import generate_start_image, generate_result_images
from app.db.models import Scenario, ScenarioNode, ScenarioOption, ScenarioResult


class DeepAgentService:
    """
    Deep Agent Pipeline Service
    
    Orchestrates:
    1. Brain: Scenario generation with GPT-4o-mini
    2. Hands: Image generation with FLUX.1-schnell
    3. Persistence: JSON file + Database storage
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.openai_api_key = os.getenv("OPENAI_API_KEY")
        if not self.openai_api_key:
            raise ValueError("OPENAI_API_KEY not found in environment variables")
        
        openai.api_key = self.openai_api_key
    
    # ========================================================================
    # Phase 1: The Brain (Scenario Generation)
    # ========================================================================
    
    async def generate_scenario_json(
        self,
        target: str,
        topic: str
    ) -> ScenarioJSON:
        """
        Generate scenario JSON using GPT-4o-mini with validation and补完 logic
        
        Args:
            target: Target relationship type
            topic: User's concern
        
        Returns:
            ScenarioJSON object
        
        Raises:
            Exception: If generation fails after retries
        """
        print("[Brain] 시나리오 생성 시작...")
        
        # Step 1: Initial generation
        scenario_json = await self._generate_initial_scenario(target, topic)
        
        # Step 2: Validate and补完 if needed
        scenario_json = await self._validate_and_complete(scenario_json, target, topic)
        
        print("[Brain] ✅ 시나리오 생성 완료 (검증 완료)")
        return scenario_json
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def _generate_initial_scenario(
        self,
        target: str,
        topic: str
    ) -> ScenarioJSON:
        """
        Generate initial scenario (1st attempt)
        """
        print("[Brain] 1단계: 전체 시나리오 생성 시도...")
        
        # Load prompt
        prompt = load_prompt(
            "scenario_architect.md",
            {
                "TARGET": target,
                "TOPIC": topic
            }
        )
        
        # Call OpenAI API
        try:
            print("[Brain] OpenAI API 호출 중...")
            response = await asyncio.to_thread(
                openai.chat.completions.create,
                model=os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
                messages=[
                    {"role": "system", "content": "You are a professional scenario designer and psychologist."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.8,
                max_tokens=4000
            )
            
            print("[Brain] OpenAI API 응답 받음")
            response_text = response.choices[0].message.content
            print(f"[Brain] 응답 길이: {len(response_text) if response_text else 0} 문자")
            
            # Extract JSON
            json_str = extract_json_from_response(response_text)
            print(f"[Brain] JSON 추출 완료: {len(json_str)} 문자")
            
            # Parse JSON
            print("[Brain] JSON 파싱 시도...")
            data = json.loads(json_str)
            print("[Brain] JSON 파싱 성공")
            
            # Convert to Pydantic model
            scenario_json = ScenarioJSON(**data)
            
            print(f"[Brain] 1단계 완료 - Nodes: {len(scenario_json.nodes)}, Options: {len(scenario_json.options)}, Results: {len(scenario_json.results)}")
            return scenario_json
            
        except json.JSONDecodeError as e:
            print(f"[Brain] ❌ JSON 파싱 실패: {e}")
            raise
        except Exception as e:
            print(f"[Brain] ❌ 예상치 못한 오류: {type(e).__name__}: {e}")
            raise
    
    async def _validate_and_complete(
        self,
        scenario_json: ScenarioJSON,
        target: str,
        topic: str,
        max_attempts: int = 2
    ) -> ScenarioJSON:
        """
        Validate scenario structure and complete missing parts
        
        Args:
            scenario_json: Initial scenario
            target: Target type
            topic: Topic
            max_attempts: Maximum补완 attempts
        
        Returns:
            Completed scenario
        """
        print("[Brain] 2단계: 구조 검증 및 보완...")
        
        for attempt in range(max_attempts):
            # Check what's missing
            missing_nodes = max(0, 15 - len(scenario_json.nodes))
            missing_options = max(0, 30 - len(scenario_json.options))
            missing_results = max(0, 16 - len(scenario_json.results))
            
            if missing_nodes == 0 and missing_options == 0 and missing_results == 0:
                print("[Brain] ✅ 구조 검증 통과 (15-30-16)")
                return scenario_json
            
            print(f"[Brain] ⚠️ 부족한 요소 발견 (시도 {attempt + 1}/{max_attempts})")
            print(f"  - Nodes: {len(scenario_json.nodes)}/15 (부족: {missing_nodes})")
            print(f"  - Options: {len(scenario_json.options)}/30 (부족: {missing_options})")
            print(f"  - Results: {len(scenario_json.results)}/16 (부족: {missing_results})")
            
            # Generate补완 prompt
            scenario_json = await self._complete_missing_parts(
                scenario_json,
                target,
                topic,
                missing_nodes,
                missing_options,
                missing_results
            )
        
        # Final check
        print(f"[Brain] ⚠️ 최종 상태: Nodes: {len(scenario_json.nodes)}/15, Options: {len(scenario_json.options)}/30, Results: {len(scenario_json.results)}/16")
        print("[Brain] 보완 시도 완료 (일부 부족할 수 있음)")
        return scenario_json
    
    async def _complete_missing_parts(
        self,
        scenario_json: ScenarioJSON,
        target: str,
        topic: str,
        missing_nodes: int,
        missing_options: int,
        missing_results: int
    ) -> ScenarioJSON:
        """
        Generate missing parts using LLM (범용 보완 로직)
        """
        print("[Brain] 3단계: 부족한 부분 추가 생성...")
        
        # 1. 부족한 항목 파악
        missing_items = []
        if missing_nodes > 0:
            missing_items.append(f"- Nodes: {missing_nodes}개")
        if missing_options > 0:
            missing_items.append(f"- Options: {missing_options}개")
        if missing_results > 0:
            missing_items.append(f"- Results: {missing_results}개")
        
        # 2. 스키마 정의
        schema_guide = """
**필수 JSON 스키마 (정확히 이 필드명을 사용하세요!):**

Node 스키마:
{
  "id": "node_1",
  "step_level": 1,
  "text": "상황 텍스트",
  "image_url": null
}

Option 스키마:
{
  "from_node_id": "node_1",
  "to_node_id": "node_2_a",
  "option_code": "A",
  "text": "선택지 텍스트",
  "result_code": null
}

Result 스키마:
{
  "result_code": "AAAA",
  "display_title": "제목",
  "analysis_text": "분석 텍스트",
  "atmosphere_image_type": "SUNNY",
  "score": 85
}
"""
        
        # 3. 기존 데이터 샘플 (참고용)
        existing_sample = json.dumps(scenario_json.model_dump(), ensure_ascii=False, indent=2)[:1500]
        
        # 4. 보완 프롬프트
        complete_prompt = f"""
다음 시나리오에 부족한 항목만 추가로 생성해주세요.

**시나리오 정보:**
- 제목: {scenario_json.scenario.title}
- Target: {target}
- Topic: {topic}

**현재 상태:**
- Nodes: {len(scenario_json.nodes)}/15
- Options: {len(scenario_json.options)}/30
- Results: {len(scenario_json.results)}/16

**부족한 항목:**
{chr(10).join(missing_items)}

{schema_guide}

**기존 데이터 샘플 (참고용):**
{existing_sample}
...

**중요 규칙:**
1. 위 스키마의 필드명을 정확히 사용하세요 (from_node_id, to_node_id, option_code, result_code 등)
2. 기존 시나리오와 주제/스타일/톤을 일관되게 유지하세요
3. 부족한 항목을 추가하되, 기존 전체 데이터에 병합하여 출력하세요
4. 노드 ID는 기존과 겹치지 않게 생성하세요
5. 순수 JSON만 출력 (코드 블록 없이)

**출력 형식:**
완전한 시나리오 JSON (기존 데이터 + 새로 추가된 데이터)
"""
        
        try:
            response = await asyncio.to_thread(
                openai.chat.completions.create,
                model=os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
                messages=[
                    {"role": "system", "content": "You are a professional scenario designer. Complete the missing parts while maintaining consistency with existing data. Use exact field names from the schema."},
                    {"role": "user", "content": complete_prompt}
                ],
                temperature=0.7,
                max_tokens=4000
            )
            
            response_text = response.choices[0].message.content
            json_str = extract_json_from_response(response_text)
            data = json.loads(json_str)
            
            # Update scenario
            completed_scenario = ScenarioJSON(**data)
            print(f"[Brain] 보완 완료 - Nodes: {len(completed_scenario.nodes)}, Options: {len(completed_scenario.options)}, Results: {len(completed_scenario.results)}")
            
            return completed_scenario
            
        except Exception as e:
            print(f"[Brain] ⚠️ 보완 실패: {e}")
            # Return original if 보완 fails
            return scenario_json
    
    # ========================================================================
    # Phase 2: The Hands (Image Generation)
    # ========================================================================
    
    async def generate_image_prompts(
        self,
        scenario_json: ScenarioJSON
    ) -> Tuple[str, Dict[str, str]]:
        """
        Generate image prompts using cartoon_director.md
        
        Args:
            scenario_json: Scenario JSON data
        
        Returns:
            Tuple of (start_image_prompt, {result_code: prompt})
        """
        print("[Hands] 이미지 프롬프트 생성 시작...")
        
        # Get character design
        char_design = scenario_json.character_design
        if not char_design:
            # Create default character design
            char_design = CharacterDesign(
                protagonist_visual="Korean woman, 50s, casual clothes",
                target_visual="Korean person, casual clothes"
            )
        
        # Extract paths for all result codes
        result_codes = generate_result_code_list()
        paths = extract_all_paths(
            result_codes,
            scenario_json.nodes,
            scenario_json.options
        )
        
        # Generate start image prompt
        start_prompt = await self._generate_single_image_prompt(
            image_type="START_IMAGE",
            scenario_context=scenario_json.nodes[0].text,
            mood="NEUTRAL",
            char_design=char_design
        )
        
        # Generate result image prompts
        result_prompts = {}
        for path in paths:
            if not path.node_texts:
                continue
            
            # Get mood from result
            result_data = next(
                (r for r in scenario_json.results if r.result_code == path.result_code),
                None
            )
            mood = result_data.atmosphere_image_type if result_data else "NEUTRAL"
            
            # Summarize path
            context = summarize_path(path.node_texts)
            
            # Generate prompt
            prompt = await self._generate_single_image_prompt(
                image_type="COMIC_STRIP",
                scenario_context=context,
                mood=mood,
                char_design=char_design
            )
            
            result_prompts[path.result_code] = prompt
        
        print(f"[Hands] 이미지 프롬프트 생성 완료 (총 {len(result_prompts) + 1}개)")
        return start_prompt, result_prompts
    
    async def _generate_single_image_prompt(
        self,
        image_type: str,
        scenario_context: str,
        mood: str,
        char_design: CharacterDesign
    ) -> str:
        """
        Generate single image prompt using cartoon_director.md
        
        Args:
            image_type: START_IMAGE or COMIC_STRIP
            scenario_context: Korean text summary
            mood: STORM, CLOUDY, SUNNY, FLOWER
            char_design: Character design
        
        Returns:
            English prompt for FLUX.1
        """
        # Load cartoon director prompt
        prompt_template = load_prompt(
            "cartoon_director.md",
            {
                "Type": image_type,
                "Scenario Context": scenario_context,
                "Mood": mood,
                "Protagonist Description": char_design.protagonist_visual,
                "Target Description": char_design.target_visual
            }
        )
        
        # Call OpenAI to convert to English prompt
        try:
            response = await asyncio.to_thread(
                openai.chat.completions.create,
                model=os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini"),
                messages=[
                    {"role": "system", "content": "You are an expert webtoon artist prompt engineer."},
                    {"role": "user", "content": prompt_template}
                ],
                temperature=0.7,
                max_tokens=500
            )
            
            english_prompt = response.choices[0].message.content.strip()
            return english_prompt
            
        except Exception as e:
            print(f"[Hands] 프롬프트 생성 실패: {e}")
            # Return fallback prompt
            return f"A {image_type.lower()} illustration showing {scenario_context[:100]}"
    
    async def generate_all_images(
        self,
        scenario_json: ScenarioJSON,
        user_id: int,
        folder_name: str
    ) -> Tuple[Optional[str], Dict[str, Optional[str]]]:
        """
        Generate all images (1 start + 16 results)
        
        Args:
            scenario_json: Scenario JSON data
            user_id: User ID
            folder_name: Folder name
        
        Returns:
            Tuple of (start_image_url, {result_code: image_url})
        """
        print("[Hands] 이미지 생성 시작...")
        
        # Generate prompts
        start_prompt, result_prompts = await self.generate_image_prompts(scenario_json)
        
        # Generate start image
        start_url = await generate_start_image(start_prompt, user_id, folder_name)
        
        # Generate result images
        result_urls = await generate_result_images(result_prompts, user_id, folder_name)
        
        print("[Hands] 이미지 생성 완료")
        return start_url, result_urls
    
    # ========================================================================
    # Phase 3: Persistence (Storage)
    # ========================================================================
    
    def save_json_file(
        self,
        scenario_json: ScenarioJSON,
        user_id: int,
        folder_name: str
    ) -> Path:
        """
        Save scenario JSON to file
        
        Args:
            scenario_json: Scenario JSON data
            user_id: User ID
            folder_name: Folder name
        
        Returns:
            Path to saved file
        """
        print("[Persistence] JSON 파일 저장 중...")
        
        # Determine output path
        data_dir = Path(__file__).parent / "data" / str(user_id)
        data_dir.mkdir(parents=True, exist_ok=True)
        
        output_path = data_dir / f"{folder_name}.json"
        
        # Save JSON
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(scenario_json.model_dump(), f, ensure_ascii=False, indent=2)
        
        print(f"[Persistence] JSON 파일 저장 완료: {output_path}")
        return output_path
    
    def save_to_database(
        self,
        scenario_json: ScenarioJSON,
        user_id: int,
        start_image_url: Optional[str],
        result_image_urls: Dict[str, Optional[str]]
    ) -> int:
        """
        Save scenario to database
        
        Args:
            scenario_json: Scenario JSON data
            user_id: User ID
            start_image_url: Start image URL
            result_image_urls: Result image URLs
        
        Returns:
            Scenario ID
        """
        print("[Persistence] DB 저장 중...")
        
        try:
            # 1. Save scenario
            scenario = Scenario(
                USER_ID=user_id,
                TITLE=scenario_json.scenario.title,
                TARGET_TYPE=scenario_json.scenario.target_type,
                CATEGORY=scenario_json.scenario.category,
                START_IMAGE_URL=start_image_url
            )
            self.db.add(scenario)
            self.db.flush()  # Get ID
            
            scenario_id = scenario.ID
            print(f"[Persistence] Scenario 저장 완료 (ID: {scenario_id})")
            
            # 2. Save nodes with ID mapping
            node_id_map = {}  # JSON ID -> DB ID
            
            for node_data in scenario_json.nodes:
                node = ScenarioNode(
                    SCENARIO_ID=scenario_id,
                    STEP_LEVEL=node_data.step_level,
                    SITUATION_TEXT=node_data.text,  # text -> SITUATION_TEXT
                    IMAGE_URL=node_data.image_url or None
                )
                self.db.add(node)
                self.db.flush()
                
                node_id_map[node_data.id] = node.ID
            
            print(f"[Persistence] Nodes 저장 완료 ({len(node_id_map)}개)")
            
            # 3. Save results with ID mapping
            result_id_map = {}  # result_code -> DB ID
            
            for result_data in scenario_json.results:
                result = ScenarioResult(
                    SCENARIO_ID=scenario_id,
                    RESULT_CODE=result_data.result_code,
                    DISPLAY_TITLE=result_data.display_title,
                    ANALYSIS_TEXT=result_data.analysis_text,
                    ATMOSPHERE_IMAGE_TYPE=result_data.atmosphere_image_type,
                    SCORE=result_data.score,
                    IMAGE_URL=result_image_urls.get(result_data.result_code)
                )
                self.db.add(result)
                self.db.flush()
                
                result_id_map[result_data.result_code] = result.ID
            
            print(f"[Persistence] Results 저장 완료 ({len(result_id_map)}개)")
            
            # 4. Save options
            for option_data in scenario_json.options:
                # Map node IDs
                node_id = node_id_map.get(option_data.from_node_id)
                next_node_id = node_id_map.get(option_data.to_node_id) if option_data.to_node_id else None
                result_id = result_id_map.get(option_data.result_code) if option_data.result_code else None
                
                if not node_id:
                    print(f"[Persistence] Warning: Node ID not found for {option_data.from_node_id}")
                    continue
                
                option = ScenarioOption(
                    NODE_ID=node_id,
                    OPTION_TEXT=option_data.text,  # text -> OPTION_TEXT
                    OPTION_CODE=option_data.option_code,
                    NEXT_NODE_ID=next_node_id,
                    RESULT_ID=result_id
                )
                self.db.add(option)
            
            print(f"[Persistence] Options 저장 완료 ({len(scenario_json.options)}개)")
            
            # Commit all
            self.db.commit()
            print("[Persistence] DB 저장 완료")
            
            return scenario_id
            
        except Exception as e:
            self.db.rollback()
            print(f"[Persistence] DB 저장 실패: {e}")
            raise
    
    # ========================================================================
    # Main Pipeline
    # ========================================================================
    
    async def generate_scenario(
        self,
        request: GenerateScenarioRequest,
        user_id: int
    ) -> Dict:
        """
        Main pipeline: Generate scenario with images
        
        Args:
            request: Generation request
            user_id: User ID
        
        Returns:
            Generation result
        """
        print("=" * 60)
        print("Deep Agent Pipeline 시작")
        print(f"Target: {request.target}, Topic: {request.topic}")
        print("=" * 60)
        
        try:
            # Generate folder name
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            folder_name = f"{request.target.lower()}_{timestamp}"
            
            # Phase 1: Brain (Scenario Generation)
            scenario_json = await self.generate_scenario_json(
                request.target,
                request.topic
            )
            
            # Phase 2: Hands (Image Generation)
            start_url, result_urls = await self.generate_all_images(
                scenario_json,
                user_id,
                folder_name
            )
            
            # Phase 3: Persistence (Storage)
            # Save JSON file
            self.save_json_file(scenario_json, user_id, folder_name)
            
            # Save to database
            scenario_id = self.save_to_database(
                scenario_json,
                user_id,
                start_url,
                result_urls
            )
            
            # Count generated images
            image_count = (1 if start_url else 0) + sum(1 for url in result_urls.values() if url)
            
            print("=" * 60)
            print("Deep Agent Pipeline 완료")
            print(f"Scenario ID: {scenario_id}")
            print(f"Images: {image_count}/17")
            print("=" * 60)
            
            return {
                "scenario_id": scenario_id,
                "status": "completed",
                "image_count": image_count,
                "folder_name": folder_name,
                "message": "시나리오와 이미지가 성공적으로 생성되었습니다."
            }
            
        except Exception as e:
            print("=" * 60)
            print(f"Deep Agent Pipeline 실패: {e}")
            print("=" * 60)
            raise

