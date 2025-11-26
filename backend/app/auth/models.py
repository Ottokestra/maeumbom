"""
SQLAlchemy models for authentication
DEPRECATED: Models have been moved to app.db.models
This file is kept for backward compatibility
"""
from app.db.models import User, DailyMoodSelection

__all__ = ["User", "DailyMoodSelection"]

