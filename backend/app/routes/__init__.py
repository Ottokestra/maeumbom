"""API route packages."""

from .menopause_questions import router as menopause_router
from .emotion_report import router as emotion_report_router

__all__ = ["menopause_router", "emotion_report_router"]
