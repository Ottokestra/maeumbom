"""Shared dependency helpers for FastAPI routes."""
from app.db.database import get_db

__all__ = ["get_db"]
