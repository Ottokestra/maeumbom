"""
Database configuration for authentication
DEPRECATED: Database configuration has been moved to app.db.database
This file is kept for backward compatibility
"""
from app.db.database import Base, get_db, init_db, engine, SessionLocal

__all__ = ["Base", "get_db", "init_db", "engine", "SessionLocal"]
