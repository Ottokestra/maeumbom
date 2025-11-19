"""
Emotion analysis model using OpenAI GPT-4o mini
논문 기반 VA(Valence/Arousal) + 감정 군집 기준 버전
"""
import sys
from pathlib import Path
from openai import OpenAI
from typing import Dict, List, Any, Optional, Tuple
import re
import json

# 경로 설정 및 import
src_path = Path(__file__).parent
if str(src_path) not in sys.path:
    sys.path.insert(0, str(src_path))

import importlib.util

# config import
config_path = src_path / "config.py"
spec = importlib.util.spec_from_file_location("config", config_path)
config_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config_module)
LLM_MODEL = config_module.LLM_MODEL
OPENAI_API_KEY = config_module.OPENAI_API_KEY
VALENCE_THRESHOLD = config_module.VALENCE_THRESHOLD

# 17개 감정 군집 관련 import
EMOTION_CLUSTERS_17 = config_module.EMOTION_CLUSTERS_17
EMOTION_CODES_17 = config_module.EMOTION_CODES_17
EMOTION_CODE_TO_NAME_KO = config_module.EMOTION_CODE_TO_NAME_KO
EMOTION_CODE_TO_GROUP = config_module.EMOTION_CODE_TO_GROUP
INTENSITY_MAPPING = config_module.INTENSITY_MAPPING
SENTIMENT_DELTA_THRESHOLD = config_module.SENTIMENT_DELTA_THRESHOLD

# OpenAI System Prompt (LLM은 raw_distribution만 생성)
SYSTEM_PROMPT_17 = """당신은 갱년기 여성 대상 감정 공감 AI 서비스의 "감정 분포 분석 엔진"입니다.

### 역할

- 사용자가 작성한 한국어 문장을 읽고,
- 논문에서 정의한 17개 감정 군집을 기준으로,
- 각 감정의 상대적인 강도를 나타내는 raw_distribution만 JSON으로 반환합니다.

### 감정 군집 정의 (17개, 논문 기준 고정)

- 긍정 그룹 (group="positive")

  1. joy          / "기쁨"

  2. excitement   / "흥분"

  3. confidence   / "자신감"

  4. love         / "사랑"

  5. relief       / "안심"

  6. enlightenment/ "깨달음"

  7. interest     / "흥미"

- 부정 그룹 (group="negative")

  8.  discontent  / "불만"

  9.  shame       / "수치"

  10. sadness     / "슬픔"

  11. guilt       / "죄책감"

  12. depression  / "우울"

  13. boredom     / "무료"

  14. contempt    / "경멸"

  15. anger       / "화"

  16. fear        / "공포"

  17. confusion   / "혼란"

이 17개 감정 이외의 이름은 사용하지 마십시오.  
사용자가 다른 표현을 쓰더라도 반드시 위 17개 중 가장 가까운 감정으로 매핑해야 합니다.

### 출력 규칙: raw_distribution만 생성

- 다음 형식의 JSON **한 개만** 반환합니다:

{
  "raw_distribution": [
    {
      "code": "joy",
      "name_ko": "기쁨",
      "group": "positive",
      "score": 0.05
    },
    ...
  ]
}

- `raw_distribution`에는 반드시 **17개 감정이 모두 포함**되어야 합니다.
- 각 항목 필드:
  - code: 위에서 정의한 영어 코드 (예: "joy", "sadness")
  - name_ko: 해당 감정의 한국어 이름 (예: "기쁨", "슬픔")
  - group: "positive" 또는 "negative"
  - score: 0 이상인 실수값 (상대적인 강도)

### score 합계에 대한 규칙

- score 값들은 "상대적인 강도"를 나타내며,
- 17개 score의 합은 **대략 1.0에 가깝게** 되도록 분포를 설계하십시오.
  - 예: 0.7, 0.8, 1.1 같은 범위까지는 허용 가능
- 단, 서버에서 최종적으로 score를 다시 정규화(normalize)할 것이므로,
  - 절대 정확한 1.0을 만들려고 너무 집착할 필요는 없습니다.
  - 중요한 것은 **감정들 사이의 상대적인 크기 관계**입니다.

### 응답 형식에 대한 엄격한 요구사항

- 반드시 위에서 정의한 JSON 구조만 반환하십시오.
- JSON 외의 자연어 설명, 마크다운, 주석, 텍스트를 추가하지 마십시오.
- "raw_distribution" 외에 다른 필드(text, language, primary_emotion 등)는 **절대 포함하지 마십시오.**

당신의 전체 응답은 **다음과 같은 한 개의 JSON 객체**여야 합니다:

{
  "raw_distribution": [
    { "code": "...", "name_ko": "...", "group": "...", "score": 0.00 },
    ...
  ]
}
"""


class EmotionAnalyzer:
    """Analyze emotions using OpenAI GPT-4o mini (논문 VA + 군집 기준)"""
    
    def __init__(self, model_name: str = LLM_MODEL):
        """
        Initialize emotion analyzer with OpenAI API
        
        Args:
            model_name: Name of the OpenAI model (default: gpt-4o-mini)
        """
        self.model_name = model_name
        
        # Valence threshold
        self.valence_threshold = VALENCE_THRESHOLD
        
        # 17개 감정 군집
        self.emotion_clusters_17 = EMOTION_CLUSTERS_17
        self.emotion_codes_17 = EMOTION_CODES_17
        self.emotion_code_to_name_ko = EMOTION_CODE_TO_NAME_KO
        self.emotion_code_to_group = EMOTION_CODE_TO_GROUP
        self.intensity_mapping = INTENSITY_MAPPING
        self.sentiment_delta_threshold = SENTIMENT_DELTA_THRESHOLD
        
        # OpenAI client (Lazy init)
        self._client = None

        print(f"EmotionAnalyzer initialized (논문 VA + 군집 기준, 17개 감정 군집 지원)")

    def _get_client(self) -> OpenAI:
        """Get or create OpenAI client"""
        if self._client is None:
            print(f"Initializing OpenAI client with model: {self.model_name}")
            self._client = OpenAI(api_key=OPENAI_API_KEY)
        return self._client
    
    def _calculate_polarity(self, valence: float) -> str:
        """
        Calculate polarity from valence value
        
        Args:
            valence: Valence value (-1.0 ~ +1.0)
            
        Returns:
            "positive", "neutral", or "negative"
        """
        if valence > self.valence_threshold:
            return "positive"
        elif valence < -self.valence_threshold:
            return "negative"
        else:
            return "neutral"
    
    def _create_prompt(self, text: str, context_texts: Optional[List[dict]] = None) -> str:
        """
        Create prompt for LLM (논문 기준)
        
        Args:
            text: Input text to analyze
            context_texts: Optional list of similar context texts
            
        Returns:
            Formatted prompt string
        """
        # 군집 설명을 프롬프트에 포함
        cluster_desc_lines = []
        if self.clusters:
            cluster_desc_lines.append("감정 군집 목록:")
            for c in self.clusters:
                cluster_desc_lines.append(f"- {c['id']}: {c['label']} (Valence: {c['valence']:.1f}, Arousal: {c['arousal']:.1f})")
        
        prompt = f"""당신은 갱년기 여성의 감정을 분석하는 전문가입니다.
우리는 한국어 감정 구조 논문에서 제안한 이론을 사용합니다.

감정은 다음과 같이 표현합니다:
1) 정서가(Valence, V): -1.0(매우 불쾌) ~ +1.0(매우 쾌)
2) 각성가(Arousal, A): -1.0(매우 안정/저각성) ~ +1.0(매우 각성/흥분)
3) 감정 군집(Emotion Cluster): 논문에서 제안한 감정 군집 ID와 이름

polarity(극성)는 다음 규칙으로 정합니다:
- valence > {self.valence_threshold}  → "positive"
- -{self.valence_threshold} <= valence <= {self.valence_threshold} → "neutral"
- valence < -{self.valence_threshold} → "negative"

분석할 텍스트:
\"\"\"{text}\"\"\""""

        if context_texts:
            prompt += "\n\n참고용 유사 감정 표현:\n"
            for i, ctx in enumerate(context_texts[:3], 1):
                if isinstance(ctx, dict):
                    prompt += f"{i}. \"{ctx.get('text', '')}\"\n"
        
        if cluster_desc_lines:
            prompt += "\n\n" + "\n".join(cluster_desc_lines)
        
        prompt += """

출력 형식:
아래 JSON 형식으로만 출력하세요. 설명 문장, 자연어 코멘트는 절대 쓰지 마세요.

{
  "valence": float,           // -1.0 ~ +1.0
  "arousal": float,           // -1.0 ~ +1.0
  "polarity": "positive" | "neutral" | "negative",
  "cluster_id": int,          // 논문 기반 감정 군집 ID (1~10)
  "cluster_label": string,    // 해당 군집의 한국어 이름
  "related_clusters": [
    {{
      "cluster_id": int,
      "cluster_label": string,
      "similarity": float      // 0~1, 선택사항
    }}
  ]
}

예시:
입력: "요즘 너무 피곤하고 아무것도 하기 싫어요"
출력:
{{
  "valence": -0.7,
  "arousal": -0.5,
  "polarity": "negative",
  "cluster_id": 9,
  "cluster_label": "피로/무기력",
  "related_clusters": [
    {{ "cluster_id": 9, "cluster_label": "피로/무기력", "similarity": 0.95 }},
    {{ "cluster_id": 6, "cluster_label": "슬픔/비애", "similarity": 0.78 }}
  ]
}}

입력: "정말 기분이 좋아요"
출력:
{{
  "valence": 0.8,
  "arousal": 0.4,
  "polarity": "positive",
  "cluster_id": 2,
  "cluster_label": "흥미/관심",
  "related_clusters": [
    {{ "cluster_id": 2, "cluster_label": "흥미/관심", "similarity": 0.92 }},
    {{ "cluster_id": 1, "cluster_label": "안심/평온", "similarity": 0.65 }}
  ]
}}

이제 위 형식을 그대로 따라 JSON만 출력하세요.
"""
        
        return prompt
    
    def _parse_llm_response(self, response: str) -> Dict[str, Any]:
        """
        Parse LLM response to extract valence/arousal/cluster info
        
        Args:
            response: LLM generated text (JSON expected)
            
        Returns:
            Dict with keys: valence, arousal, polarity, cluster_id, cluster_label, related_clusters
        """
        # JSON 그대로 파싱 시도
        try:
            data = json.loads(response)
        except json.JSONDecodeError:
            # 응답에 앞뒤로 잡소리가 껴 있을 수 있으니 JSON 부분만 추출 시도
            json_pattern = r'\{[\s\S]*\}'
            match = re.search(json_pattern, response)
            if not match:
                raise ValueError(f"LLM response is not valid JSON: {response}")
            data = json.loads(match.group(0))
        
        # 필수 필드 기본값
        valence = float(data.get("valence", 0.0))
        arousal = float(data.get("arousal", 0.0))
        polarity = data.get("polarity")
        cluster_id = data.get("cluster_id")
        cluster_label = data.get("cluster_label")
        related_clusters = data.get("related_clusters", [])
        
        # 범위 검증
        valence = max(-1.0, min(1.0, valence))
        arousal = max(-1.0, min(1.0, arousal))
        
        # polarity 없으면 규칙대로 계산
        if not polarity:
            polarity = self._calculate_polarity(valence)
        
        # cluster_id가 없거나 유효하지 않으면 VA 값으로 가장 가까운 군집 찾기
        if not cluster_id or cluster_id not in [c['id'] for c in self.clusters]:
            cluster_id, cluster_label = self._find_nearest_cluster(valence, arousal)
        
        # cluster_label이 없으면 cluster_id로 찾기
        if not cluster_label:
            for c in self.clusters:
                if c['id'] == cluster_id:
                    cluster_label = c['label']
                    break
        
        # related_clusters가 리스트가 아니면 초기화
        if not isinstance(related_clusters, list):
            related_clusters = []
        
        return {
            "valence": valence,
            "arousal": arousal,
            "polarity": polarity,
            "cluster_id": cluster_id,
            "cluster_label": cluster_label,
            "related_clusters": related_clusters
        }
    
    def _find_nearest_cluster(self, valence: float, arousal: float) -> Tuple[int, str]:
        """
        Find the nearest emotion cluster based on VA values
        
        Args:
            valence: Valence value
            arousal: Arousal value
            
        Returns:
            Tuple of (cluster_id, cluster_label)
        """
        min_distance = float('inf')
        nearest_cluster_id = 1
        nearest_cluster_label = "안심/평온"
        
        for cluster in self.clusters:
            # 유클리드 거리 계산
            distance = ((valence - cluster['valence'])**2 + (arousal - cluster['arousal'])**2)**0.5
            if distance < min_distance:
                min_distance = distance
                nearest_cluster_id = cluster['id']
                nearest_cluster_label = cluster['label']
        
        return nearest_cluster_id, nearest_cluster_label
    
    def _create_user_prompt_17(self, text: str, context_texts: Optional[List[dict]] = None) -> str:
        """
        Create user prompt for LLM (raw_distribution만 요청)
        
        Args:
            text: Input text to analyze
            context_texts: Optional list of similar context texts
            
        Returns:
            User prompt string
        """
        prompt = f"""분석할 텍스트:
\"\"\"{text}\"\"\""""

        if context_texts:
            prompt += "\n\n참고용 유사 감정 표현:\n"
            for i, ctx in enumerate(context_texts[:3], 1):
                if isinstance(ctx, dict):
                    prompt += f"{i}. \"{ctx.get('text', '')}\"\n"
        
        prompt += "\n\n위 텍스트를 분석하여 17개 감정 군집에 대한 raw_distribution만 JSON으로 반환하세요."
        
        return prompt
    
    def _parse_raw_distribution(self, response: str) -> List[Dict[str, Any]]:
        """
        Parse LLM response to extract raw_distribution
        
        Args:
            response: LLM generated text (JSON expected)
            
        Returns:
            List of emotion distribution dicts (정규화 전)
        """
        # JSON 파싱
        try:
            data = json.loads(response)
        except json.JSONDecodeError:
            json_pattern = r'\{[\s\S]*\}'
            match = re.search(json_pattern, response)
            if not match:
                raise ValueError(f"LLM response is not valid JSON: {response}")
            data = json.loads(match.group(0))
        
        raw_distribution = data.get("raw_distribution", [])
        
        # 1. 각 객체 검증 및 필드 보완
        validated_distribution = []
        seen_codes = set()
        
        for item in raw_distribution:
            # dict가 아니거나 code가 없으면 스킵
            if not isinstance(item, dict) or not item.get("code"):
                continue
            
            code = item.get("code")
            
            # 중복 코드 처리 (첫 번째 것만 유지)
            if code in seen_codes:
                continue
            
            # 유효한 감정 코드인지 확인
            if code not in self.emotion_codes_17:
                continue
            
            seen_codes.add(code)
            
            # 필드 보완: 누락된 필드를 config에서 가져오기
            validated_item = {
                "code": code,
                "name_ko": item.get("name_ko") or self.emotion_code_to_name_ko.get(code, ""),
                "group": item.get("group") or self.emotion_code_to_group.get(code, ""),
                "score": float(item.get("score", 0.001)) if item.get("score") is not None else 0.001
            }
            
            # 필드가 모두 완전한지 확인
            if validated_item["name_ko"] and validated_item["group"]:
                validated_distribution.append(validated_item)
        
        # 2. 누락된 감정 추가
        for emotion in self.emotion_clusters_17:
            if emotion["code"] not in seen_codes:
                validated_distribution.append({
                    "code": emotion["code"],
                    "name_ko": emotion["name_ko"],
                    "group": emotion["group"],
                    "score": 0.001  # 매우 작은 값
                })
        
        return validated_distribution
    
    def _normalize_scores(self, raw_distribution: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Normalize scores so that sum equals 1.0
        
        Args:
            raw_distribution: List of emotion distributions with raw scores
            
        Returns:
            List of emotion distributions with normalized scores
        """
        # score 합계 계산
        total = sum(item.get("score", 0) for item in raw_distribution)
        
        # 정규화
        if total > 0:
            for item in raw_distribution:
                item["score"] = item.get("score", 0) / total
        else:
            # 모든 score가 0이면 균등 분배
            for item in raw_distribution:
                item["score"] = 1.0 / len(raw_distribution)
        
        return raw_distribution
    
    def _score_to_intensity(self, score: float) -> int:
        """
        Convert score to intensity (1~5)
        
        Args:
            score: Emotion score (0~1)
            
        Returns:
            Intensity (1~5)
        """
        if score < 0.10:
            return 1
        elif score < 0.25:
            return 2
        elif score < 0.45:
            return 3
        elif score < 0.70:
            return 4
        else:
            return 5
    
    def _calculate_confidence(self, primary_score: float, secondary_score: float) -> float:
        """
        Calculate confidence based on score difference, absolute value, and ratio
        
        Args:
            primary_score: Primary emotion score (0~1)
            secondary_score: Secondary emotion score (0~1)
            
        Returns:
            Confidence (0~1)
        """
        if secondary_score == 0:
            return 0.95
        
        # 1. primary_score의 절대값 반영 (높을수록 신뢰도 증가)
        primary_bonus = primary_score * 0.3  # primary_score가 높을수록 보너스
        
        # 2. 점수 차이 반영
        diff = primary_score - secondary_score
        diff_factor = diff * 0.4  # 차이가 클수록 신뢰도 증가
        
        # 3. 비율 차이 반영 (primary가 secondary보다 얼마나 큰지)
        if secondary_score > 0:
            ratio = primary_score / secondary_score
            ratio_factor = min(0.3, (ratio - 1) * 0.1)  # 비율이 클수록 신뢰도 증가, 최대 0.3
        else:
            ratio_factor = 0.3
        
        # 4. 기본 신뢰도 계산
        base_confidence = 0.6 + primary_bonus + diff_factor + ratio_factor
        
        # 5. primary_score가 높으면 최소값도 높임
        min_confidence = 0.55 + (primary_score * 0.2)  # primary_score가 높을수록 최소값 증가
        
        # 최종 신뢰도 (최소값 ~ 0.95)
        confidence = min(0.95, max(min_confidence, base_confidence))
        
        return round(confidence, 2)
    
    def _calculate_sentiment_overall(self, normalized_distribution: List[Dict[str, Any]]) -> str:
        """
        Calculate sentiment_overall from normalized distribution
        
        Args:
            normalized_distribution: List of emotion distributions (정규화된 score)
            
        Returns:
            "positive", "neutral", or "negative"
        """
        pos_sum = sum(item["score"] for item in normalized_distribution if item.get("group") == "positive")
        neg_sum = sum(item["score"] for item in normalized_distribution if item.get("group") == "negative")
        
        delta = pos_sum - neg_sum
        
        if delta > self.sentiment_delta_threshold:
            return "positive"
        elif delta < -self.sentiment_delta_threshold:
            return "negative"
        else:
            return "neutral"
    
    def _generate_service_signals(self, normalized_distribution: List[Dict[str, Any]], 
                                  primary_emotion: Dict[str, Any],
                                  sentiment_overall: str) -> Dict[str, Any]:
        """
        Generate service_signals based on emotion analysis
        
        Args:
            normalized_distribution: List of emotion distributions (정규화된 score)
            primary_emotion: Primary emotion dict
            sentiment_overall: Overall sentiment
            
        Returns:
            Service signals dict
        """
        # 부정 감정 점수 합계
        negative_scores = {
            "depression": 0,
            "sadness": 0,
            "guilt": 0,
            "fear": 0,
            "anger": 0
        }
        
        for item in normalized_distribution:
            code = item.get("code")
            if code in negative_scores:
                negative_scores[code] = item.get("score", 0)
        
        total_negative = sum(negative_scores.values())
        depression_score = negative_scores.get("depression", 0)
        sadness_score = negative_scores.get("sadness", 0)
        guilt_score = negative_scores.get("guilt", 0)
        fear_score = negative_scores.get("fear", 0)
        anger_score = negative_scores.get("anger", 0)
        
        # need_empathy: 부정 감정이 있으면 true
        need_empathy = sentiment_overall in ["negative", "neutral"] or total_negative > 0.3
        
        # need_routine_recommend: 부정 감정이 있거나 중립이면 true
        need_routine_recommend = sentiment_overall != "positive" or total_negative > 0.2
        
        # need_health_check: 우울, 슬픔, 죄책감이 높으면 true
        need_health_check = depression_score > 0.3 or sadness_score > 0.4 or guilt_score > 0.3
        
        # need_voice_analysis: 공포나 화가 높으면 true
        need_voice_analysis = fear_score > 0.3 or anger_score > 0.4
        
        # risk_level 계산
        if depression_score > 0.5 or (depression_score > 0.3 and sadness_score > 0.3):
            risk_level = "critical"
        elif total_negative > 0.6 or depression_score > 0.3:
            risk_level = "alert"
        elif total_negative > 0.4 or sentiment_overall == "negative":
            risk_level = "watch"
        else:
            risk_level = "normal"
        
        return {
            "need_empathy": need_empathy,
            "need_routine_recommend": need_routine_recommend,
            "need_health_check": need_health_check,
            "need_voice_analysis": need_voice_analysis,
            "risk_level": risk_level
        }
    
    def _generate_recommendations(self, normalized_distribution: List[Dict[str, Any]],
                                  primary_emotion: Dict[str, Any],
                                  sentiment_overall: str) -> Dict[str, List[str]]:
        """
        Generate recommended_response_style, recommended_routine_tags, report_tags
        
        Args:
            normalized_distribution: List of emotion distributions (정규화된 score)
            primary_emotion: Primary emotion dict
            sentiment_overall: Overall sentiment
            
        Returns:
            Dict with recommended_response_style, recommended_routine_tags, report_tags
        """
        primary_code = primary_emotion.get("code")
        primary_group = primary_emotion.get("group")
        
        # recommended_response_style
        response_styles = []
        if sentiment_overall == "negative":
            response_styles.append("부드럽고 공감 중심의 답변")
            response_styles.append("비난 없이 감정을 받아주는 방식")
            response_styles.append("천천히 말 걸기")
        elif primary_group == "negative":
            if primary_code in ["depression", "sadness"]:
                response_styles.append("따뜻하고 지지적인 톤")
                response_styles.append("감정을 인정하고 공감하기")
            elif primary_code in ["anger", "fear"]:
                response_styles.append("차분하고 안정적인 톤")
                response_styles.append("감정을 받아들이고 이해하기")
            else:
                response_styles.append("공감적이고 지지적인 답변")
        else:
            response_styles.append("긍정적이고 격려하는 답변")
            response_styles.append("감정을 함께 나누기")
        
        # recommended_routine_tags
        routine_tags = []
        if sentiment_overall == "negative" or primary_group == "negative":
            if primary_code in ["depression", "sadness", "boredom"]:
                routine_tags.extend(["light_walk", "breathing", "journaling"])
            elif primary_code in ["anger", "fear", "confusion"]:
                routine_tags.extend(["breathing", "meditation", "light_exercise"])
            elif primary_code in ["guilt", "shame"]:
                routine_tags.extend(["journaling", "self_compassion", "breathing"])
            else:
                routine_tags.extend(["light_walk", "breathing"])
        else:
            routine_tags.extend(["maintain_positive", "gratitude", "social_activity"])
        
        # report_tags
        report_tags = []
        for item in sorted(normalized_distribution, key=lambda x: x.get("score", 0), reverse=True)[:3]:
            if item.get("score", 0) > 0.1:
                code = item.get("code")
                name_ko = item.get("name_ko")
                if item.get("group") == "negative":
                    report_tags.append(f"{name_ko} 증가")
                else:
                    report_tags.append(f"{name_ko} 경향")
        
        if sentiment_overall == "negative":
            report_tags.append("정서적 피로")
        
        return {
            "recommended_response_style": response_styles[:3],
            "recommended_routine_tags": routine_tags[:3],
            "report_tags": report_tags[:5]
        }
    
    def analyze_emotion(self, text: str, context_texts: Optional[List[dict]] = None) -> Dict[str, Any]:
        """
        Analyze emotions using 17 emotion clusters system
        
        LLM은 raw_distribution만 생성하고, 나머지는 백엔드에서 계산합니다.
        
        Args:
            text: Input text to analyze
            context_texts: Optional list of similar context texts
            
        Returns:
            Dict with 17 emotion cluster analysis results
        """
        # Step 1: LLM 호출하여 raw_distribution만 받아오기
        user_prompt = self._create_user_prompt_17(text, context_texts)
        
        try:
            client = self._get_client()
            response = client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {
                        "role": "system",
                        "content": SYSTEM_PROMPT_17
                    },
                    {
                        "role": "user",
                        "content": user_prompt
                    }
                ],
                temperature=0.1,
                max_tokens=800,
                response_format={"type": "json_object"}
            )
            generated_text = response.choices[0].message.content.strip()
            # print("\n=== OpenAI API Response (raw_distribution only) ===")
            # print(generated_text)
            # print("=" * 50)
        except Exception as e:
            if "response_format" in str(e).lower():
                print("JSON mode not supported, retrying without response_format...")
                response = self.client.chat.completions.create(
                    model=self.model_name,
                    messages=[
                        {
                            "role": "system",
                            "content": SYSTEM_PROMPT_17
                        },
                        {
                            "role": "user",
                            "content": user_prompt
                        }
                    ],
                    temperature=0.1,
                    max_tokens=800
                )
                generated_text = response.choices[0].message.content.strip()
                # print("\n=== OpenAI API Response ===")
                # print(generated_text)
                # print("=" * 50)
            else:
                raise e
        
        # Step 2: raw_distribution 파싱
        raw_distribution = self._parse_raw_distribution(generated_text)
        
        # Step 3: score 정규화 (합이 정확히 1.0이 되도록) - 계산용
        normalized_distribution = self._normalize_scores(raw_distribution.copy())
        
        # Step 4: primary_emotion 계산 (정규화된 값 사용)
        sorted_dist = sorted(normalized_distribution, key=lambda x: x.get("score", 0), reverse=True)
        primary_item = sorted_dist[0]
        secondary_item = sorted_dist[1] if len(sorted_dist) > 1 else {"score": 0}
        
        primary_score = primary_item.get("score", 0)
        secondary_score = secondary_item.get("score", 0)
        
        primary_emotion = {
            "code": primary_item.get("code"),
            "name_ko": primary_item.get("name_ko"),
            "group": primary_item.get("group"),
            "intensity": self._score_to_intensity(primary_score),
            "confidence": self._calculate_confidence(primary_score, secondary_score)
        }
        
        # Step 5: secondary_emotions 계산 (상위 1~3개, primary 제외)
        secondary_emotions = []
        for item in sorted_dist[1:4]:  # 최대 3개
            if item.get("score", 0) > 0.05:  # 최소 5% 이상
                secondary_emotions.append({
                    "code": item.get("code"),
                    "name_ko": item.get("name_ko"),
                    "intensity": self._score_to_intensity(item.get("score", 0))
                })
        
        # Step 6: sentiment_overall 계산
        sentiment_overall = self._calculate_sentiment_overall(normalized_distribution)
        
        # Step 7: service_signals 생성
        service_signals = self._generate_service_signals(normalized_distribution, primary_emotion, sentiment_overall)
        
        # Step 8: 추천 태그 생성
        recommendations = self._generate_recommendations(normalized_distribution, primary_emotion, sentiment_overall)
        
        # Step 9: raw_distribution에서 score가 0인 항목 필터링
        filtered_raw_distribution = [
            item for item in raw_distribution 
            if item.get("score", 0) > 0
        ]
        
        # Step 10: 최종 결과 구성
        result = {
            "text": text,
            "language": "ko",
            "raw_distribution": filtered_raw_distribution,  # score가 0보다 큰 항목만 포함
            "primary_emotion": primary_emotion,
            "secondary_emotions": secondary_emotions,
            "sentiment_overall": sentiment_overall,
            "service_signals": service_signals,
            "recommended_response_style": recommendations["recommended_response_style"],
            "recommended_routine_tags": recommendations["recommended_routine_tags"],
            "report_tags": recommendations["report_tags"]
        }
        
        # 최종 응답 출력 (디버깅용)
        print("\n=== 3-4 Emotion Analyzer - API Response ===")
        import json
        print(json.dumps(result, indent=2, ensure_ascii=False))
        # print("=" * 50)
        
        return result
    
    def analyze_17(self, text: str, context_texts: Optional[List[dict]] = None) -> Dict[str, Any]:
        """
        Alias for analyze_emotion (하위 호환성)
        """
        return self.analyze_emotion(text, context_texts)
    
    def analyze(self, text: str, context_texts: Optional[List[dict]] = None) -> Dict[str, Any]:
        """
        Analyze emotions using OpenAI API (논문 VA + 감정 군집 기준)
        
        Args:
            text: Input text to analyze
            context_texts: Optional list of similar context texts
            
        Returns:
            Dict with valence, arousal, polarity, cluster info + legacy format
        """
        prompt = self._create_prompt(text, context_texts)
        
        try:
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "당신은 한국어 감정 구조 논문을 기준으로 감정을 분석하는 전문가입니다. "
                            "반드시 유효한 JSON 객체만 응답하세요."
                        )
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.1,
                max_tokens=300,
                # gpt-4o-mini에서 json_object 안 되면 예외 처리에서 다시 호출
                response_format={"type": "json_object"}
            )
            generated_text = response.choices[0].message.content.strip()
            # print("\n=== OpenAI API Response (JSON mode) ===")
            # print(generated_text)
            # print("=" * 50)
        except Exception as e:
            if "response_format" in str(e).lower():
                print("JSON mode not supported, retrying without response_format...")
                response = self.client.chat.completions.create(
                    model=self.model_name,
                    messages=[
                        {
                            "role": "system",
                            "content": (
                                "당신은 한국어 감정 구조 논문을 기준으로 감정을 분석하는 전문가입니다. "
                                "반드시 유효한 JSON 객체만 응답하세요."
                            )
                        },
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    temperature=0.1,
                    max_tokens=300
                )
                generated_text = response.choices[0].message.content.strip()
                # print("\n=== OpenAI API Response ===")
                # print(generated_text)
                # print("=" * 50)
            else:
                raise e
        
        # VA + 군집 결과 파싱
        va_result = self._parse_llm_response(generated_text)
        
        # VA + 군집 형식만 반환 (레거시 형식 제거)
        result = {
            "valence": va_result["valence"],
            "arousal": va_result["arousal"],
            "polarity": va_result["polarity"],
            "cluster_id": va_result["cluster_id"],
            "cluster_label": va_result["cluster_label"],
            "related_clusters": va_result["related_clusters"]
        }
        
        return result


# Global instance
_emotion_analyzer = None


def get_emotion_analyzer() -> EmotionAnalyzer:
    """
    Get or create the global emotion analyzer instance
    
    Returns:
        EmotionAnalyzer instance
    """
    global _emotion_analyzer
    if _emotion_analyzer is None:
        _emotion_analyzer = EmotionAnalyzer()
    return _emotion_analyzer
