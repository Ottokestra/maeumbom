# 인터랙티브 시나리오 서비스 (관계 개선 훈련 + 공감 드라마)

사용자가 다양한 관계 상황에서 선택을 통해 시나리오를 진행하고, 최종 결과를 받을 수 있는 인터랙티브 경험을 제공합니다.

## 📋 목차

- [기능](#기능)
- [시나리오 데이터 관리](#시나리오-데이터-관리)
- [API 엔드포인트](#api-엔드포인트)
- [Excel 파일 형식](#excel-파일-형식)
- [사용 방법](#사용-방법)
- [트러블슈팅](#트러블슈팅)

## ✨ 기능

- ✅ 시나리오 목록 조회 (카테고리 필터 가능)
- ✅ 시나리오 시작 (첫 번째 노드 반환)
- ✅ 진행 처리 (선택지 선택 → 다음 노드 또는 결과)
- ✅ 경로 추적 (A → B → C 형식)
- ✅ 통계 제공 (드라마 시나리오의 경우)
- ✅ 플레이 로그 자동 저장
- ✅ Excel/JSON 파일로 시나리오 관리
- ✅ 자동 Import (서버 시작 시)

## 📊 시나리오 데이터 관리

### 파일 형식

시나리오 데이터는 **Excel 파일 (4개 시트)** 또는 **JSON 파일 (하나의 파일)**로 관리할 수 있습니다.

**Excel 파일**:
- 하나의 파일에 4개 시트 (scenarios, nodes, options, results)
- Excel에서 편집하기 편함

**JSON 파일** (추천):
- 하나의 파일에 모든 데이터 포함
- Cursor에서 바로 확인 가능
- 텍스트 파일이라 Git에서 diff 확인 가능

```
backend/app/relation_training/data/
├── template.xlsx          # Excel 템플릿
├── template.json          # JSON 템플릿 (추천)
├── 부모님과의대화.json     # 시나리오 1 (JSON)
├── 친구와의갈등.xlsx       # 시나리오 2 (Excel)
└── ...
```

### 자동 Import

서버 시작 시 `data/` 폴더의 Excel/JSON 파일들을 자동으로 DB에 저장합니다.

**작동 방식:**
- ✅ **중복 체크**: 같은 제목(`title`)의 시나리오는 자동으로 스킵 (중복 방지)
- ✅ **안전한 실행**: 에러 발생 시에도 서버는 계속 실행
- ✅ **새 파일만 import**: 기존 시나리오는 스킵하고 새 시나리오만 추가
- ✅ **로그 표시**: 어떤 파일이 import되었는지, 어떤 파일이 스킵되었는지 명확히 표시

**팀 협업 시나리오:**
1. 시나리오 작성자가 `data/` 폴더에 새 JSON/Excel 파일 추가
2. GitHub에 커밋 & push
3. 팀원들이 `git pull`로 최신 파일 받기
4. 서버 재시작 (`python main.py`)
5. 자동으로 새 시나리오만 import됨 (기존 시나리오는 스킵)

**중복 방지 메커니즘:**
- 시나리오 제목(`title`)으로 중복 체크
- 같은 제목이 이미 DB에 있으면 자동 스킵
- 로그에 "⏭️ 시나리오 '제목' 이미 존재 (스킵) - 중복 방지" 메시지 표시

### 수동 Import (선택사항)

특정 파일만 import하거나 재설정할 때 사용합니다.

```bash
# 특정 파일 import (Excel 또는 JSON)
python -m app.relation_training.import_data data/부모님과의대화.json
python -m app.relation_training.import_data data/부모님과의대화.xlsx

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
      "category": "TRAINING"
    }
  ],
  "total": 1
}
```

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

## 📝 Excel 파일 형식

### 파일 구조

하나의 Excel 파일에 4개의 시트:
1. **scenarios**: 시나리오 메타데이터
2. **nodes**: 각 단계의 상황
3. **options**: 선택지
4. **results**: 최종 결과

### 시트 1: scenarios

| scenario_id | title | target_type | category |
|-------------|-------|-------------|----------|
| 1 | 부모님과의 대화 | parent | TRAINING |

**컬럼 설명:**
- `scenario_id`: 시나리오 고유 ID (Excel 내에서만 사용, DB에서는 자동 생성)
- `title`: 시나리오 제목
- `target_type`: 대상 관계 (`parent`, `friend`, `partner`, `child`, `colleague`)
- `category`: 카테고리 (`TRAINING` 또는 `DRAMA`)

### 시트 2: nodes

| scenario_id | step_level | situation_text | image_url |
|-------------|------------|----------------|-----------|
| 1 | 1 | 부모님이 당신의 진로에 대해... | |
| 1 | 2 | 부모님이 당신의 이야기를... | |

**컬럼 설명:**
- `scenario_id`: 시나리오 ID (scenarios 시트의 scenario_id와 매칭)
- `step_level`: 단계 번호 (1부터 시작)
- `situation_text`: 상황 설명 텍스트
- `image_url`: 이미지 URL (선택사항, 비워두면 NULL)

### 시트 3: options

| scenario_id | node_step | option_code | option_text | next_step | result_code |
|-------------|-----------|-------------|-------------|-----------|-------------|
| 1 | 1 | A | 대화를 시작한다 | 2 | |
| 1 | 1 | B | 대화를 피한다 | | FAIL |
| 1 | 2 | A | 솔직하게 말한다 | | SUCCESS |

**컬럼 설명:**
- `scenario_id`: 시나리오 ID
- `node_step`: 이 선택지가 속한 노드의 step_level
- `option_code`: 선택지 코드 (`A`, `B`, `C`, `D`...)
- `option_text`: 선택지 텍스트
- `next_step`: 다음 노드의 step_level (빈칸이면 결과로 이동)
- `result_code`: 결과 코드 (next_step이 빈칸일 때 필수)

**중요:**
- `next_step`과 `result_code` 중 **하나는 반드시 있어야 함**
- `next_step`이 있으면 다음 노드로 이동
- `next_step`이 비어있으면 `result_code`로 결과 표시

### 시트 4: results

| scenario_id | result_code | display_title | analysis_text | atmosphere_image_type | score |
|-------------|-------------|---------------|---------------|----------------------|-------|
| 1 | SUCCESS | 성공적인 대화 | 부모님과 솔직하고... | positive | 85 |
| 1 | FAIL | 대화 실패 | 대화가 원활하게... | negative | 30 |

**컬럼 설명:**
- `scenario_id`: 시나리오 ID
- `result_code`: 결과 코드 (options 시트의 result_code와 매칭)
- `display_title`: 결과 제목
- `analysis_text`: 분석 내용
- `atmosphere_image_type`: 분위기 (`positive`, `negative`, `neutral`)
- `score`: 점수 (0-100, 선택사항)

## 📝 JSON 파일 형식 (추천)

### 파일 구조

하나의 JSON 파일에 모든 데이터가 포함됩니다.

```json
{
  "scenario": {
    "scenario_id": 1,
    "title": "부모님과의 대화",
    "target_type": "parent",
    "category": "TRAINING"
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
      "score": 85
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

### JSON 파일의 장점

- ✅ Cursor에서 바로 확인 가능 (텍스트 파일)
- ✅ Git에서 diff 확인 가능
- ✅ 하나의 파일에 모든 데이터 포함
- ✅ 구조화되어 있어 파싱이 쉬움

## 💡 사용 방법

### 1. 템플릿 복사

**JSON 파일 사용 (추천):**
```bash
cd backend/app/relation_training/data
cp template.json 내시나리오.json
```

**Excel 파일 사용:**
```bash
cd backend/app/relation_training/data
cp template.xlsx 내시나리오.xlsx
```

### 2. 파일 편집

**JSON 파일:**
- Cursor에서 `내시나리오.json` 파일을 열고 편집합니다.
- `template.json`을 참고하여 데이터를 채웁니다.

**Excel 파일:**
- Excel에서 `내시나리오.xlsx` 파일을 열고 4개 시트를 채웁니다.
- **작성 순서:**
  1. **scenarios** 시트: 시나리오 기본 정보
  2. **nodes** 시트: 각 단계의 상황 (step 1, 2, 3, 4...)
  3. **results** 시트: 가능한 결과들
  4. **options** 시트: 각 노드의 선택지 (next_step 또는 result_code 연결)

### 3. 서버 재시작

```bash
cd backend
python main.py
```

서버 시작 시 자동으로 Excel/JSON 파일이 DB에 import됩니다.

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
    "category": "TRAINING"
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
      "score": 80
    },
    {
      "result_code": "BAD",
      "display_title": "아쉬운 대화",
      "analysis_text": "좀 더 공감이 필요해요",
      "atmosphere_image_type": "negative",
      "score": 40
    }
  ]
}
```

### 간단한 2단계 시나리오 (Excel)

**scenarios:**
| scenario_id | title | target_type | category |
|-------------|-------|-------------|----------|
| 1 | 간단한 대화 | friend | TRAINING |

**nodes:**
| scenario_id | step_level | situation_text |
|-------------|------------|----------------|
| 1 | 1 | 친구가 고민을 이야기합니다. |
| 1 | 2 | 친구가 당신의 반응을 기다립니다. |

**results:**
| scenario_id | result_code | display_title | analysis_text | score |
|-------------|-------------|---------------|---------------|-------|
| 1 | GOOD | 좋은 대화 | 잘 들어주셨네요 | 80 |
| 1 | BAD | 아쉬운 대화 | 좀 더 공감이 필요해요 | 40 |

**options:**
| scenario_id | node_step | option_code | option_text | next_step | result_code |
|-------------|-----------|-------------|-------------|-----------|-------------|
| 1 | 1 | A | 공감하며 듣는다 | 2 | |
| 1 | 1 | B | 무시한다 | | BAD |
| 1 | 2 | A | 조언한다 | | GOOD |
| 1 | 2 | B | 화제를 돌린다 | | BAD |

## 🐛 트러블슈팅

### 1. "필수 시트가 없습니다" 오류 (Excel)

Excel 파일에 4개 시트(`scenarios`, `nodes`, `options`, `results`)가 모두 있는지 확인하세요.

### 1-1. "필수 필드가 없습니다" 오류 (JSON)

JSON 파일에 `scenario`, `nodes`, `options`, `results` 필드가 모두 있는지 확인하세요.

### 2. "존재하지 않는 next_step" 오류 (Excel)

`options` 시트의 `next_step` 값이 `nodes` 시트의 `step_level`에 실제로 존재하는지 확인하세요.

### 2-1. "존재하지 않는 from_node_id" 오류 (JSON)

`options` 배열의 `from_node_id` 값이 `nodes` 배열의 `id`에 실제로 존재하는지 확인하세요.

### 2-2. "존재하지 않는 to_node_id" 오류 (JSON)

`options` 배열의 `to_node_id` 값이 `nodes` 배열의 `id`에 실제로 존재하는지 확인하세요. `to_node_id`가 `null`이 아닌 경우에만 확인합니다.

### 3. "존재하지 않는 result_code" 오류

`options`의 `result_code` 값이 `results`의 `result_code`에 실제로 존재하는지 확인하세요.

### 4. 시나리오가 목록에 안 나타남

- 서버를 재시작했는지 확인
- 콘솔에서 import 성공 메시지 확인
- 수동 import 시도: `python -m app.relation_training.import_data data/파일명.xlsx`

### 5. "next_step 또는 result_code 중 하나는 필수" 오류 (Excel)

`options` 시트에서 각 선택지는 `next_step` 또는 `result_code` 중 **하나는 반드시** 있어야 합니다.

### 5-1. "to_node_id 또는 result_code 중 하나는 필수" 오류 (JSON)

`options` 배열에서 각 선택지는 `to_node_id` 또는 `result_code` 중 **하나는 반드시** 있어야 합니다.

### 6. "노드에 'id' 필드가 없습니다" 오류 (JSON)

JSON 파일의 모든 노드는 `id` 필드를 반드시 가져야 합니다. 각 노드에 고유한 `id`를 지정하세요 (예: "node_1", "node_2_a", "node_2_b").

## 📁 파일 구조

```
backend/app/relation_training/
├── __init__.py              # 패키지 초기화
├── data/                    # 시나리오 데이터 폴더
│   ├── template.xlsx        # 템플릿 파일
│   └── *.xlsx               # 시나리오 파일들
├── models.py                # (없음, app/db/models.py 사용)
├── schemas.py               # Pydantic 모델
├── service.py               # 비즈니스 로직
├── routes.py                # API 엔드포인트
├── import_data.py           # Excel import 스크립트
├── create_template.py       # 템플릿 생성 스크립트
└── README.md                # 이 문서
```

## 📚 참고 자료

- [FastAPI 문서](https://fastapi.tiangolo.com/)
- [SQLAlchemy 문서](https://docs.sqlalchemy.org/)
- [openpyxl 문서](https://openpyxl.readthedocs.io/)

## 🎓 팀원 공유 방법

1. Excel 파일을 Git에 커밋
2. 팀원이 Pull
3. 서버 재시작 → 자동 반영!

```bash
git add backend/app/relation_training/data/새시나리오.xlsx
git commit -m "Add: 새 시나리오 추가"
git push
```

팀원:
```bash
git pull
cd backend
python main.py  # 자동으로 새 시나리오 import됨
```
