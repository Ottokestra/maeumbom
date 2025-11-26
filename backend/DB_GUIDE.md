# Database 개발 가이드

이 문서는 `backend/app/db/` 폴더의 데이터베이스 관리 및 새로운 DB 모델을 추가하는 개발자를 위한 가이드입니다.

**중요**: 이 가이드를 Cursor AI 프롬프트에 포함하면, 동일한 DB 구조와 네이밍 규칙으로 새로운 모델을 생성할 수 있습니다.

## DB 구조

### 폴더 구조

```
backend/app/db/
├── __init__.py        # 패키지 초기화 (Base, get_db, models export)
├── database.py        # DB 연결 설정 (Base, get_db(), init_db())
└── models.py          # 모든 SQLAlchemy 모델 정의
```

### 역할 분담

- **`database.py`**: DB 연결 설정, Base 클래스, 세션 관리
- **`models.py`**: 모든 SQLAlchemy 모델 정의 (테이블 스키마)
- **`__init__.py`**: 외부에서 쉽게 import할 수 있도록 export

## 네이밍 규칙

### 테이블명

- **모든 테이블**: `TB_` 접두사 사용 (예: `TB_EMOTION_ANALYSIS`, `TB_USERS`, `TB_DAILY_MOOD_SELECTIONS`)

### 컬럼명

- **모든 컬럼**: 모두 대문자 (예: `ID`, `USER_ID`, `SESSION_ID`, `CREATED_AT`)

### 모델 클래스명

- PascalCase 사용 (예: `EmotionAnalysis`, `User`, `DailyMoodSelection`)

## 필드 규칙

### Primary Key

```python
ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
```

- 필드명: `ID` (대문자)
- 타입: `Integer`
- 옵션: `primary_key=True`, `index=True`, `autoincrement=True`

### Foreign Key

```python
USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
```

- 필드명: `참조테이블명_ID` 형식 (예: `USER_ID`, `POST_ID`)
- 타입: `Integer`
- 옵션: `ForeignKey("TB_테이블명.ID")`, `index=True`
- nullable: 선택 사항에 따라 설정

### 타임스탬프

```python
CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
```

- `CREATED_AT`: 필수 (생성 시간)
- `UPDATED_AT`: 선택 (수정 시간, 필요한 경우에만)

### JSON 필드

```python
RAW_DISTRIBUTION = Column(JSON, nullable=True)
```

- 복잡한 구조의 데이터는 JSON 타입 사용
- MySQL 5.7+ 지원
- nullable 여부는 요구사항에 따라 설정

### 인덱스

```python
__table_args__ = (
    Index('idx_session_created', 'SESSION_ID', 'CREATED_AT'),
    Index('idx_user_created', 'USER_ID', 'CREATED_AT'),
)
```

- Foreign Key 컬럼에는 자동으로 인덱스 생성
- 검색에 자주 사용되는 컬럼에 인덱스 추가
- 복합 인덱스는 `__table_args__`에 정의

## 새로운 모델 추가하기

### 1. `backend/app/db/models.py`에 모델 추가

```python
class YourNewModel(Base):
    """
    Your new model description
    
    Attributes:
        ID: Primary key
        USER_ID: Foreign key to users table
        YOUR_FIELD: Description
        CREATED_AT: Creation timestamp
    """
    __tablename__ = "TB_YOUR_TABLE_NAME"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    YOUR_FIELD = Column(String(255), nullable=False)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    
    # 인덱스 정의 (필요한 경우)
    __table_args__ = (
        Index('idx_your_index', 'YOUR_FIELD', 'CREATED_AT'),
    )
    
    # Relationship 정의 (필요한 경우)
    user = relationship("User", backref="your_new_models")
    
    def __repr__(self):
        return f"<YourNewModel(ID={self.ID}, YOUR_FIELD={self.YOUR_FIELD})>"
```

### 2. `backend/app/db/__init__.py`에 export 추가

```python
from .models import User, DailyMoodSelection, EmotionAnalysis, YourNewModel

__all__ = [
    "Base",
    "get_db",
    "init_db",
    "engine",
    "SessionLocal",
    "User",
    "DailyMoodSelection",
    "EmotionAnalysis",
    "YourNewModel",  # 추가
]
```

### 3. 모델 사용하기

```python
from app.db.database import get_db
from app.db.models import YourNewModel
from fastapi import Depends
from sqlalchemy.orm import Session

@app.post("/your-endpoint")
def create_item(db: Session = Depends(get_db)):
    new_item = YourNewModel(
        USER_ID=1,
        YOUR_FIELD="value"
    )
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item
```

## Import 규칙

### Base import

```python
from app.db.database import Base
```

### 모델 import

```python
from app.db.models import EmotionAnalysis, User, YourNewModel
```

### DB 세션 import

```python
from app.db.database import get_db
```

### 전체 import (권장)

```python
from app.db import Base, get_db, EmotionAnalysis, User
```

## DB 초기화

### 애플리케이션 시작 시

```python
from app.db.database import init_db

# FastAPI 앱 시작 시
init_db()
```

`init_db()` 함수는 `app.db.models`의 모든 모델을 자동으로 import하여 테이블을 생성합니다.

## 마이그레이션

### 주의사항

- 기존 테이블의 컬럼명이나 테이블명을 변경하면 데이터 손실 위험
- 프로덕션 환경에서는 Alembic 같은 마이그레이션 도구 사용 권장
- 개발 환경에서는 `init_db()`로 테이블 자동 생성

### 기존 모델 수정 시

1. 새 컬럼 추가: `nullable=True`로 설정하여 기존 데이터 보호
2. 컬럼 삭제: 데이터 백업 후 진행
3. 테이블명/컬럼명 변경: 마이그레이션 스크립트 작성 필요

## 예시 프로젝트 참고

### 모든 모델 (새 규칙 적용)

- `User`: 인증 사용자 모델 (테이블명: `TB_USERS`, 컬럼명: 대문자)
- `DailyMoodSelection`: 일일 감정 체크 모델 (테이블명: `TB_DAILY_MOOD_SELECTIONS`, 컬럼명: 대문자)
- `EmotionAnalysis`: 감정분석 결과 모델 (테이블명: `TB_EMOTION_ANALYSIS`, 컬럼명: 대문자)

## Cursor AI 사용 시

이 가이드를 Cursor AI 프롬프트에 포함하고 다음과 같이 요청하면, 규칙에 맞는 모델이 생성됩니다:

```
"backend/DB_GUIDE.md를 참고하여 
backend/app/db/models.py에 새로운 모델을 추가해줘.
모델 이름은 'ConversationLog'이고, 테이블명은 'TB_CONVERSATION_LOG'로 해줘.
필드는 ID, USER_ID, SESSION_ID, MESSAGE, CREATED_AT이 필요해."
```

## 문의

프로젝트 관련 문의사항이 있으면 팀에 문의하세요.

