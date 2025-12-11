"""
Database configuration
Centralized database management for all models
"""

import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
project_root = Path(__file__).parent.parent.parent
env_path = project_root / ".env"
if env_path.exists():
    load_dotenv(dotenv_path=env_path)

# Database configuration
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "1111")
DB_NAME = os.getenv("DB_NAME", "bomdb")

# MySQL connection URL
DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}?charset=utf8mb4"

# Create SQLAlchemy engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # Verify connections before using them
    pool_recycle=3600,  # Recycle connections after 1 hour
    echo=False,  # Set to True for SQL query logging
)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class for models
Base = declarative_base()


def get_db():
    """
    Dependency function to get database session

    Usage in FastAPI:
        @app.get("/endpoint")
        def endpoint(db: Session = Depends(get_db)):
            ...
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """
    Initialize database tables
    Call this function on application startup
    """
    from . import models  # Import models to register them
    from sqlalchemy import text, inspect

    Base.metadata.create_all(bind=engine)

    # 마이그레이션: 컬럼 추가
    try:
        inspector = inspect(engine)
        table_names = inspector.get_table_names()

        # 대소문자 무시하고 테이블 이름 찾기 (Windows 등 Case-insensitive 환경 대응)
        table_map = {name.upper(): name for name in table_names}

        # TB_SCENARIO_RESULTS 마이그레이션
        if "TB_SCENARIO_RESULTS" in table_map:
            real_table_name = table_map["TB_SCENARIO_RESULTS"]
            columns = [
                col["name"].upper() for col in inspector.get_columns(real_table_name)
            ]

            # IMAGE_URL 추가
            if "IMAGE_URL" not in columns:
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN IMAGE_URL VARCHAR(500) NULL"
                        )
                    )
                print(f"[DB] Added IMAGE_URL column to {real_table_name}")

            # RELATION_HEALTH_LEVEL 추가
            if "RELATION_HEALTH_LEVEL" not in columns:
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN RELATION_HEALTH_LEVEL VARCHAR(20) NULL"
                        )
                    )
                print(f"[DB] Added RELATION_HEALTH_LEVEL column to {real_table_name}")

            # BOUNDARY_STYLE 추가
            if "BOUNDARY_STYLE" not in columns:
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN BOUNDARY_STYLE VARCHAR(500) NULL"
                        )
                    )
                print(f"[DB] Added BOUNDARY_STYLE column to {real_table_name}")

            # RELATIONSHIP_TREND 추가
            if "RELATIONSHIP_TREND" not in columns:
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN RELATIONSHIP_TREND VARCHAR(20) NULL"
                        )
                    )
                print(f"[DB] Added RELATIONSHIP_TREND column to {real_table_name}")

        # TB_SCENARIOS 마이그레이션
        if "TB_SCENARIOS" in table_map:
            real_table_name = table_map["TB_SCENARIOS"]
            columns = [
                col["name"].upper() for col in inspector.get_columns(real_table_name)
            ]

            # START_IMAGE_URL 컬럼 추가
            if "START_IMAGE_URL" not in columns:
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN START_IMAGE_URL VARCHAR(500) NULL"
                        )
                    )
                print(f"[DB] Added START_IMAGE_URL column to {real_table_name}")

            # 컬럼 목록 다시 가져오기
            columns = [
                col["name"].upper() for col in inspector.get_columns(real_table_name)
            ]

            # UPDATED_AT 컬럼 추가
            if "UPDATED_AT" not in columns:
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN UPDATED_AT DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
                        )
                    )
                print(f"[DB] Added UPDATED_AT column to {real_table_name}")

            # 컬럼 목록 다시 가져오기
            columns = [
                col["name"].upper() for col in inspector.get_columns(real_table_name)
            ]

            # USER_ID 컬럼 추가 (개인화 시나리오 지원)
            if "USER_ID" not in columns:
                with engine.begin() as conn:
                    # 컬럼 추가
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN USER_ID INT NULL"
                        )
                    )

                    # 인덱스 추가
                    try:
                        conn.execute(
                            text(
                                f"ALTER TABLE {real_table_name} ADD INDEX idx_user_id (USER_ID)"
                            )
                        )
                    except Exception:
                        pass

                    # 외래키 제약조건 추가
                    try:
                        conn.execute(
                            text(
                                f"ALTER TABLE {real_table_name} ADD CONSTRAINT fk_scenarios_user_id FOREIGN KEY (USER_ID) REFERENCES TB_USERS(ID) ON DELETE CASCADE"
                            )
                        )
                    except Exception:
                        pass

                print(f"[DB] Added USER_ID column to {real_table_name}")
            else:
                print(f"[DB] USER_ID column already exists in {real_table_name}")

        # TB_MENOPAUSE_SURVEY_ANSWER 마이그레이션 (RESULT_ID, QUESTION_ID 등 컬럼 확인)
        if "TB_MENOPAUSE_SURVEY_ANSWER" in table_map:
            real_table_name = table_map["TB_MENOPAUSE_SURVEY_ANSWER"]
            columns = [
                col["name"].upper() for col in inspector.get_columns(real_table_name)
            ]

            with engine.begin() as conn:
                if "RESULT_ID" not in columns:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN RESULT_ID INT NOT NULL"
                        )
                    )
                    try:
                        conn.execute(
                            text(
                                f"create index ix_tb_menopause_survey_answer_result_id on {real_table_name} (result_id)"
                            )
                        )
                    except Exception:
                        pass
                    print(f"[DB] Added RESULT_ID column to {real_table_name}")

                if "QUESTION_ID" not in columns:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN QUESTION_ID INT NOT NULL"
                        )
                    )
                    try:
                        conn.execute(
                            text(
                                f"create index ix_tb_menopause_survey_answer_question_id on {real_table_name} (question_id)"
                            )
                        )
                    except Exception:
                        pass
                    print(f"[DB] Added QUESTION_ID column to {real_table_name}")

                if "SURVEY_ID" in columns:
                    # Legacy column: Make it nullable to avoid insert errors
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} MODIFY COLUMN SURVEY_ID INT NULL"
                        )
                    )
                    print(
                        f"[DB] Modified SURVEY_ID to be nullable in {real_table_name}"
                    )

                if "QUESTION_CODE" in columns:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} MODIFY COLUMN QUESTION_CODE VARCHAR(50) NULL"
                        )
                    )
                    print(
                        f"[DB] Modified QUESTION_CODE to be nullable in {real_table_name}"
                    )

                if "QUESTION_TEXT" in columns:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} MODIFY COLUMN QUESTION_TEXT TEXT NULL"
                        )
                    )
                    print(
                        f"[DB] Modified QUESTION_TEXT to be nullable in {real_table_name}"
                    )

                if "ANSWER_LABEL" in columns:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} MODIFY COLUMN ANSWER_LABEL VARCHAR(50) NULL"
                        )
                    )
                    print(
                        f"[DB] Modified ANSWER_LABEL to be nullable in {real_table_name}"
                    )

                if "ANSWER_VALUE" not in columns:
                    # 기존 ANSWER_VALUE가 있을 수 있는데 타입이 다를 수 있음 (Integer vs Varchar)
                    # 여기서는 없으면 추가하는 로직만
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN ANSWER_VALUE INT NOT NULL DEFAULT 0"
                        )
                    )
                    print(f"[DB] Added ANSWER_VALUE column to {real_table_name}")

                if "IS_DELETED" not in columns:
                    conn.execute(
                        text(
                            f"ALTER TABLE {real_table_name} ADD COLUMN IS_DELETED TINYINT NOT NULL DEFAULT 0"
                        )
                    )
                    print(f"[DB] Added IS_DELETED column to {real_table_name}")

    except Exception as e:
        import traceback

        print(f"[DB] Migration failed: {e}")
        traceback.print_exc()

    print("[DB] All tables created successfully")
