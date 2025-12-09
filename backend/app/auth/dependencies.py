"""
Security dependencies for token verification
"""
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import jwt

from app.config import settings
from app.db.database import get_db
from app.db.models import User
from .utils import verify_token

# HTTP Bearer token scheme
security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """
    Dependency to get current authenticated user from access token
    
    Usage in routes:
        @router.get("/protected")
        async def protected_route(current_user: User = Depends(get_current_user)):
            return {"user_id": current_user.id}
    
    Args:
        credentials: HTTP Authorization credentials (Bearer token)
        db: Database session
        
    Returns:
        User object if token is valid
        
    Raises:
        HTTPException 401: If token is invalid or user not found
    """
    if settings.DEBUG and settings.DISABLE_AUTH_FOR_DEV:
        dev_user = db.query(User).filter(User.ID == settings.DEV_AUTH_USER_ID).first()
        if dev_user:
            return dev_user

        return User(
            ID=settings.DEV_AUTH_USER_ID,
            SOCIAL_ID="dev-user",
            PROVIDER="dev",
            EMAIL="dev@example.com",
            NICKNAME="개발자",
        )

    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"detail": "인증이 필요합니다. 다시 로그인해주세요.", "code": "AUTH_REQUIRED"},
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials

    # Verify token
    try:
        payload = verify_token(token, token_type="access")
        user_id = int(payload["sub"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"detail": "인증이 필요합니다. 다시 로그인해주세요.", "code": "AUTH_REQUIRED"},
            headers={"WWW-Authenticate": "Bearer"}
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"detail": "인증이 필요합니다. 다시 로그인해주세요.", "code": "AUTH_REQUIRED"},
            headers={"WWW-Authenticate": "Bearer"}
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"detail": f"인증이 필요합니다. 다시 로그인해주세요.", "code": "AUTH_REQUIRED", "reason": str(e)},
            headers={"WWW-Authenticate": "Bearer"}
        )

    # Get user from database
    user = db.query(User).filter(User.ID == user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"detail": "인증이 필요합니다. 다시 로그인해주세요.", "code": "AUTH_REQUIRED"},
            headers={"WWW-Authenticate": "Bearer"}
        )

    return user


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False)),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """
    Dependency to get current user if token is provided (optional authentication)
    
    Usage in routes:
        @router.get("/optional-protected")
        async def optional_route(current_user: Optional[User] = Depends(get_optional_user)):
            if current_user:
                return {"user_id": current_user.id}
            return {"message": "Anonymous user"}
    
    Args:
        credentials: HTTP Authorization credentials (Bearer token) - optional
        db: Database session
        
    Returns:
        User object if token is valid, None otherwise
    """
    if not credentials:
        return None
    
    try:
        return await get_current_user(credentials, db)
    except HTTPException:
        return None

