<<<<<<< HEAD
"""Menopause survey package."""

from .router import router

__all__ = ["router"]
=======
# backend/app/menopause_survey/__init__.py
"""
갱년기 라이트 설문 도메인.

- router: FastAPI 라우터
- models: SQLAlchemy 모델
- schemas: Pydantic 스키마
- services: 비즈니스 로직
"""

from . import models  # 테이블이 Base 메타데이터에 등록되도록 import 유지
>>>>>>> dev
