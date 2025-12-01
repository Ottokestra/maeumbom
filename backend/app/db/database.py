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
    pool_recycle=3600,   # Recycle connections after 1 hour
    echo=False,          # Set to True for SQL query logging
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
        
        # TB_SCENARIO_RESULTS에 IMAGE_URL 컬럼 추가
        if 'TB_SCENARIO_RESULTS' in table_names:
            columns = [col['name'] for col in inspector.get_columns('TB_SCENARIO_RESULTS')]
            if 'IMAGE_URL' not in columns:
                with engine.begin() as conn:
                    conn.execute(text("ALTER TABLE TB_SCENARIO_RESULTS ADD COLUMN IMAGE_URL VARCHAR(500) NULL"))
                print("[DB] Added IMAGE_URL column to TB_SCENARIO_RESULTS")
        
        # TB_SCENARIOS에 START_IMAGE_URL 컬럼 추가
        if 'TB_SCENARIOS' in table_names:
            columns = [col['name'] for col in inspector.get_columns('TB_SCENARIOS')]
            if 'START_IMAGE_URL' not in columns:
                with engine.begin() as conn:
                    conn.execute(text("ALTER TABLE TB_SCENARIOS ADD COLUMN START_IMAGE_URL VARCHAR(500) NULL"))
                print("[DB] Added START_IMAGE_URL column to TB_SCENARIOS")
                
    except Exception as e:
        import traceback
        print(f"[DB] Migration failed: {e}")
        traceback.print_exc()
    
    print("[DB] All tables created successfully")

