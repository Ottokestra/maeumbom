# Deep Agent Pipeline 사용 가이드

## 개요

Deep Agent Pipeline은 사용자 입력을 받아 GPT-4o-mini로 시나리오를 생성하고, FLUX.1-schnell로 17장의 이미지를 자동 생성하는 완전 자동화 파이프라인입니다.

## 환경 변수 설정

`backend/.env` 파일에 다음 환경 변수를 추가하세요:

```bash
# ============================================================
# Deep Agent Pipeline 설정
# ============================================================

# 이미지 생성 제어
USE_SKIP_IMAGES=true       # 개발 모드: 이미지 생성 스킵 (NULL 저장)
USE_AMD_GPU=false          # AMD Radeon GPU 사용 (노트북)
USE_NVIDIA_GPU=false       # NVIDIA GPU 사용 (학원 컴퓨터)

# 성능 설정
MAX_PARALLEL_IMAGE_GENERATION=4    # 동시 생성 이미지 수 (1~8)
IMAGE_GENERATION_TIMEOUT=300       # 타임아웃 (초)

# OpenAI API (이미 설정되어 있어야 함)
OPENAI_API_KEY=sk-xxxxxxxxxxxxx
OPENAI_MODEL_NAME=gpt-4o-mini
```

## 패키지 설치 (중요!)

### ⚠️ PyTorch 설치 주의사항

**이 프로젝트는 TTS(Text-to-Speech) 기능에서도 PyTorch를 사용합니다!**

- `backend/engine/text-to-speech/` 모듈이 PyTorch에 의존
- Deep Agent뿐만 아니라 **TTS 기능도 PyTorch 필요**
- **절대로 PyTorch를 제거하지 마세요!**

### Windows 환경 (권장)

```bash
# 1. 표준 PyTorch 설치 (CPU 버전, TTS + Deep Agent 모두 지원)
pip install torch torchvision torchaudio

# 2. Deep Agent 추가 의존성
pip install diffusers transformers accelerate tenacity pillow
```

**특징:**
- ✅ Windows에서 안정적으로 작동
- ✅ TTS 기능 사용 가능
- ✅ Deep Agent 개발 가능 (`USE_SKIP_IMAGES=true`로)
- ✅ 학원 NVIDIA GPU에서도 동일한 코드로 작동

**주의:**
- ⚠️ ROCm (AMD GPU 지원)은 Windows에서 지원되지 않음
- ⚠️ Windows에서 AMD GPU를 사용하려면 DirectML 필요 (복잡, 비권장)

### Linux 환경 (AMD GPU) - 고급 사용자용

```bash
# ROCm 지원 PyTorch (AMD GPU 전용, Linux만 지원)
pip uninstall torch torchvision torchaudio -y
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0

# Deep Agent 추가 의존성
pip install diffusers transformers accelerate tenacity pillow
```

**주의:** Windows에서는 작동하지 않습니다!

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

### Phase 2: 프로덕션 (NVIDIA GPU) - 학원 컴퓨터

```bash
USE_SKIP_IMAGES=false
USE_AMD_GPU=false
USE_NVIDIA_GPU=true
```

**특징:**
- NVIDIA GPU로 빠른 이미지 생성
- 17장 생성 시간: 약 2~5분
- 학원 컴퓨터 등 고성능 GPU 환경

## API 사용법

### 1. 시나리오 생성 요청

**Endpoint:** `POST /api/service/relation-training/generate-scenario`

**Request:**
```json
{
  "target": "HUSBAND",
  "topic": "남편이 밥투정을 합니다"
}
```

**Headers:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Response:**
```json
{
  "scenario_id": 123,
  "status": "completed",
  "image_count": 17,
  "folder_name": "husband_20231215_143022",
  "message": "시나리오와 이미지가 성공적으로 생성되었습니다."
}
```

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

## 파일 구조

```
backend/app/relation_training/
├── prompts/
│   ├── scenario_architect.md      # Brain 프롬프트
│   └── cartoon_director.md        # Hands 프롬프트
├── data/
│   └── {user_id}/
│       └── {folder_name}.json     # 백업 JSON
├── images/
│   ├── {scenario_name}/           # 공용 시나리오 (기존)
│   └── {user_id}/
│       └── {folder_name}/         # 사용자별 시나리오 (Deep Agent)
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

1. `scenario_architect.md` 프롬프트 로드
2. 변수 치환 (TARGET, TOPIC)
3. GPT-4o-mini 호출
4. JSON 파싱 및 검증
5. Pydantic 모델 변환

**출력:** 15개 노드, 30개 선택지, 16개 결과

### Phase 2: The Hands (이미지 생성)

1. Character Design 추출
2. 경로 역추적 (AAAA~BBBB)
3. `cartoon_director.md`로 영문 프롬프트 생성
4. FLUX.1-schnell 호출 (병렬 처리)
5. 이미지 저장

**출력:** 17장 이미지 (1 start + 16 results)

### Phase 3: Persistence (저장)

1. JSON 파일 저장 (`data/{user_id}/{folder_name}.json`)
2. DB 저장:
   - TB_SCENARIOS (메타데이터)
   - TB_SCENARIO_NODES (15개, text → SITUATION_TEXT)
   - TB_SCENARIO_OPTIONS (30개, text → OPTION_TEXT)
   - TB_SCENARIO_RESULTS (16개, IMAGE_URL)

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

