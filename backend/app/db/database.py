"""Database configuration and session helpers."""

from pathlib import Path
import os
from typing import Optional

from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker


def _load_env() -> None:
    """Load environment variables from the project root ``.env`` file if present."""

    project_root = Path(__file__).parent.parent.parent
    env_path = project_root / ".env"
    if env_path.exists():
        load_dotenv(dotenv_path=env_path)


_load_env()


def get_database_url() -> str:
    """Return the database URL derived from environment variables.

    Preference is given to ``DATABASE_URL``. If absent, build the MySQL connection
    string from ``DB_HOST``, ``DB_PORT``, ``DB_USER``, ``DB_PASSWORD``, and
    ``DB_NAME``.
    """

    explicit_url: Optional[str] = os.getenv("DATABASE_URL")
    if explicit_url:
        return explicit_url

    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "3306")
    db_user = os.getenv("DB_USER", "root")
    db_password = os.getenv("DB_PASSWORD", "")
    db_name = os.getenv("DB_NAME", "")

    return (
        f"mysql+pymysql://{db_user}:{db_password}"
        f"@{db_host}:{db_port}/{db_name}?charset=utf8mb4"
    )


DATABASE_URL = get_database_url()

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """FastAPI dependency to provide a DB session."""

    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Initialize database tables and run lightweight migrations."""

    from . import models  # noqa: F401 - register models

    Base.metadata.create_all(bind=engine)

    # 마이그레이션: 컬럼 추가
    try:
        inspector = inspect(engine)
        table_names = inspector.get_table_names()

        # TB_SCENARIO_RESULTS에 IMAGE_URL 컬럼 추가
        if "TB_SCENARIO_RESULTS" in table_names:
            columns = [col["name"] for col in inspector.get_columns("TB_SCENARIO_RESULTS")]
            if "IMAGE_URL" not in columns:
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            "ALTER TABLE TB_SCENARIO_RESULTS ADD COLUMN IMAGE_URL VARCHAR(500) NULL"
                        )
                    )
                print("[DB] Added IMAGE_URL column to TB_SCENARIO_RESULTS")

        # TB_SCENARIOS에 START_IMAGE_URL 컬럼 추가
        if "TB_SCENARIOS" in table_names:
            columns = [col["name"] for col in inspector.get_columns("TB_SCENARIOS")]
            if "START_IMAGE_URL" not in columns:
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            "ALTER TABLE TB_SCENARIOS ADD COLUMN START_IMAGE_URL VARCHAR(500) NULL"
                        )
                    )
                print("[DB] Added START_IMAGE_URL column to TB_SCENARIOS")

            columns = [col["name"] for col in inspector.get_columns("TB_SCENARIOS")]

            if "UPDATED_AT" not in columns:
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            "ALTER TABLE TB_SCENARIOS ADD COLUMN UPDATED_AT DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
                        )
                    )
                print("[DB] Added UPDATED_AT column to TB_SCENARIOS")

            columns = [col["name"] for col in inspector.get_columns("TB_SCENARIOS")]

            if "USER_ID" not in columns:
                with engine.begin() as conn:
                    conn.execute(text("ALTER TABLE TB_SCENARIOS ADD COLUMN USER_ID INT NULL"))

                    try:
                        conn.execute(text("ALTER TABLE TB_SCENARIOS ADD INDEX idx_user_id (USER_ID)"))
                    except Exception:
                        pass

                    try:
                        conn.execute(
                            text(
                                "ALTER TABLE TB_SCENARIOS ADD CONSTRAINT fk_scenarios_user_id FOREIGN KEY (USER_ID) REFERENCES TB_USERS(ID) ON DELETE CASCADE"
                            )
                        )
                    except Exception:
                        pass

                print("[DB] Added USER_ID column to TB_SCENARIOS")
            else:
                print("[DB] USER_ID column already exists in TB_SCENARIOS")

    except Exception as e:  # pragma: no cover - defensive logging
        import traceback

        print(f"[DB] Migration failed: {e}")
        traceback.print_exc()

    print("[DB] All tables created successfully")
