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
CREATED_AT = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
```

- `CREATED_AT`: 필수 (생성 시간)
- `UPDATED_AT`: 권장 (수정 시간, 표준 필드에 포함)

**참고**: 표준 필드 섹션을 참조하여 `CREATED_BY`, `UPDATED_BY`도 함께 사용하는 것을 권장합니다.

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

## 표준 필드 (권장)

모든 모델에 다음 5가지 표준 필드를 포함하는 것을 권장합니다:

1. **삭제플래그** (`IS_DELETED` 또는 `DELETED_AT`)
2. **생성일자** (`CREATED_AT`)
3. **생성자** (`CREATED_BY`)
4. **수정일자** (`UPDATED_AT`)
5. **수정자** (`UPDATED_BY`)

### 삭제플래그

**방법 1: Boolean 방식 (권장)**

```python
IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
```

- 필드명: `IS_DELETED`
- 타입: `Boolean`
- 기본값: `False`
- nullable: `False`
- 인덱스: `True` (삭제되지 않은 데이터 조회 성능 향상)
- 사용법: 삭제 시 `IS_DELETED=True`로 설정 (실제 데이터는 유지)

**방법 2: DateTime 방식 (삭제 시간 추적 필요 시)**

```python
DELETED_AT = Column(DateTime(timezone=True), nullable=True, index=True)
```

- 필드명: `DELETED_AT`
- 타입: `DateTime(timezone=True)`
- nullable: `True` (삭제되지 않은 경우 NULL)
- 인덱스: `True`
- 사용법: 삭제 시 `DELETED_AT=func.now()`로 설정

**권장**: Boolean 방식(`IS_DELETED`)을 사용하세요. 삭제 시간이 필요한 경우에만 DateTime 방식(`DELETED_AT`)을 사용하세요.

### 생성일자

```python
CREATED_AT = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
```

- 필드명: `CREATED_AT`
- 타입: `DateTime(timezone=True)`
- 옵션: `server_default=func.now()` (DB에서 자동 설정)
- nullable: `False` (필수)
- 인덱스: 필요에 따라 추가 (검색에 자주 사용되는 경우)

### 생성자

```python
CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
```

- 필드명: `CREATED_BY`
- 타입: `Integer` (USER_ID 참조)
- 옵션: `ForeignKey("TB_USERS.ID")`, `index=True`
- nullable: `True` (시스템 생성 데이터의 경우 NULL 가능)
- 사용법: 생성한 사용자의 `USER_ID` 저장

**참고**: 시스템 자동 생성 데이터의 경우 `nullable=True`로 설정하여 NULL 허용

### 수정일자

```python
UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
```

- 필드명: `UPDATED_AT`
- 타입: `DateTime(timezone=True)`
- 옵션: `server_default=func.now()`, `onupdate=func.now()` (자동 업데이트)
- nullable: `False` (필수)
- 사용법: 데이터 수정 시 자동으로 현재 시간으로 업데이트

### 수정자

```python
UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
```

- 필드명: `UPDATED_BY`
- 타입: `Integer` (USER_ID 참조)
- 옵션: `ForeignKey("TB_USERS.ID")`, `index=True`
- nullable: `True` (시스템 자동 업데이트의 경우 NULL 가능)
- 사용법: 수정한 사용자의 `USER_ID` 저장

**참고**: 수정 시마다 명시적으로 `UPDATED_BY`를 설정해야 합니다. `onupdate`는 `UPDATED_AT`에만 적용됩니다.

### 표준 필드 사용 예시

```python
class YourNewModel(Base):
    """
    Your new model with standard fields
    
    Attributes:
        ID: Primary key
        YOUR_FIELD: Your custom field
        IS_DELETED: Deletion flag
        CREATED_AT: Creation timestamp
        CREATED_BY: Creator user ID
        UPDATED_AT: Last update timestamp
        UPDATED_BY: Last updater user ID
    """
    __tablename__ = "TB_YOUR_TABLE_NAME"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    YOUR_FIELD = Column(String(255), nullable=False)
    
    # 표준 필드
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    
    # Relationships
    creator = relationship("User", foreign_keys=[CREATED_BY], backref="created_items")
    updater = relationship("User", foreign_keys=[UPDATED_BY], backref="updated_items")
    
    def __repr__(self):
        return f"<YourNewModel(ID={self.ID}, YOUR_FIELD={self.YOUR_FIELD})>"
```

### 표준 필드 사용 시 주의사항

1. **조회 시 삭제된 데이터 제외**: `IS_DELETED=False` 조건 추가
   ```python
   items = db.query(YourModel).filter(YourModel.IS_DELETED == False).all()
   ```

2. **생성 시 생성자 설정**: 현재 로그인한 사용자 ID 설정
   ```python
   new_item = YourModel(
       YOUR_FIELD="value",
       CREATED_BY=current_user.id
   )
   ```

3. **수정 시 수정자 설정**: 현재 로그인한 사용자 ID 명시적으로 설정
   ```python
   item.YOUR_FIELD = "new_value"
   item.UPDATED_BY = current_user.id
   db.commit()
   ```

4. **삭제 시 소프트 삭제**: 실제 삭제 대신 플래그 설정
   ```python
   item.IS_DELETED = True
   item.UPDATED_BY = current_user.id
   db.commit()
   ```

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
        IS_DELETED: Deletion flag
        CREATED_AT: Creation timestamp
        CREATED_BY: Creator user ID
        UPDATED_AT: Last update timestamp
        UPDATED_BY: Last updater user ID
    """
    __tablename__ = "TB_YOUR_TABLE_NAME"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    USER_ID = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    YOUR_FIELD = Column(String(255), nullable=False)
    
    # 표준 필드 (권장)
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    
    # 인덱스 정의 (필요한 경우)
    __table_args__ = (
        Index('idx_your_index', 'YOUR_FIELD', 'CREATED_AT'),
    )
    
    # Relationship 정의 (필요한 경우)
    user = relationship("User", foreign_keys=[USER_ID], backref="your_new_models")
    creator = relationship("User", foreign_keys=[CREATED_BY], backref="created_your_models")
    updater = relationship("User", foreign_keys=[UPDATED_BY], backref="updated_your_models")
    
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

from app.auth.dependencies import get_current_user
from app.auth.models import User

@app.post("/your-endpoint")
def create_item(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """표준 필드를 포함한 항목 생성"""
    new_item = YourNewModel(
        USER_ID=current_user.id,
        YOUR_FIELD="value",
        CREATED_BY=current_user.id  # 생성자 설정
    )
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item

@app.put("/your-endpoint/{item_id}")
def update_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """표준 필드를 포함한 항목 수정"""
    item = db.query(YourNewModel).filter(
        YourNewModel.ID == item_id,
        YourNewModel.IS_DELETED == False  # 삭제되지 않은 항목만 조회
    ).first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    item.YOUR_FIELD = "new_value"
    item.UPDATED_BY = current_user.id  # 수정자 설정
    db.commit()
    db.refresh(item)
    return item

@app.delete("/your-endpoint/{item_id}")
def delete_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """소프트 삭제 (표준 필드 사용)"""
    item = db.query(YourNewModel).filter(
        YourNewModel.ID == item_id,
        YourNewModel.IS_DELETED == False
    ).first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    item.IS_DELETED = True  # 삭제 플래그 설정
    item.UPDATED_BY = current_user.id
    db.commit()
    return {"message": "Item deleted successfully"}

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

### 기존 모델에 표준 필드 추가하기

기존 모델에 표준 필드를 추가할 때는 다음 순서를 따르세요:

#### 1. 모델에 표준 필드 추가

```python
class YourExistingModel(Base):
    __tablename__ = "TB_YOUR_EXISTING_TABLE"
    
    ID = Column(Integer, primary_key=True, index=True, autoincrement=True)
    YOUR_FIELD = Column(String(255), nullable=False)
    
    # 기존 필드
    CREATED_AT = Column(DateTime(timezone=True), server_default=func.now())
    
    # 추가할 표준 필드 (nullable=True로 설정하여 기존 데이터 보호)
    IS_DELETED = Column(Boolean, default=False, nullable=False, index=True)
    CREATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=True)
    UPDATED_BY = Column(Integer, ForeignKey("TB_USERS.ID"), nullable=True, index=True)
    
    # Relationships 추가
    creator = relationship("User", foreign_keys=[CREATED_BY], backref="created_your_existing_models")
    updater = relationship("User", foreign_keys=[UPDATED_BY], backref="updated_your_existing_models")
```

**주의사항**:
- `IS_DELETED`: `nullable=False`이지만 `default=False`로 설정하여 기존 데이터는 자동으로 `False`가 됩니다.
- `CREATED_BY`, `UPDATED_BY`: `nullable=True`로 설정하여 기존 데이터는 NULL로 유지됩니다.
- `UPDATED_AT`: `nullable=True`로 설정하고, 기존 데이터는 `CREATED_AT` 값으로 업데이트하는 스크립트를 실행할 수 있습니다.

#### 2. 기존 데이터 마이그레이션 (선택사항)

기존 데이터에 기본값을 설정하려면 마이그레이션 스크립트를 실행하세요:

```python
from app.db.database import SessionLocal
from app.db.models import YourExistingModel

def migrate_existing_data():
    """기존 데이터에 표준 필드 값 설정"""
    db = SessionLocal()
    try:
        # UPDATED_AT을 CREATED_AT 값으로 설정 (기존 데이터)
        items = db.query(YourExistingModel).filter(
            YourExistingModel.UPDATED_AT.is_(None)
        ).all()
        
        for item in items:
            item.UPDATED_AT = item.CREATED_AT
        
        db.commit()
        print(f"Migrated {len(items)} items")
    except Exception as e:
        db.rollback()
        print(f"Migration failed: {e}")
    finally:
        db.close()

# 실행
if __name__ == "__main__":
    migrate_existing_data()
```

#### 3. nullable=False로 변경 (선택사항)

기존 데이터 마이그레이션이 완료된 후, `UPDATED_AT`을 `nullable=False`로 변경할 수 있습니다:

```python
# 마이그레이션 완료 후
UPDATED_AT = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
```

**주의**: 프로덕션 환경에서는 단계적으로 진행하세요:
1. 먼저 `nullable=True`로 컬럼 추가
2. 기존 데이터 마이그레이션 실행
3. 모든 데이터가 채워진 후 `nullable=False`로 변경

#### 4. 조회 쿼리 업데이트

표준 필드를 추가한 후, 모든 조회 쿼리에 `IS_DELETED=False` 조건을 추가하세요:

```python
# 기존 쿼리
items = db.query(YourExistingModel).all()

# 업데이트된 쿼리 (삭제되지 않은 항목만 조회)
items = db.query(YourExistingModel).filter(
    YourExistingModel.IS_DELETED == False
).all()
```

#### 5. 삭제 로직 변경

실제 삭제 대신 소프트 삭제를 사용하도록 변경하세요:

```python
# 기존 삭제 로직
db.delete(item)
db.commit()

# 업데이트된 삭제 로직 (소프트 삭제)
item.IS_DELETED = True
item.UPDATED_BY = current_user.id
db.commit()
```

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
필드는 ID, USER_ID, SESSION_ID, MESSAGE가 필요하고,
표준 필드(IS_DELETED, CREATED_AT, CREATED_BY, UPDATED_AT, UPDATED_BY)도 포함해줘."
```

## 문의

프로젝트 관련 문의사항이 있으면 팀에 문의하세요.

