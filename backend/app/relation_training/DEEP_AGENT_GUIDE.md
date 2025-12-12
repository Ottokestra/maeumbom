# Deep Agent Pipeline 사용 가이드

## 개요

Deep Agent Pipeline은 사용자 입력을 받아 Gemini API로 시나리오를 생성하고, Gemini 2.5 Flash로 17장의 이미지를 자동 생성하는 완전 자동화 파이프라인입니다.

**최신 업데이트 (2025-12-11)**:
- FLUX.1-schnell 로컬 모델 제거
- Gemini 2.5 Flash로 이미지 생성 전환 (빠르고 저렴)
- 시나리오 생성은 Gemini 2.5 Flash 사용 (scenario_architect.md 또는 scenario_prompt_drama.md)
- 오케스트레이션은 GPT-4o-mini 계속 사용 (프롬프트 준비, 검증, 파싱)
- **드라마 카테고리 추가**: 드라마 시나리오 생성 기능 (막장/로맨스/가족)
- **AUTO 기능**: AI가 자동으로 배역과 주제를 창작하는 기능
- **드라마 시나리오 공용화**: 드라마 시나리오는 모든 사용자에게 공개 (USER_ID = NULL)

## 환경 변수 설정

`backend/.env` 파일에 다음 환경 변수를 추가하세요:

```bash
# ============================================================
# Deep Agent Pipeline 설정
# ============================================================

# 이미지 생성 제어
USE_SKIP_IMAGES=true       # 개발 모드: 이미지 생성 스킵 (NULL 저장)
                           # false로 변경하면 Gemini 2.5 Flash로 이미지 생성

# 성능 설정
MAX_PARALLEL_IMAGE_GENERATION=4    # 동시 생성 이미지 수 (1~8)

# OpenAI API (Orchestration - 이미 설정되어 있어야 함)
OPENAI_API_KEY=sk-xxxxxxxxxxxxx
OPENAI_MODEL_NAME=gpt-4o-mini

# Gemini API (Scenario Generation + Image Generation)
SCENARIO_GENERATION_MODEL_NAME=gemini-2.5-flash
IMAGE_GENERATION_MODEL_NAME=gemini-2.5-flash-image
GEMINI_API_KEY=your_gemini_api_key_here
```

## 패키지 설치

### 필수 패키지

```bash
# Gemini API
pip install google-generativeai

# 기타 의존성
pip install tenacity pillow
```

**특징:**
- ✅ 로컬 GPU 불필요 (API 호출)
- ✅ 빠른 이미지 생성 (초당 1-2장)
- ✅ 저렴한 비용
- ✅ 한글 프롬프트 지원

**참고:**
- PyTorch는 TTS 기능에서만 사용됩니다
- diffusers, transformers는 더 이상 필요하지 않습니다

### Linux/Windows 환경 (NVIDIA GPU)

```bash
# CUDA 지원 PyTorch (NVIDIA GPU 전용)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Deep Agent 추가 의존성
pip install diffusers transformers accelerate tenacity pillow
```

## 개발 단계별 설정

### Phase 1: 개발 단계 (이미지 생성 스킵) - Windows 노트북 권장

```bash
USE_SKIP_IMAGES=true
USE_AMD_GPU=false
USE_NVIDIA_GPU=false
```

**특징:**
- 이미지 생성 없이 시나리오만 생성
- DB에 이미지 URL은 NULL로 저장
- 즉시 완료 (대기 시간 없음)
- 파이프라인 로직 테스트용
- **TTS 기능도 정상 작동**

**권장 환경:**
- Windows 노트북 (CPU 모드)
- 표준 PyTorch 설치

### Phase 2: 프로덕션 (이미지 생성 활성화)

```bash
USE_SKIP_IMAGES=false
```

**특징:**
- Gemini 2.5 Flash Image API로 이미지 생성
- 17장 생성 시간: 약 17-34초 (초당 1-2장)
- 로컬 GPU 불필요, API 호출로 처리
- 저렴한 비용 (~$0.17/시나리오)

## API 사용법

### 1. 시나리오 생성 요청

**Endpoint:** `POST /api/service/relation-training/generate-scenario`

**관계 개선 훈련 시나리오:**
```json
{
  "target": "HUSBAND",  # HUSBAND, CHILD, FRIEND, COLLEAGUE
  "topic": "매일 늦게 들어오는 남편",
  "category": "TRAINING"  # 기본값
}
```

**드라마 시나리오:**
```json
{
  "target": "AUTO",  # AUTO (랜덤 배역) 또는 HUSBAND, CHILD, FRIEND, COLLEAGUE
  "topic": "AUTO",  # AUTO (AI 자동 창작) 또는 직접 입력
  "category": "DRAMA",
  "genre": "MAKJANG"  # MAKJANG, ROMANCE, FAMILY
}
```

**참고:**
- 드라마 시나리오는 공용 시나리오로 생성됩니다 (USER_ID = NULL)
- `target: "AUTO"`를 사용하면 AI가 장르에 맞춰 배역을 자동 선택합니다
- `topic: "AUTO"`를 사용하면 AI가 장르에 맞춰 주제를 자동 창작합니다

**Headers:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Response (비동기 처리):**
```json
{
  "scenario_id": 0,
  "status": "processing",
  "image_count": 0,
  "folder_name": "",
  "message": "시나리오 생성이 시작되었습니다. 잠시 후 목록을 새로고침해주세요."
}
```

**참고:**
- 시나리오 생성은 백그라운드에서 비동기로 처리됩니다 (약 20-30초 소요)
- 생성 완료 후 시나리오 목록을 새로고침하면 생성된 시나리오를 확인할 수 있습니다
- 프론트엔드 UI에서 설정 아이콘을 통해 시나리오를 생성할 수 있습니다

### 2. 생성된 시나리오 확인

**Endpoint:** `GET /api/service/relation-training/scenarios`

생성된 시나리오가 목록에 표시됩니다.

### 3. 이미지 접근

**공용 시나리오 (기존):**
```
GET /api/service/relation-training/images/{scenario_name}/{filename}
예: /api/service/relation-training/images/husband_three_meals/start.png
```

**사용자별 시나리오 (Deep Agent):**
```
GET /api/service/relation-training/images/{user_id}/{scenario_name}/{filename}
예: /api/service/relation-training/images/123/husband_20231215_143022/start.png
```

**드라마 시나리오 (공용):**
```
GET /api/service/relation-training/images/public/{scenario_name}/{filename}
예: /api/service/relation-training/images/public/차가운_심장에_피어난_꽃_20251211_151150/start.png
```

**참고:**
- 드라마 시나리오는 `user_id="public"`으로 저장됩니다
- 공용 시나리오 이미지는 `images/public/` 폴더에 저장됩니다

## 파일 구조

```
backend/app/relation_training/
├── prompts/
│   ├── scenario_architect.md      # 관계 개선 훈련 프롬프트
│   ├── scenario_prompt_drama.md   # 드라마 프롬프트 (NEW!)
│   └── cartoon_director.md        # Hands 프롬프트
├── data/
│   ├── {user_id}/
│   │   └── {folder_name}.json     # 개인 시나리오 JSON
│   └── public/
│       └── {folder_name}.json     # 드라마 시나리오 JSON (NEW!)
├── images/
│   ├── {scenario_name}/           # 공용 시나리오 (기존)
│   ├── {user_id}/
│   │   └── {folder_name}/         # 사용자별 시나리오
│   │       ├── start.png
│   │       ├── result_AAAA.png
│   │       └── ... (총 17장)
│   └── public/
│       └── {folder_name}/         # 드라마 시나리오 이미지 (NEW!)
│           ├── start.png
│           ├── result_AAAA.png
│           └── ... (총 17장)
├── prompt_utils.py                # 프롬프트 로딩
├── image_generator.py             # 이미지 생성
├── path_tracker.py                # 경로 역추적
├── deep_agent_schemas.py          # Pydantic 모델
├── deep_agent_service.py          # 메인 서비스
└── routes.py                      # API 엔드포인트
```

## 동작 과정

### Phase 1: The Brain (시나리오 생성)

**관계 개선 훈련 (TRAINING):**
1. 프롬프트 로드: `scenario_architect.md`
2. 변수 치환 (TARGET, TOPIC)
3. Gemini 2.5 Flash API 호출
4. JSON 파싱 및 검증
5. Pydantic 모델 변환

**드라마 (DRAMA):**
1. 프롬프트 로드: `scenario_prompt_drama.md`
2. 변수 치환 (TARGET, TOPIC, GENRE)
3. Gemini 2.5 Flash API 호출
4. JSON 파싱 및 검증
5. Pydantic 모델 변환
6. **공용 시나리오로 저장** (USER_ID = NULL)

**출력:** 15개 노드, 30개 선택지, 16개 결과

### Phase 2: The Hands (이미지 생성)

1. Character Design 추출
2. 경로 역추적 (AAAA~BBBB)
3. `cartoon_director.md`로 영문 프롬프트 생성
4. FLUX.1-schnell 호출 (병렬 처리)
5. 이미지 저장

**출력:** 17장 이미지 (1 start + 16 results)

### Phase 3: Persistence (저장)

**관계 개선 훈련:**
1. JSON 파일 저장 (`data/{user_id}/{folder_name}.json`)
2. DB 저장: USER_ID = 사용자 ID
   - TB_SCENARIOS (메타데이터)
   - TB_SCENARIO_NODES (15개, text → SITUATION_TEXT)
   - TB_SCENARIO_OPTIONS (30개, text → OPTION_TEXT)
   - TB_SCENARIO_RESULTS (16개, IMAGE_URL)

**드라마:**
1. JSON 파일 저장 (`data/public/{folder_name}.json`)
2. DB 저장: USER_ID = NULL (공용 시나리오)
   - TB_SCENARIOS (메타데이터, CATEGORY = "DRAMA")
   - TB_SCENARIO_NODES (15개)
   - TB_SCENARIO_OPTIONS (30개)
   - TB_SCENARIO_RESULTS (16개)
3. 이미지 저장: `images/public/{folder_name}/`

## 트러블슈팅

### 1. "OPENAI_API_KEY not found"

**해결:** `backend/.env` 파일에 `OPENAI_API_KEY` 추가

### 2. "FLUX.1 model loading failed"

**원인:** GPU 드라이버 문제 또는 메모리 부족

**해결:**
- `USE_SKIP_IMAGES=true`로 설정하여 이미지 생성 스킵
- 또는 GPU 드라이버 업데이트

### 3. "JSON 파싱 실패"

**원인:** LLM이 잘못된 JSON 생성

**해결:** 자동 재시도 (최대 3회) - 코드에 이미 구현됨

### 4. 이미지 생성이 너무 느림

**해결:**
- `MAX_PARALLEL_IMAGE_GENERATION` 값 증가 (4 → 8)
- 더 빠른 GPU 사용 (NVIDIA)
- 또는 `USE_SKIP_IMAGES=true`로 개발 진행

### 5. "Image not found" (404)

**원인:** 이미지 URL 경로 불일치

**확인:**
- 공용 시나리오: `/images/{scenario_name}/{filename}`
- 사용자별: `/images/{user_id}/{scenario_name}/{filename}`

## 성능 최적화

### 1. 모델 사전 로드

서버 시작 시 FLUX.1 모델을 미리 로드하여 첫 요청 속도 향상:

```python
# main.py에 이미 구현됨
@asynccontextmanager
async def lifespan(app: FastAPI):
    await load_flux_model()
    yield
```

### 2. 병렬 이미지 생성

최대 4개 이미지를 동시에 생성:

```bash
MAX_PARALLEL_IMAGE_GENERATION=4  # 1~8 권장
```

### 3. GPU 메모리 최적화

```python
# image_generator.py에 이미 구현됨
pipe.enable_model_cpu_offload()
```

## 주의사항

1. **이미지 생성 시간**: 8~34분 소요 (AMD GPU 기준)
2. **GPU 메모리**: 최소 8GB VRAM 필요
3. **디스크 공간**: 이미지당 약 1~3MB (17장 = 약 17~51MB)
4. **API 비용**: OpenAI API 사용 (시나리오당 약 $0.01~0.05)
5. **라이선스**: FLUX.1-schnell은 Apache 2.0 (상업적 사용 가능)

## 문의

프로젝트 관련 문의사항이 있으면 팀에 문의하세요.

