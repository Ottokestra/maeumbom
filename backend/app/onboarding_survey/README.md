# Onboarding Survey Service

온보딩 설문 서비스 - 사용자 프로필 데이터 관리

## 개요

프론트엔드 `frontend/lib/app/sign/` 설문 조사(Q1~Q11)의 응답 데이터를 저장하고 관리하는 서비스입니다.

## 데이터 구조

### TB_USER_PROFILE 테이블

- **단일선택 필드** (한글 텍스트로 저장):
  - `NICKNAME`: 닉네임 (Q1)
  - `AGE_GROUP`: 연령대 (Q2) - '40대', '50대', '60대', '70대 이상'
  - `GENDER`: 성별 (Q3) - '여성', '남성'
  - `MARITAL_STATUS`: 결혼 여부 (Q4) - '미혼', '기혼', '이혼/사별', '말하고 싶지 않음'
  - `CHILDREN_YN`: 자녀 유무 (Q5) - '있음', '없음'
  - `PERSONALITY_TYPE`: 성향 (Q7) - '내향적', '외향적', '상황에따라'
  - `ACTIVITY_STYLE`: 활동 스타일 (Q8) - '조용한 활동이 좋아요', '활동적인게 좋아요', '상황에 따라 달라요'

- **다중선택 필드** (JSON 배열로 저장, 한글 텍스트):
  - `LIVING_WITH`: 동거인 (Q6) - ["혼자", "배우자와", "자녀와", "부모님과", "가족과 함께", "기타"]
  - `STRESS_RELIEF`: 스트레스 해소법 (Q9) - ["혼자 조용히 해결해요", "누군가와 대화를 나눠요", "산책을 해요", "운동을 해요", "취미 활동을 해요", "그냥 잊고 넘어가요", "바로 감정이 격해져요", "기타"]
  - `HOBBIES`: 취미 (Q10) - ["등산", "산책", "음악감상", "독서", "영화/드라마", "요리", "정원/식물", "반려동물", "여행", "정리정돈", "공예/DIY", "기타"]
  - `ATMOSPHERE`: 선호 분위기 (Q11, optional) - ["잔잔한 분위기", "밝고 명랑한 분위기", "감성적인 스타일", "차분함", "활발함", "따뜻하고 부드러운 느낌"]
    - **주의**: Q11은 현재 프론트엔드에 구현되지 않았으며, 빈 배열로 전송됩니다.

## API 엔드포인트

### 1. POST /api/onboarding-survey/submit
설문 제출 또는 수정 (Upsert)

**인증**: 필요

**요청 Body**:
```json
{
  "nickname": "봄이",
  "age_group": "50대",
  "gender": "여성",
  "marital_status": "기혼",
  "children_yn": "있음",
  "living_with": ["배우자와", "자녀와"],
  "personality_type": "외향적",
  "activity_style": "활동적인게 좋아요",
  "stress_relief": ["산책을 해요", "누군가와 대화를 나눠요", "취미 활동을 해요"],
  "hobbies": ["산책", "음악감상", "독서"],
  "atmosphere": []
}
```

**응답**:
```json
{
  "id": 1,
  "user_id": 123,
  "nickname": "봄이",
  "age_group": "50대",
  "gender": "여성",
  "marital_status": "기혼",
  "children_yn": "있음",
  "living_with": ["배우자와", "자녀와"],
  "personality_type": "외향적",
  "activity_style": "활동적인게 좋아요",
  "stress_relief": ["산책을 해요", "누군가와 대화를 나눠요", "취미 활동을 해요"],
  "hobbies": ["산책", "음악감상", "독서"],
  "atmosphere": [],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### 2. GET /api/onboarding-survey/me
내 프로필 조회

**인증**: 필요

**응답**: 위와 동일

### 3. GET /api/onboarding-survey/status
프로필 완료 여부 확인

**인증**: 필요

**응답**:
```json
{
  "has_profile": true,
  "profile": { /* OnboardingSurveyResponse */ }
}
```

## 사용 방법

### 프로필 생성/수정
```python
from app.onboarding_survey.service import create_or_update_profile
from app.onboarding_survey.models import OnboardingSurveySubmitRequest

request = OnboardingSurveySubmitRequest(
    nickname="봄이",
    age_group="50대",
    gender="여성",
    marital_status="기혼",
    children_yn="있음",
    living_with=["배우자와", "자녀와"],
    personality_type="외향적",
    activity_style="활동적인게 좋아요",
    stress_relief=["산책을 해요", "누군가와 대화를 나눠요"],
    hobbies=["산책", "음악감상"],
    atmosphere=[]
)

profile = create_or_update_profile(db, user_id, request)
```

### 프로필 조회
```python
from app.onboarding_survey.service import get_user_profile

profile = get_user_profile(db, user_id)
if profile:
    print(f"Nickname: {profile.NICKNAME}")
    print(f"Hobbies: {profile.HOBBIES}")  # JSON 배열
```

## 특징

- **Upsert 방식**: 하나의 엔드포인트로 생성/수정 모두 처리
- **한글 텍스트 저장**: 프론트엔드와 동일한 한글 텍스트를 직접 저장하여 변환 로직 불필요
- **JSON 배열**: 다중선택 항목은 JSON 배열로 저장하여 유연성 확보
- **표준 필드**: IS_DELETED, CREATED_AT, CREATED_BY, UPDATED_AT, UPDATED_BY 포함
- **Q11 Optional**: ATMOSPHERE 필드는 nullable로 설정되어 있으며, 프론트엔드 구현 시 추가 가능

