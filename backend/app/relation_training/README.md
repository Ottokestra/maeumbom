# 인터랙티브 시나리오 서비스 (관계 개선 훈련 + 공감 드라마)

사용자가 다양한 관계 상황에서 선택을 통해 시나리오를 진행하고, 최종 결과를 받을 수 있는 인터랙티브 경험을 제공합니다.

## 📋 목차

- [기능](#기능)
- [Deep Agent Pipeline (자동 시나리오 생성)](#deep-agent-pipeline-자동-시나리오-생성)
- [시나리오 데이터 관리](#시나리오-데이터-관리)
- [API 엔드포인트](#api-엔드포인트)
- [JSON 파일 형식](#json-파일-형식)
- [사용 방법](#사용-방법)
- [트러블슈팅](#트러블슈팅)

## ✨ 기능

- ✅ 시나리오 목록 조회 (카테고리 필터 가능)
- ✅ 시나리오 시작 (첫 번째 노드 반환)
- ✅ 진행 처리 (선택지 선택 → 다음 노드 또는 결과)
- ✅ 경로 추적 (A → B → C 형식)
- ✅ 통계 제공 (드라마 시나리오의 경우)
- ✅ 플레이 로그 자동 저장
- ✅ JSON 파일로 시나리오 관리
- ✅ 자동 Import (서버 시작 시)
- ✅ **Deep Agent Pipeline (AI 자동 시나리오 생성)**

## 🤖 Deep Agent Pipeline (자동 시나리오 생성)

### 아키텍처

Deep Agent Pipeline은 **Orchestrator-Writer 패턴**을 사용합니다:

```
GPT-4o-mini (Orchestrator)
  ↓ 프롬프트 준비 및 변수 설정
Qwen 2.5 14B (Scenario Writer)
  ↓ 시나리오 텍스트 생성
GPT-4o-mini (Validator)
  ↓ 품질 검증 및 파싱
DB 저장
```

- **Orchestrator (GPT-4o-mini)**: 전체 파이프라인 기획, 프롬프트 준비, 결과 검증
- **Scenario Writer (Qwen 2.5 14B 또는 GPT-4o-mini)**: 시나리오 텍스트 생성
- **Image Generator (FLUX.1-schnell)**: 이미지 생성 (선택적)

### 환경 변수 설정

`.env` 파일에 다음 환경변수를 추가하세요:

```bash
# ============================================================================
# OpenAI API (Orchestrator - GPT-4o-mini)
# ============================================================================
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL_NAME=gpt-4o-mini

# ============================================================================
# Scenario Writer Configuration
# ============================================================================
# SCENARIO_MODE: Choose the LLM for scenario generation
# - "qwen" = Qwen 2.5 14B GGUF (로컬, 고품질, 무료, 느림 ~6-7분)
# - "openai" = GPT-4o-mini (API, 빠름 ~15초, 비용 발생)
SCENARIO_MODE=qwen

# PROMPT_STYLE: Choose prompt template style
# - "step" = step0~step3 분리된 프롬프트 (권장, 역할 분리 명확)
# - "architect" = scenario_architect.md 올인원 프롬프트 (레거시)
PROMPT_STYLE=step

# ============================================================================
# Image Generation Configuration
# ============================================================================
USE_SKIP_IMAGES=false
USE_AMD_GPU=false
USE_NVIDIA_GPU=false
MAX_PARALLEL_IMAGE_GENERATION=4
```

### 설치

Qwen 2.5 14B GGUF 모델을 사용하려면 `llama-cpp-python`이 필요합니다:

```bash
pip install llama-cpp-python==0.2.90
```

모델은 첫 실행 시 Hugging Face에서 자동으로 다운로드됩니다 (~8GB).

### 사용 방법

**API 호출:**

```bash
POST /api/service/relation-training/deep-agent/generate
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "target": "CHILD",  # CHILD, HUSBAND, FRIEND, COLLEAGUE, ETC
  "topic": "스마트폰 사용법 질문"
}
```

**응답:**

```json
{
  "scenario_id": 123,
  "status": "completed",
  "image_count": 17,
  "folder_name": "child_20231215_143022"
}
```

### 성능

| 모드 | 시간 | 비용 | 품질 |
|------|------|------|------|
| **Qwen 2.5 14B (로컬)** | ~6-7분 | 무료 | ⭐⭐⭐⭐⭐ |
| **GPT-4o-mini (API)** | ~15초 | ~$0.15 | ⭐⭐⭐ |

### 4단계 생성 프로세스

1. **STEP 0: Character Design** - 주인공과 타겟의 비주얼 설명 생성
2. **STEP 1: Nodes (15개)** - 시나리오 노드 생성 (타겟의 말/행동)
3. **STEP 2: Options (30개)** - 선택지 생성 (주인공의 선택/대사)
4. **STEP 3: Results (16개)** - 결과 및 분석 생성 (AAAA~BBBB)

### 프롬프트 파일

- `prompts/step0_character_design.md` - 캐릭터 디자인
- `prompts/step1_nodes.md` - 노드 생성 (역할 분리 규칙 포함)
- `prompts/step2_options.md` - 옵션 생성 (주인공 대사만)
- `prompts/step3_results.md` - 결과 생성 (타겟별 관계 표현)
- `prompts/scenario_architect.md` - 올인원 프롬프트 (레거시)

### 검증 로직

Orchestrator (GPT-4o-mini)는 각 단계에서 품질을 검증합니다:

- **노드 검증**: 개수(15), 필수 필드, 역할 분리 (주인공 대사 포함 여부)
- **옵션 검증**: 개수(30), 필수 필드, 주인공 대사만 포함
- **결과 검증**: 개수(16), 필수 필드, 타겟 관계 표현

### 문서

- `DEEP_AGENT_GUIDE.md` - 상세 가이드
- `LLM_STRUCTURE_ISSUE.md` - 아키텍처 변경 이력

## 📊 시나리오 데이터 관리

### 파일 형식

시나리오 데이터는 **JSON 파일**로 관리합니다.

**JSON 파일**:
- 하나의 파일에 모든 데이터 포함
- Cursor에서 바로 확인 가능
- 텍스트 파일이라 Git에서 diff 확인 가능
- 구조화되어 있어 파싱이 쉬움

```
backend/app/relation_training/data/
├── template.json          # JSON 템플릿
├── 부모님과의대화.json     # 시나리오 1
├── 친구와의갈등.json       # 시나리오 2
└── ...
```

### 자동 Import

서버 시작 시 `data/` 폴더의 JSON 파일들을 자동으로 DB에 저장합니다.

**작동 방식:**
- ✅ **중복 체크**: 같은 제목(`title`)의 시나리오는 자동으로 스킵 (중복 방지)
- ✅ **안전한 실행**: 에러 발생 시에도 서버는 계속 실행
- ✅ **새 파일만 import**: 기존 시나리오는 스킵하고 새 시나리오만 추가
- ✅ **로그 표시**: 어떤 파일이 import되었는지, 어떤 파일이 스킵되었는지 명확히 표시
- ✅ **스마트 업데이트**: 파일 수정 시간을 비교하여 DB보다 최신인 파일만 업데이트 (중복 체크 시)

**팀 협업 시나리오:**
1. 시나리오 작성자가 `data/` 폴더에 새 JSON 파일 추가
2. GitHub에 커밋 & push
3. 팀원들이 `git pull`로 최신 파일 받기
4. 서버 재시작 (`python main.py`)
5. 자동으로 새 시나리오만 import됨 (기존 시나리오는 스킵)

**중복 방지 메커니즘:**
- 시나리오 제목(`title`)으로 중복 체크
- 같은 제목이 이미 DB에 있으면:
  - 파일 수정 시간과 DB 업데이트 시간을 비교
  - 파일이 DB보다 최신이면 업데이트, 그렇지 않으면 스킵
  - 로그에 "⏭️ 시나리오 '제목' 이미 존재 (스킵) - 중복 방지" 메시지 표시

### 수동 Import (선택사항)

특정 파일만 import하거나 재설정할 때 사용합니다.

```bash
# 특정 파일 import
python -m app.relation_training.import_data data/부모님과의대화.json

# 전체 import
python -m app.relation_training.import_data --all

# 기존 데이터 삭제 후 전체 import
python -m app.relation_training.import_data --all --clear

# 기존 시나리오 업데이트
python -m app.relation_training.import_data data/부모님과의대화.json --update
```

## 🚀 API 엔드포인트

### 1. 시나리오 목록 조회

**GET** `/api/service/relation-training/scenarios`

**Query Parameters:**
- `category` (optional): `TRAINING` 또는 `DRAMA`

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "scenarios": [
    {
      "id": 1,
      "title": "부모님과의 대화",
      "target_type": "parent",
      "category": "TRAINING",
      "start_image_url": "/api/service/relation-training/images/husband_three_meals/start.png"
    }
  ],
  "total": 1
}
```

**참고:** `start_image_url`은 시나리오 목록에서 썸네일 이미지로 사용됩니다. JSON 파일의 `scenario.start_image_url` 필드에서 읽어옵니다.

### 2. 시나리오 시작

**GET** `/api/service/relation-training/scenarios/{scenario_id}/start`

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "scenario_id": 1,
  "scenario_title": "부모님과의 대화",
  "category": "TRAINING",
  "start_image_url": "/api/service/relation-training/images/husband_three_meals/start.png",
  "first_node": {
    "id": 1,
    "step_level": 1,
    "situation_text": "부모님이 당신의 진로에 대해 걱정하며 이야기를 꺼내십니다.",
    "image_url": null,
    "options": [
      {
        "id": 1,
        "option_text": "부모님의 걱정을 이해하고 대화를 시작한다",
        "option_code": "A"
      },
      {
        "id": 2,
        "option_text": "방으로 들어가 대화를 피한다",
        "option_code": "B"
      }
    ]
  }
}
```

**참고:** `start_image_url`은 JSON 파일의 `scenario.start_image_url` 필드에서 읽어옵니다. 시나리오 시작 화면에 표시되는 이미지입니다.

### 3. 시나리오 진행

**POST** `/api/service/relation-training/progress`

**Headers:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "scenario_id": 1,
  "current_node_id": 1,
  "selected_option_code": "A",
  "current_path": "A"
}
```

**Response (진행 중):**
```json
{
  "is_finished": false,
  "next_node": {
    "id": 2,
    "step_level": 2,
    "situation_text": "부모님이 당신의 이야기를 듣고 계십니다.",
    "image_url": null,
    "options": [...]
  },
  "result": null,
  "current_path": "A-A"
}
```

**Response (완료):**
```json
{
  "is_finished": true,
  "next_node": null,
  "result": {
    "result_id": 1,
    "result_code": "SUCCESS",
    "display_title": "성공적인 대화",
    "analysis_text": "부모님과 솔직하고 진솔한 대화를 나누셨습니다...",
    "atmosphere_image_type": "positive",
    "score": 85,
    "image_url": "/api/service/relation-training/images/husband_three_meals/result_AAAA.png",
    "stats": [
      {
        "result_id": 1,
        "result_code": "SUCCESS",
        "display_title": "성공적인 대화",
        "percentage": 65.5,
        "count": 131
      }
    ]
  },
  "current_path": "A-A-B"
}
```

### 4. 시나리오 이미지 조회

**GET** `/api/service/relation-training/images/{scenario_name}/{filename}`

시나리오에 사용되는 이미지 파일을 제공합니다. 인증이 필요하지 않습니다.

**Path Parameters:**
- `scenario_name`: 시나리오 폴더명 (예: `husband_three_meals`)
- `filename`: 이미지 파일명 (예: `start.png`, `result_AAAA.png`)

**Response:**
이미지 파일 (PNG 형식)

**사용 예시:**
```
GET /api/service/relation-training/images/husband_three_meals/start.png
GET /api/service/relation-training/images/husband_three_meals/result_AAAA.png
```

**참고:**
- 이미지는 `backend/app/relation_training/images/{scenario_name}/` 폴더에 저장됩니다
- 시나리오 시작 이미지: `start.png`
- 결과별 4컷만화 이미지: `result_{경로코드}.png` (예: `result_AAAA.png`, `result_AAB.png`)
- 노드별 상황 이미지: 각 노드의 `image_url` 필드에 지정된 파일명

## 📝 JSON 파일 형식

### 파일 구조

하나의 JSON 파일에 모든 데이터가 포함됩니다.

```json
{
  "scenario": {
    "scenario_id": 1,
    "title": "부모님과의 대화",
    "target_type": "parent",
    "category": "TRAINING",
    "start_image_url": "/api/service/relation-training/images/husband_three_meals/start.png"
  },
  "nodes": [
    {
      "id": "node_1",
      "step_level": 1,
      "situation_text": "부모님이 당신의 진로에 대해 걱정하며 이야기를 꺼내십니다.",
      "image_url": ""
    },
    {
      "id": "node_2",
      "step_level": 2,
      "situation_text": "부모님이 당신의 이야기를 진지하게 듣고 계십니다.",
      "image_url": ""
    }
  ],
  "options": [
    {
      "from_node_id": "node_1",
      "option_code": "A",
      "option_text": "부모님의 걱정을 이해하고 솔직하게 내 상황을 설명한다",
      "to_node_id": "node_2",
      "result_code": null
    },
    {
      "from_node_id": "node_1",
      "option_code": "B",
      "option_text": "괜찮다고만 말하고 대화를 피한다",
      "to_node_id": null,
      "result_code": "FAIL"
    }
  ],
  "results": [
    {
      "result_code": "SUCCESS",
      "display_title": "성공적인 대화",
      "analysis_text": "부모님과 솔직하고 진솔한 대화를 나누셨습니다...",
      "atmosphere_image_type": "positive",
      "score": 85,
      "image_url": "/api/service/relation-training/images/husband_three_meals/result_AAAA.png"
    }
  ]
}
```

### 필드 설명

**scenario:**
- `scenario_id`: 시나리오 고유 ID (JSON 내에서만 사용, DB에서는 자동 생성)
- `title`: 시나리오 제목
- `target_type`: 대상 관계 (`parent`, `friend`, `partner`, `child`, `colleague`)
- `category`: 카테고리 (`TRAINING` 또는 `DRAMA`)
- `start_image_url`: 시나리오 시작 이미지 URL (선택사항, 예: `/api/service/relation-training/images/husband_three_meals/start.png`)

**nodes:**
- `id`: **노드 고유 ID (필수)** - 각 노드를 구분하는 고유 문자열 (예: "node_1", "node_2_a", "node_2_b")
- `step_level`: 단계 번호 (1부터 시작) - 같은 레벨의 노드가 여러 개일 수 있음
- `situation_text`: 상황 설명 텍스트
- `image_url`: 이미지 URL (선택사항, 빈 문자열이면 NULL)

**중요:** 같은 `step_level`이라도 선택에 따라 다른 노드로 갈 수 있으므로, 각 노드에 고유한 `id`를 반드시 지정해야 합니다.

**options:**
- `from_node_id`: **이 선택지가 속한 노드의 ID (필수)** - `nodes` 배열의 `id` 값과 일치해야 함
- `option_code`: 선택지 코드 (`A`, `B`, `C`, `D`...)
- `option_text`: 선택지 텍스트
- `to_node_id`: 다음 노드의 ID (null이면 결과로 이동)
- `result_code`: 결과 코드 (`to_node_id`가 null일 때 필수)

**중요:**
- `to_node_id`와 `result_code` 중 **하나는 반드시 있어야 함**
- `to_node_id`가 있으면 해당 노드로 이동
- `to_node_id`가 `null`이면 `result_code`로 결과 표시
- `from_node_id`는 반드시 `nodes` 배열에 존재하는 `id`여야 함
- `to_node_id`가 있으면 반드시 `nodes` 배열에 존재하는 `id`여야 함

**results:**
- `result_code`: 결과 코드 (options의 result_code와 매칭)
- `display_title`: 결과 제목
- `analysis_text`: 분석 내용
- `atmosphere_image_type`: 분위기 (`positive`, `negative`, `neutral`)
- `score`: 점수 (0-100, 선택사항)
- `image_url`: 결과 4컷만화 이미지 파일명 또는 URL (선택사항, 예: `result_AAAA.png` 또는 `/api/service/relation-training/images/husband_three_meals/result_AAAA.png`)

### JSON 파일의 장점

- ✅ Cursor에서 바로 확인 가능 (텍스트 파일)
- ✅ Git에서 diff 확인 가능
- ✅ 하나의 파일에 모든 데이터 포함
- ✅ 구조화되어 있어 파싱이 쉬움

## 💡 사용 방법

### 1. 템플릿 복사

```bash
cd backend/app/relation_training/data
cp template.json 내시나리오.json
```

### 2. 파일 편집

- Cursor에서 `내시나리오.json` 파일을 열고 편집합니다.
- `template.json`을 참고하여 데이터를 채웁니다.

### 3. 서버 재시작

```bash
cd backend
python main.py
```

서버 시작 시 자동으로 JSON 파일이 DB에 import됩니다.

**중복 체크:**
- 같은 제목의 시나리오는 자동으로 스킵됩니다
- 로그에서 "⏭️ 시나리오 '제목' 이미 존재 (스킵) - 중복 방지" 메시지를 확인할 수 있습니다

### 4. 팀 협업 (GitHub 사용 시)

**시나리오 작성자:**
```bash
# 1. 새 시나리오 파일 작성
cd backend/app/relation_training/data
cp template.json 새시나리오.json
# ... 파일 편집 ...

# 2. GitHub에 커밋 & push
git add backend/app/relation_training/data/새시나리오.json
git commit -m "Add: 새 시나리오 추가"
git push
```

**팀원들:**
```bash
# 1. 최신 파일 받기
git pull

# 2. 서버 재시작 (자동으로 새 시나리오 import됨)
python main.py
```

**결과:**
- 새 시나리오는 자동으로 import됨
- 기존 시나리오는 스킵됨 (중복 방지)
- 팀원들이 별도 명령어 실행 불필요

### 5. 프론트엔드에서 테스트

1. http://localhost:5173 접속
2. 로그인
3. "시나리오 테스트" 탭 클릭
4. 시나리오 선택 및 플레이

## 🎯 시나리오 작성 예시

### 간단한 2단계 시나리오 (JSON)

```json
{
  "scenario": {
    "scenario_id": 1,
    "title": "간단한 대화",
    "target_type": "friend",
    "category": "TRAINING",
    "start_image_url": ""
  },
  "nodes": [
    {
      "id": "node_1",
      "step_level": 1,
      "situation_text": "친구가 고민을 이야기합니다.",
      "image_url": ""
    },
    {
      "id": "node_2",
      "step_level": 2,
      "situation_text": "친구가 당신의 반응을 기다립니다.",
      "image_url": ""
    }
  ],
  "options": [
    {
      "from_node_id": "node_1",
      "option_code": "A",
      "option_text": "공감하며 듣는다",
      "to_node_id": "node_2",
      "result_code": null
    },
    {
      "from_node_id": "node_1",
      "option_code": "B",
      "option_text": "무시한다",
      "to_node_id": null,
      "result_code": "BAD"
    },
    {
      "from_node_id": "node_2",
      "option_code": "A",
      "option_text": "조언한다",
      "to_node_id": null,
      "result_code": "GOOD"
    },
    {
      "from_node_id": "node_2",
      "option_code": "B",
      "option_text": "화제를 돌린다",
      "to_node_id": null,
      "result_code": "BAD"
    }
  ],
  "results": [
    {
      "result_code": "GOOD",
      "display_title": "좋은 대화",
      "analysis_text": "잘 들어주셨네요",
      "atmosphere_image_type": "positive",
      "score": 80,
      "image_url": ""
    },
    {
      "result_code": "BAD",
      "display_title": "아쉬운 대화",
      "analysis_text": "좀 더 공감이 필요해요",
      "atmosphere_image_type": "negative",
      "score": 40,
      "image_url": ""
    }
  ]
}
```

## 🐛 트러블슈팅

### 1. "필수 필드가 없습니다" 오류

JSON 파일에 `scenario`, `nodes`, `options`, `results` 필드가 모두 있는지 확인하세요.

### 2. "존재하지 않는 from_node_id" 오류

`options` 배열의 `from_node_id` 값이 `nodes` 배열의 `id`에 실제로 존재하는지 확인하세요.

### 3. "존재하지 않는 to_node_id" 오류

`options` 배열의 `to_node_id` 값이 `nodes` 배열의 `id`에 실제로 존재하는지 확인하세요. `to_node_id`가 `null`이 아닌 경우에만 확인합니다.

### 4. "존재하지 않는 result_code" 오류

`options`의 `result_code` 값이 `results`의 `result_code`에 실제로 존재하는지 확인하세요.

### 5. 시나리오가 목록에 안 나타남

- 서버를 재시작했는지 확인
- 콘솔에서 import 성공 메시지 확인
- 수동 import 시도: `python -m app.relation_training.import_data data/파일명.json`

### 6. "to_node_id 또는 result_code 중 하나는 필수" 오류

`options` 배열에서 각 선택지는 `to_node_id` 또는 `result_code` 중 **하나는 반드시** 있어야 합니다.

### 7. "노드에 'id' 필드가 없습니다" 오류

JSON 파일의 모든 노드는 `id` 필드를 반드시 가져야 합니다. 각 노드에 고유한 `id`를 지정하세요 (예: "node_1", "node_2_a", "node_2_b").

## 📁 파일 구조

```
backend/app/relation_training/
├── __init__.py              # 패키지 초기화
├── data/                    # 시나리오 데이터 폴더
│   ├── template.json        # JSON 템플릿 파일
│   └── *.json               # 시나리오 파일들
├── models.py                # (없음, app/db/models.py 사용)
├── schemas.py               # Pydantic 모델
├── service.py               # 비즈니스 로직
├── routes.py                # API 엔드포인트
├── import_data.py           # JSON import 스크립트
├── create_template.py       # 템플릿 생성 스크립트
└── README.md                # 이 문서
```

## 📚 참고 자료

- [FastAPI 문서](https://fastapi.tiangolo.com/)
- [SQLAlchemy 문서](https://docs.sqlalchemy.org/)

## 🎓 팀원 공유 방법

1. JSON 파일을 Git에 커밋
2. 팀원이 Pull
3. 서버 재시작 → 자동 반영!

```bash
git add backend/app/relation_training/data/새시나리오.json
git commit -m "Add: 새 시나리오 추가"
git push
```

팀원:
```bash
git pull
cd backend
python main.py  # 자동으로 새 시나리오 import됨
```
