"""
Deep Agent Service - Scenario Generation with Gemini
Orchestrates scenario generation using scenario_architect.md prompt
"""
import os
import json
import asyncio
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional, List
from sqlalchemy.orm import Session
from tenacity import retry, stop_after_attempt, wait_exponential
import openai

from .deep_agent_schemas import (
    GenerateScenarioRequest,
    ScenarioJSON,
    CharacterDesign,
    NodeData,
    OptionData,
    ResultData,
    ScenarioMeta
)
from .prompt_utils import load_prompt_sections, extract_json_from_response, validate_scenario_json
from .image_generator import generate_start_image, generate_result_images
from app.db.models import Scenario, ScenarioNode, ScenarioOption, ScenarioResult


def calculate_atmosphere_from_labels(health_level: str, trend: str) -> str:
    """
    Calculate atmosphere type based on relationship labels.
    
    Args:
        health_level: Relationship health level (GOOD/MIXED/BAD)
        trend: Relationship trend (IMPROVING/STABLE/WORSENING)
    
    Returns:
        Atmosphere type: STORM, CLOUDY, SUNNY, or FLOWER
    """
    if health_level == "GOOD" and trend == "IMPROVING":
        return "FLOWER"
    elif health_level == "GOOD" or (health_level == "MIXED" and trend == "IMPROVING"):
        return "SUNNY"
    elif health_level == "MIXED" or (health_level == "BAD" and trend == "STABLE"):
        return "CLOUDY"
    else:  # BAD or WORSENING
        return "STORM"


class DeepAgentService:
    """
    Deep Agent Pipeline Service - Single Prompt Generation
    
    Architecture:
    - Gemini: Generates scenario content (scenario_architect.md 사용)
    - GPT-4o-mini: Orchestration (프롬프트 준비, 검증, 파싱)
    """
    
    def __init__(self, db: Session):
        self.db = db
        
        # OpenAI API - Used for orchestration (프롬프트 준비, 검증, 파싱)
        self.openai_api_key = os.getenv("OPENAI_API_KEY")
        if not self.openai_api_key:
            raise ValueError("OPENAI_API_KEY not found in environment variables")
        
        openai.api_key = self.openai_api_key
        self.orchestrator_model = os.getenv("OPENAI_MODEL_NAME", "gpt-4o-mini")
        
        # Scenario Generation Model - Gemini or OpenAI
        self.scenario_model_name = os.getenv("SCENARIO_GENERATION_MODEL_NAME", "gemini-1.5-pro")
        self.use_gemini = self.scenario_model_name.lower().startswith("gemini")
        
        if self.use_gemini:
            # Gemini API 설정
            self.gemini_api_key = os.getenv("GEMINI_API_KEY")
            if not self.gemini_api_key:
                raise ValueError("GEMINI_API_KEY not found in environment variables (required for Gemini)")
            
            try:
                import google.generativeai as genai
                genai.configure(api_key=self.gemini_api_key)
                self.gemini_client = genai
                print(f"[Deep Agent] Scenario Generation Model: {self.scenario_model_name} (Gemini)")
            except ImportError:
                raise ImportError("google-generativeai package not installed. Run: pip install google-generativeai")
        else:
            # OpenAI API 사용 (fallback)
            self.gemini_client = None
            print(f"[Deep Agent] Scenario Generation Model: {self.scenario_model_name} (OpenAI)")
        
        print(f"[Deep Agent] Orchestration Model: {self.orchestrator_model} (GPT-4o-mini)")
    
    # ========================================================================
    # Main Entry Point (Full Pipeline)
    # ========================================================================
    
    async def generate_scenario(
        self,
        request: GenerateScenarioRequest,
        user_id: int
    ) -> Dict:
        """
        Complete Deep Agent Pipeline: Generate + Save scenario.
        
        This is the main entry point called by routes.py.
        
        Args:
            request: GenerateScenarioRequest with target and topic
            user_id: User ID
        
        Returns:
            Dictionary with scenario_id and status
        """
        print(f"\n{'='*80}")
        print(f"[Deep Agent Pipeline] 전체 파이프라인 시작")
        print(f"[Deep Agent Pipeline] User: {user_id}, Target: {request.target}, Topic: {request.topic}")
        print(f"{'='*80}\n")
        
        # Phase 1: Generate scenario JSON (scenario_architect.md 사용)
        scenario_json = await self.generate_scenario_json(request.target, request.topic)
        
        # Phase 2: Generate folder name from title (하이브리드 방식)
        folder_name = self._generate_folder_name_from_title(scenario_json.scenario.title)
        
        # Phase 3: Generate images (optional, based on env var)
        image_urls = await self.generate_images(scenario_json, folder_name, user_id)
        
        # Phase 4: Save to JSON file and database
        scenario_id = await self.save_scenario(scenario_json, user_id, folder_name)
        
        print(f"\n{'='*80}")
        print(f"[Deep Agent Pipeline] 전체 파이프라인 완료!")
        print(f"[Deep Agent Pipeline] Scenario ID: {scenario_id}")
        print(f"[Deep Agent Pipeline] Images: {len(image_urls)}장")
        print(f"{'='*80}\n")
        
        return {
            "scenario_id": scenario_id,
            "status": "completed",
            "image_count": len(image_urls),
            "folder_name": folder_name
        }
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def generate_scenario_json(
        self,
        target: str,
        topic: str
    ) -> ScenarioJSON:
        """
        Generate complete scenario JSON using scenario_architect.md prompt.
        
        Args:
            target: Target relationship type (HUSBAND, CHILD, etc.)
            topic: User's concern description
        
        Returns:
            Complete ScenarioJSON object
        """
        print(f"\n{'='*60}")
        print(f"[Deep Agent] 시나리오 생성 시작 (scenario_architect.md 사용)")
        print(f"[Deep Agent] Target: {target}, Topic: {topic}")
        print(f"{'='*60}\n")
        
        # Load scenario_architect.md prompt
        from .prompt_utils import load_prompt_sections
        system_prompt, user_prompt = load_prompt_sections(
            "scenario_architect.md",
            {
                "target": target,
                "topic": topic
            }
        )
        
        # Generate scenario JSON with Gemini or OpenAI
        print(f"[Deep Agent] 시나리오 생성 중... (Model: {self.scenario_model_name})")
        
        if self.use_gemini:
            content = await self._generate_with_gemini(system_prompt, user_prompt)
        else:
            content = await self._generate_with_openai(system_prompt, user_prompt)
        
        # Parse JSON response
        json_str = extract_json_from_response(content)
        data = json.loads(json_str)
        
        # Validate structure
        validate_scenario_json(data)
        
        # Convert to Pydantic models
        scenario_json = ScenarioJSON(**data)
        
        # Auto-calculate atmosphere from labels
        self._fill_atmosphere_from_labels(scenario_json)
        
        # Final validation
        scenario_json.validate_structure()
        
        print(f"\n{'='*60}")
        print(f"[Deep Agent] 시나리오 생성 완료!")
        print(f"{'='*60}\n")
        
        return scenario_json
    
    async def _generate_with_gemini(self, system_prompt: str, user_prompt: str) -> str:
        """Generate scenario using Gemini API."""
        try:
            import google.generativeai as genai
            model = genai.GenerativeModel(self.scenario_model_name)
            
            # Gemini는 system prompt와 user prompt를 하나의 프롬프트로 합침
            # JSON 생성 요청을 명확히 함
            full_prompt = f"""{system_prompt}

{user_prompt}

중요: 반드시 유효한 JSON 객체만 반환하세요. 마크다운 코드 블록이나 설명 없이 순수 JSON만 반환해야 합니다."""
            
            # JSON 생성 모드 설정
            generation_config = {
                "temperature": 0.8,
                "max_output_tokens": 16000,
            }
            
            response = await asyncio.to_thread(
                model.generate_content,
                full_prompt,
                generation_config=generation_config
            )
            
            content = response.text.strip()
            
            # Gemini 응답에서 JSON 추출 (코드 블록 제거)
            if content.startswith('```'):
                # 마크다운 코드 블록 제거
                import re
                pattern = r'```(?:json)?\s*(.*?)\s*```'
                matches = re.findall(pattern, content, re.DOTALL)
                if matches:
                    content = matches[0].strip()
            
            print(f"[Gemini] ✅ 생성 완료: {len(content)} 문자")
            
            return content
            
        except Exception as e:
            print(f"[Gemini] ❌ 생성 실패: {e}")
            import traceback
            traceback.print_exc()
            raise RuntimeError(f"Gemini generation failed: {e}")
    
    async def _generate_with_openai(self, system_prompt: str, user_prompt: str) -> str:
        """Generate scenario using OpenAI API (fallback)."""
        try:
            response = await asyncio.to_thread(
                openai.chat.completions.create,
                model=self.scenario_model_name,
                response_format={"type": "json_object"},
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.8,
                max_tokens=16000
            )
            
            content = response.choices[0].message.content
            print(f"[OpenAI] ✅ 생성 완료: {len(content)} 문자")
            
            return content
            
        except Exception as e:
            print(f"[OpenAI] ❌ 생성 실패: {e}")
            raise RuntimeError(f"OpenAI generation failed: {e}")
    
    def _generate_folder_name_from_title(self, title: str) -> str:
        """
        Generate folder name from scenario title (하이브리드 방식).
        
        Args:
            title: Scenario title (한글 가능)
        
        Returns:
            Folder name in format: {title_변환}_{timestamp}
        """
        # 타이틀을 파일명에 적합하게 변환
        # 1. 특수문자 제거/변환
        folder_part = re.sub(r'[<>:"/\\|?*]', '', title)  # Windows/Linux 파일명 금지 문자 제거
        
        # 2. 공백을 언더스코어로 변경
        folder_part = re.sub(r'\s+', '_', folder_part)
        
        # 3. 길이 제한 (50자)
        if len(folder_part) > 50:
            folder_part = folder_part[:50]
        
        # 4. 타임스탬프 추가
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        folder_name = f"{folder_part}_{timestamp}"
        
        return folder_name
    
    # ========================================================================
    # STEP 0: Character Design
    # ========================================================================
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def _generate_character_design(
        self,
        target: str,
        topic: str
    ) -> CharacterDesign:
        """
        STEP 0: Generate character visual descriptions using GPT-4o-mini
        """
        # Load and prepare prompts
        system_prompt, user_prompt = load_prompt_sections(
            "step0_character_design.md",
            {
                "target": target,
                "topic": topic
            }
        )
        
        try:
            # Generate character design with GPT-4o-mini
            response = await asyncio.to_thread(
                openai.chat.completions.create,
                model=self.orchestrator_model,
                response_format={"type": "json_object"},
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.8,
                max_tokens=500
            )
            content = response.choices[0].message.content
            
            # Parse and validate
            json_str = extract_json_from_response(content)
            data = json.loads(json_str)
            
            # Validate required fields
            if "protagonist_visual" not in data or "target_visual" not in data:
                raise ValueError("Character design missing required fields")
            
            return CharacterDesign(**data)
            
        except Exception as e:
            print(f"[STEP 0] ❌ 에러: {e}")
            raise
    
    # ========================================================================
    # STEP 1: Nodes (15개)
    # ========================================================================
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def _generate_nodes(
        self,
        target: str,
        topic: str,
        character_design: CharacterDesign
    ) -> List[NodeData]:
        """
        STEP 1: Generate 15 nodes using GPT-4o-mini
        """
        # Load and prepare prompts
        system_prompt, user_prompt = load_prompt_sections(
            "step1_nodes.md",
            {
                "target": target,
                "topic": topic,
                "protagonist_visual": character_design.protagonist_visual,
                "target_visual": character_design.target_visual
            }
        )
        
        try:
            # Generate nodes with GPT-4o-mini
            response = await asyncio.to_thread(
                openai.chat.completions.create,
                model=self.orchestrator_model,
                response_format={"type": "json_object"},
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.8,
                max_tokens=4000
            )
            content = response.choices[0].message.content
            
            # Parse
            json_str = extract_json_from_response(content)
            data = json.loads(json_str)
            
            nodes = data.get("nodes", [])
            
            # Validate count
            if len(nodes) != 15:
                # Try to complete missing nodes
                if len(nodes) < 15:
                    print(f"[STEP 1] ⚠️ {len(nodes)}/15 노드 생성됨. 부족한 부분 보완 시도...")
                    nodes = await self._complete_missing_nodes(target, topic, character_design, nodes)
                else:
                    raise ValueError(f"Too many nodes: {len(nodes)}")
            
            # Validate IDs
            expected_ids = {
                "node_1",
                "node_2_a", "node_2_b",
                "node_3_aa", "node_3_ab", "node_3_ba", "node_3_bb",
                "node_4_aaa", "node_4_aab", "node_4_aba", "node_4_abb",
                "node_4_baa", "node_4_bab", "node_4_bba", "node_4_bbb"
            }
            actual_ids = {n.get("id") for n in nodes}
            
            if actual_ids != expected_ids:
                missing = expected_ids - actual_ids
                extra = actual_ids - expected_ids
                raise ValueError(f"Node ID mismatch. Missing: {missing}, Extra: {extra}")
            
            # Quality validation
            node_objects = [NodeData(**n) for n in nodes]
            self._validate_nodes(node_objects, target)
            
            return node_objects
            
        except Exception as e:
            print(f"[STEP 1] ❌ 에러: {e}")
            raise
    
    def _validate_nodes(self, nodes: List[NodeData], target: str):
        """
        Validate node quality
        
        Validates:
        - Node count (15)
        - Required fields
        - Role separation (no protagonist dialogue in nodes)
        - Target appropriateness
        """
        print(f"[Validation] 노드 품질 검증 중...")
        
        # Check count
        if len(nodes) != 15:
            print(f"[Validation] ⚠️ 노드 개수 오류: {len(nodes)}/15")
        
        # Check required fields
        for node in nodes:
            if not node.id or not node.text:
                print(f"[Validation] ⚠️ 필수 필드 누락: {node.id}")
        
        # Check role separation (basic check for protagonist dialogue)
        # This is a simple heuristic - looks for patterns like "당신이 말합니다"
        protagonist_dialogue_patterns = [
            "당신이 말합니다", "당신이 물어봅니다", "당신이 대답합니다",
            "어머니가 말합니다", "어머니가 물어봅니다"
        ]
        
        for node in nodes:
            for pattern in protagonist_dialogue_patterns:
                if pattern in node.text:
                    print(f"[Validation] ⚠️ 주인공 대사 포함 가능성: {node.id} - '{pattern}'")
                    break
        
        print(f"[Validation] ✅ 노드 검증 완료")
    
    async def _complete_missing_nodes(
        self,
        target: str,
        topic: str,
        character_design: CharacterDesign,
        existing_nodes: List[dict]
    ) -> List[dict]:
        """Complete missing nodes (fallback)."""
        expected_ids = [
            "node_1",
            "node_2_a", "node_2_b",
            "node_3_aa", "node_3_ab", "node_3_ba", "node_3_bb",
            "node_4_aaa", "node_4_aab", "node_4_aba", "node_4_abb",
            "node_4_baa", "node_4_bab", "node_4_bba", "node_4_bbb"
        ]
        
        existing_ids = {n.get("id") for n in existing_nodes}
        missing_ids = [nid for nid in expected_ids if nid not in existing_ids]
        
        if not missing_ids:
            return existing_nodes
        
        print(f"[STEP 1] 부족한 노드 ID: {missing_ids}")
        
        # Create completion prompt
        system_prompt = "You are an expert scenario writer. Complete the missing nodes based on existing context."
        user_prompt = f"""
Target: {target}
Topic: {topic}

Existing nodes:
{json.dumps(existing_nodes, ensure_ascii=False, indent=2)}

Missing node IDs: {missing_ids}

Generate ONLY the missing nodes in JSON format:
{{"nodes": [...]}}
"""
        
        response = await asyncio.to_thread(
            openai.chat.completions.create,
            model=self.orchestrator_model,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.8,
            max_tokens=3000
        )
        
        content = response.choices[0].message.content
        json_str = extract_json_from_response(content)
        data = json.loads(json_str)
        
        new_nodes = data.get("nodes", [])
        combined = existing_nodes + new_nodes
        
        print(f"[STEP 1] ✅ 보완 완료: 총 {len(combined)}개 노드")
        
        return combined
    
    # ========================================================================
    # STEP 2: Options (30개)
    # ========================================================================
    
    def _filter_valid_options(self, options: List) -> List[dict]:
        """
        Filter and validate options from LLM response.
        
        Removes:
        - Non-dict elements (strings, etc.)
        - Options with missing or invalid 'text' field
        
        Args:
            options: Raw options list from LLM
        
        Returns:
            Cleaned list of valid option dicts
        """
        cleaned = []
        
        for idx, opt in enumerate(options):
            # 1) Check if it's a dict
            if not isinstance(opt, dict):
                print(f"[STEP 2] ⚠️ 옵션 {idx} 무시: dict 아님 (type={type(opt).__name__}) -> {str(opt)[:50]}...")
                continue
            
            # 2) Check 'text' field exists and is valid string
            text = opt.get("text")
            if not isinstance(text, str) or not text.strip():
                print(f"[STEP 2] ⚠️ 옵션 {idx} 무시: text가 비어있거나 문자열이 아님 -> {opt.get('from_node_id', 'unknown')}")
                continue
            
            # 3) Check required fields exist
            if "from_node_id" not in opt or "option_code" not in opt:
                print(f"[STEP 2] ⚠️ 옵션 {idx} 무시: 필수 필드 누락 -> {opt}")
                continue
            
            cleaned.append(opt)
        
        return cleaned
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def _generate_options(
        self,
        target: str,
        topic: str,
        nodes: List[NodeData]
    ) -> List[OptionData]:
        """
        STEP 2: Generate 30 options using GPT-4o-mini
        """
        # Prepare prompts
        nodes_json = json.dumps(
            {"nodes": [n.dict() for n in nodes]},
            ensure_ascii=False,
            indent=2
        )
        
        system_prompt, user_prompt = load_prompt_sections(
            "step2_options.md",
            {
                "target": target,
                "topic": topic,
                "nodes_json": nodes_json
            }
        )
        
        try:
            # Generate options with GPT-4o-mini
            response = await asyncio.to_thread(
                openai.chat.completions.create,
                model=self.orchestrator_model,
                response_format={"type": "json_object"},
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.8,
                max_tokens=5000
            )
            content = response.choices[0].message.content
            
            # Parse
            json_str = extract_json_from_response(content)
            data = json.loads(json_str)
            
            raw_options = data.get("options", [])
            
            # Filter invalid options
            options = self._filter_valid_options(raw_options)
            
            if len(options) == 0:
                raise ValueError("[STEP 2] 유효한 옵션이 하나도 없습니다. LLM 프롬프트를 점검하세요.")
            
            # Validate count
            if len(options) != 30:
                if len(options) < 30:
                    print(f"[STEP 2] ⚠️ {len(options)}/30 옵션 생성됨. 부족한 부분 보완 시도...")
                    options = await self._complete_missing_options(target, topic, nodes, options)
                else:
                    # Too many options - take first 30
                    print(f"[STEP 2] ⚠️ {len(options)}개 옵션 생성됨. 처음 30개만 사용합니다.")
                    options = options[:30]
            
            # Convert to Pydantic models
            option_objects = [OptionData(**opt) for opt in options]
            
            # Quality validation
            self._validate_options(option_objects, target)
            
            return option_objects
            
        except Exception as e:
            print(f"[STEP 2] ❌ 에러: {e}")
            raise
    
    def _validate_options(self, options: List[OptionData], target: str):
        """
        Validate option quality
        
        Validates:
        - Option count (30)
        - Required fields
        - Protagonist dialogue only (no target dialogue)
        """
        print(f"[Validation] 옵션 품질 검증 중...")
        
        # Check count
        if len(options) != 30:
            print(f"[Validation] ⚠️ 옵션 개수 오류: {len(options)}/30")
        
        # Check required fields
        for option in options:
            if not option.text or not option.from_node_id or not option.option_code:
                print(f"[Validation] ⚠️ 필수 필드 누락: {option.from_node_id} - {option.option_code}")
        
        # Check that options contain protagonist dialogue (should have quotes)
        for option in options:
            if '"' not in option.text and '"' not in option.text:
                print(f"[Validation] ⚠️ 대사 없음: {option.from_node_id} - {option.option_code}")
        
        print(f"[Validation] ✅ 옵션 검증 완료")
    
    async def _complete_missing_options(
        self,
        target: str,
        topic: str,
        nodes: List[NodeData],
        existing_options: List[dict]
    ) -> List[dict]:
        """Complete missing options (fallback)."""
        print(f"[STEP 2] 옵션 보완 재시도...")
        
        # Get existing from_node_id + option_code pairs to avoid duplicates
        existing_keys = {
            (opt.get("from_node_id"), opt.get("option_code"))
            for opt in existing_options
            if isinstance(opt, dict) and opt.get("from_node_id") and opt.get("option_code")
        }
        
        system_prompt = "You are an expert scenario writer. Generate ONLY the missing options."
        user_prompt = f"""
Target: {target}
Topic: {topic}

Existing options: {len(existing_options)}/30

Generate ONLY the missing options to reach exactly 30 total.
Do NOT duplicate existing options.
Output JSON: {{"options": [...]}}
"""
        
        response = await asyncio.to_thread(
            openai.chat.completions.create,
            model=self.orchestrator_model,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.8,
            max_tokens=3000
        )
        
        content = response.choices[0].message.content
        json_str = extract_json_from_response(content)
        data = json.loads(json_str)
        
        new_raw_options = data.get("options", [])
        
        # Filter invalid options
        new_options = self._filter_valid_options(new_raw_options)
        
        # Remove duplicates based on (from_node_id, option_code)
        combined = existing_options.copy()
        for new_opt in new_options:
            key = (new_opt.get("from_node_id"), new_opt.get("option_code"))
            if key not in existing_keys:
                combined.append(new_opt)
                existing_keys.add(key)
        
        # Filter again to ensure all are valid
        combined = self._filter_valid_options(combined)
        
        print(f"[STEP 2] ✅ 보완 완료: 총 {len(combined)}개 옵션 (필터링 후)")
        
        return combined
    
    # ========================================================================
    # STEP 3: Results (16개)
    # ========================================================================
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def _generate_results(
        self,
        target: str,
        topic: str,
        nodes: List[NodeData],
        options: List[OptionData]
    ) -> List[ResultData]:
        """
        STEP 3: Generate 16 results with labels using GPT-4o-mini
        """
        # Prepare prompts
        # Define required result codes explicitly
        required_codes = [
            "AAAA", "AAAB", "AABA", "AABB",
            "ABAA", "ABAB", "ABBA", "ABBB",
            "BAAA", "BAAB", "BABA", "BABB",
            "BBAA", "BBAB", "BBBA", "BBBB"
        ]
        
        system_prompt, user_prompt = load_prompt_sections(
            "step3_results.md",
            {
                "target": target,
                "topic": topic,
                "required_codes": json.dumps(required_codes, ensure_ascii=False)
            }
        )
        
        try:
            # Generate results with GPT-4o-mini
            response = await asyncio.to_thread(
                openai.chat.completions.create,
                model=self.orchestrator_model,
                response_format={"type": "json_object"},
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.8,
                max_tokens=8000
            )
            content = response.choices[0].message.content
            
            # Parse
            json_str = extract_json_from_response(content)
            data = json.loads(json_str)
            
            raw_results = data.get("results", [])
            
            # Filter and validate results
            cleaned_results = []
            for idx, r in enumerate(raw_results):
                # 1) Check if it's a dict
                if not isinstance(r, dict):
                    print(f"[STEP 3] ⚠️ 결과 {idx} 무시: dict 아님 (type={type(r).__name__})")
                    continue
                
                # 2) Check required fields
                if "result_code" not in r or "display_title" not in r or "analysis_text" not in r:
                    print(f"[STEP 3] ⚠️ 결과 {idx} 무시: 필수 필드 누락 -> {r.get('result_code', 'unknown')}")
                    continue
                
                # 3) Check label fields
                if "relation_health_level" not in r or "boundary_style" not in r or "relationship_trend" not in r:
                    print(f"[STEP 3] ⚠️ 결과 {idx} 무시: 라벨 필드 누락 -> {r.get('result_code', 'unknown')}")
                    continue
                
                # 4) atmosphere_image_type은 백엔드에서 자동 계산하므로 없어도 OK (None으로 설정)
                if "atmosphere_image_type" not in r:
                    r["atmosphere_image_type"] = None
                
                cleaned_results.append(r)
            
            if len(cleaned_results) == 0:
                raise ValueError("[STEP 3] 유효한 결과가 하나도 없습니다. LLM 프롬프트를 점검하세요.")
            
            # Validate count
            if len(cleaned_results) != 16:
                raise ValueError(f"Expected 16 results, got {len(cleaned_results)}")
            
            # Validate result codes
            expected_codes = {
                "AAAA", "AAAB", "AABA", "AABB",
                "ABAA", "ABAB", "ABBA", "ABBB",
                "BAAA", "BAAB", "BABA", "BABB",
                "BBAA", "BBAB", "BBBA", "BBBB"
            }
            actual_codes = {r.get("result_code") for r in cleaned_results}
            
            if actual_codes != expected_codes:
                missing = expected_codes - actual_codes
                extra = actual_codes - expected_codes
                raise ValueError(f"Result code mismatch. Missing: {missing}, Extra: {extra}")
            
            # Convert to Pydantic models
            result_objects = [ResultData(**r) for r in cleaned_results]
            
            # Quality validation
            self._validate_results(result_objects, target)
            
            return result_objects
            
        except Exception as e:
            print(f"[STEP 3] ❌ 에러: {e}")
            raise
    
    def _validate_results(self, results: List[ResultData], target: str):
        """
        Validate result quality
        
        Validates:
        - Result count (16)
        - Required fields
        - Target relationship expression in analysis
        """
        print(f"[Validation] 결과 품질 검증 중...")
        
        # Check count
        if len(results) != 16:
            print(f"[Validation] ⚠️ 결과 개수 오류: {len(results)}/16")
        
        # Check required fields
        for result in results:
            if not result.result_code or not result.display_title or not result.analysis_text:
                print(f"[Validation] ⚠️ 필수 필드 누락: {result.result_code}")
        
        # Check target-specific relationship expressions
        target_keywords = {
            "HUSBAND": ["남편", "부부"],
            "CHILD": ["자녀", "아들", "딸"],
            "FRIEND": ["친구"],
            "COLLEAGUE": ["동료", "직장"],
            "ETC": []  # No specific keywords
        }
        
        keywords = target_keywords.get(target, [])
        if keywords:
            for result in results:
                has_keyword = any(kw in result.analysis_text for kw in keywords)
                if not has_keyword:
                    print(f"[Validation] ⚠️ 타겟 관계 표현 부족: {result.result_code}")
        
        print(f"[Validation] ✅ 결과 검증 완료")
    
    # ========================================================================
    # STEP 4: Combine & Validate
    # ========================================================================
    
    def _combine_scenario(
        self,
        target: str,
        topic: str,
        character_design: CharacterDesign,
        nodes: List[NodeData],
        options: List[OptionData],
        results: List[ResultData]
    ) -> ScenarioJSON:
        """Combine all parts into final ScenarioJSON."""
        # Generate topic summary for image paths
        topic_summary = self._make_topic_summary(topic)
        
        scenario_meta = ScenarioMeta(
            title=self._make_title_from_topic(topic),
            target_type=target,
            category="TRAINING",
            start_image_url=f"/api/service/relation-training/images/{topic_summary}/start.png"
        )
        
        # Fill image URLs for results
        for result in results:
            if not result.image_url:
                result.image_url = f"/api/service/relation-training/images/{topic_summary}/result_{result.result_code}.png"
        
        return ScenarioJSON(
            scenario=scenario_meta,
            character_design=character_design,
            nodes=nodes,
            options=options,
            results=results
        )
    
    def _fill_atmosphere_from_labels(self, scenario_json: ScenarioJSON) -> None:
        """Auto-calculate atmosphere_image_type from labels."""
        print("[STEP 4] Atmosphere 자동 계산 중...")
        
        for result in scenario_json.results:
            correct_atmosphere = calculate_atmosphere_from_labels(
                result.relation_health_level,
                result.relationship_trend
            )
            result.atmosphere_image_type = correct_atmosphere
        
        print("[STEP 4] ✅ Atmosphere 계산 완료")
    
    def _make_topic_summary(self, topic: str) -> str:
        """Generate English topic summary for image paths."""
        # Simple version - you can enhance this
        topic_lower = topic.lower()
        
        if "스마트폰" in topic or "폰" in topic:
            return "smartphone"
        elif "밥" in topic or "식사" in topic:
            return "meal"
        elif "돈" in topic or "용돈" in topic:
            return "money"
        elif "공부" in topic or "숙제" in topic:
            return "study"
        else:
            # Default: use timestamp
            return f"scenario_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    def _make_title_from_topic(self, topic: str) -> str:
        """
        Generate scenario title from topic.
        
        Args:
            topic: Analyzed topic string
            
        Returns:
            Title string (15-25 characters)
        """
        # Clean up topic
        topic = topic.strip()
        
        # If topic is empty or invalid, return default
        if not topic or topic in ["\\", "\"", "...", ""]:
            return "관계 훈련 시나리오"
        
        # If topic is already good length (15-25 chars), use as-is
        if 15 <= len(topic) <= 25:
            return topic
        
        # If too long, truncate intelligently
        if len(topic) > 25:
            # Try to cut at natural break point
            if "," in topic[:25]:
                return topic[:topic[:25].rfind(",")] + "..."
            elif " " in topic[:25]:
                return topic[:topic[:25].rfind(" ")] + "..."
            else:
                return topic[:22] + "..."
        
        # If too short, return as-is (better than adding filler)
        return topic
    
    # ========================================================================
    # Phase 2: The Hands (Image Generation)
    # ========================================================================
    
    async def generate_images(
        self,
        scenario_json: ScenarioJSON,
        folder_name: str,
        user_id: int
    ) -> Dict[str, str]:
        """
        Generate images for scenario.
        
        Args:
            scenario_json: Complete scenario JSON
            folder_name: Folder name for images (e.g., "husband_20231215_143022")
            user_id: User ID
        
        Returns:
            Dictionary mapping image types to URLs
        """
        print(f"\n[Hands] 이미지 생성 시작 (총 17장)")
        
        # Check if image generation is skipped
        use_skip_images = os.getenv("USE_SKIP_IMAGES", "false").lower() == "true"
        
        if use_skip_images:
            print("[Hands] ⚠️ 이미지 생성 스킵 모드 (USE_SKIP_IMAGES=true)")
            return {}
        
        image_urls = {}
        
        # Generate start image
        print("[Hands] [1/17] Start 이미지 생성 중...")
        start_url = await generate_start_image(scenario_json, folder_name, user_id)
        if start_url:
            image_urls["start"] = start_url
        
        # Generate result images
        print("[Hands] [2-17/17] Result 이미지 생성 중...")
        result_urls = await generate_result_images(scenario_json, folder_name, user_id)
        image_urls.update(result_urls)
        
        print(f"[Hands] ✅ 이미지 생성 완료: {len(image_urls)}장")
        
        return image_urls
    
    # ========================================================================
    # Phase 3: Persistence (JSON + DB)
    # ========================================================================
    
    async def save_scenario(
        self,
        scenario_json: ScenarioJSON,
        user_id: int,
        folder_name: str
    ) -> int:
        """
        Save scenario to JSON file and database.
        
        Args:
            scenario_json: Complete scenario JSON
            user_id: User ID
            folder_name: Folder name for JSON file
        
        Returns:
            Scenario ID from database
        """
        print(f"\n[Persistence] 시나리오 저장 시작")
        
        # 1. Save JSON file
        json_path = await self._save_json_file(scenario_json, user_id, folder_name)
        print(f"[Persistence] ✅ JSON 파일 저장: {json_path}")
        
        # 2. Save to database
        scenario_id = await self._save_to_database(scenario_json, user_id)
        print(f"[Persistence] ✅ DB 저장 완료: Scenario ID = {scenario_id}")
        
        return scenario_id
    
    async def _save_json_file(
        self,
        scenario_json: ScenarioJSON,
        user_id: int,
        folder_name: str
    ) -> Path:
        """Save scenario to JSON file."""
        data_dir = Path(__file__).parent / "data" / str(user_id)
        data_dir.mkdir(parents=True, exist_ok=True)
        
        json_path = data_dir / f"{folder_name}.json"
        
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(
                scenario_json.dict(),
                f,
                ensure_ascii=False,
                indent=2
            )
        
        return json_path
    
    async def _save_to_database(
        self,
        scenario_json: ScenarioJSON,
        user_id: int
    ) -> int:
        """Save scenario to database."""
        # 1. Create Scenario
        scenario = Scenario(
            USER_ID=user_id,
            TITLE=scenario_json.scenario.title,
            TARGET_TYPE=scenario_json.scenario.target_type,
            CATEGORY=scenario_json.scenario.category,
            START_IMAGE_URL=scenario_json.scenario.start_image_url
        )
        self.db.add(scenario)
        self.db.flush()
        
        scenario_id = scenario.ID
        
        # 2. Create node ID mapping
        node_id_map = {}
        for node_data in scenario_json.nodes:
            node = ScenarioNode(
                SCENARIO_ID=scenario_id,
                STEP_LEVEL=node_data.step_level,
                SITUATION_TEXT=node_data.text,
                IMAGE_URL=node_data.image_url or None
            )
            self.db.add(node)
            self.db.flush()
            node_id_map[node_data.id] = node.ID
        
        # 3. Create Results first (to get result IDs)
        result_id_map = {}
        for result_data in scenario_json.results:
            result = ScenarioResult(
                SCENARIO_ID=scenario_id,
                RESULT_CODE=result_data.result_code,
                DISPLAY_TITLE=result_data.display_title,
                ANALYSIS_TEXT=result_data.analysis_text,
                ATMOSPHERE_IMAGE_TYPE=result_data.atmosphere_image_type,
                SCORE=None,  # Legacy field, not used
                RELATION_HEALTH_LEVEL=result_data.relation_health_level,
                BOUNDARY_STYLE=result_data.boundary_style,
                RELATIONSHIP_TREND=result_data.relationship_trend,
                IMAGE_URL=result_data.image_url
            )
            self.db.add(result)
            self.db.flush()
            result_id_map[result_data.result_code] = result.ID
        
        # 4. Create Options (after results, so we have result IDs)
        for option_data in scenario_json.options:
            next_node_id = node_id_map.get(option_data.to_node_id) if option_data.to_node_id else None
            result_id = result_id_map.get(option_data.result_code) if option_data.result_code else None
            
            option = ScenarioOption(
                NODE_ID=node_id_map[option_data.from_node_id],
                OPTION_CODE=option_data.option_code,
                OPTION_TEXT=option_data.text,
                NEXT_NODE_ID=next_node_id,
                RESULT_ID=result_id
            )
            self.db.add(option)
        
        self.db.commit()
        
        return scenario_id
