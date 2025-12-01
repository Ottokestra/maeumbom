"""
API endpoints for authentication (Controller layer)
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from .schemas import (
    GoogleLoginRequest,
    KakaoLoginRequest,
    NaverLoginRequest,
    TokenResponse,
    RefreshRequest,
    UserResponse,
    LogoutResponse,
    AuthConfigResponse
)
from .services import google_login, kakao_login, naver_login, refresh_access_token, logout
from .dependencies import get_current_user
from .models import User

# Create router
router = APIRouter()


@router.post(
    "/google",
    response_model=TokenResponse,
    summary="Google OAuth Login",
    description="Login with Google OAuth authorization code and get JWT tokens"
)
async def login_with_google(
    request: GoogleLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Google OAuth Login
    
    Process:
    1. Exchange authorization code for Google access token
    2. Get user info from Google
    3. Create or update user in database
    4. Generate and return JWT tokens
    
    Args:
        request: GoogleLoginRequest with auth_code and redirect_uri
        db: Database session
        
    Returns:
        TokenResponse with access_token and refresh_token
    """
    return await google_login(request.auth_code, request.redirect_uri, db)


@router.post(
    "/kakao",
    response_model=TokenResponse,
    summary="Kakao OAuth Login",
    description="Login with Kakao OAuth authorization code and get JWT tokens"
)
async def login_with_kakao(
    request: KakaoLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Kakao OAuth Login
    
    Process:
    1. Exchange authorization code for Kakao access token
    2. Get user info from Kakao
    3. Create or update user in database
    4. Generate and return JWT tokens
    
    Args:
        request: KakaoLoginRequest with auth_code and redirect_uri
        db: Database session
        
    Returns:
        TokenResponse with access_token and refresh_token
    """
    return await kakao_login(request.auth_code, request.redirect_uri, db)


@router.post(
    "/naver",
    response_model=TokenResponse,
    summary="Naver OAuth Login",
    description="Login with Naver OAuth authorization code and get JWT tokens"
)
async def login_with_naver(
    request: NaverLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Naver OAuth Login
    
    Process:
    1. Exchange authorization code for Naver access token
    2. Get user info from Naver
    3. Create or update user in database
    4. Generate and return JWT tokens
    
    Args:
        request: NaverLoginRequest with auth_code, redirect_uri, and state
        db: Database session
        
    Returns:
        TokenResponse with access_token and refresh_token
    """
    return await naver_login(request.auth_code, request.state, db)


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Refresh Access Token",
    description="Get new access token using refresh token (RTR strategy)"
)
async def refresh_token(
    request: RefreshRequest,
    db: Session = Depends(get_db)
):
    """
    Refresh Access Token
    
    Uses Refresh Token Rotation (RTR) strategy:
    - Generates new access token AND new refresh token
    - Invalidates old refresh token
    - Updates whitelist in database
    
    Args:
        request: RefreshRequest with refresh_token
        db: Database session
        
    Returns:
        TokenResponse with new access_token and refresh_token
    """
    return refresh_access_token(request.refresh_token, db)


@router.post(
    "/logout",
    response_model=LogoutResponse,
    summary="Logout",
    description="Logout user by invalidating refresh token"
)
async def logout_user(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logout User
    
    Invalidates refresh token in database (removes from whitelist)
    
    Args:
        current_user: Current authenticated user (from access token)
        db: Database session
        
    Returns:
        LogoutResponse with success message
    """
    logout(current_user.ID, db)
    return LogoutResponse(message="Logged out successfully")


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get Current User",
    description="Get current user information from access token"
)
async def get_me(
    current_user: User = Depends(get_current_user)
):
    """
    Get Current User Information
    
    Returns user information based on the access token provided in Authorization header
    
    Args:
        current_user: Current authenticated user (from access token)
        
    Returns:
        UserResponse with user information
    """
    return UserResponse(
        id=current_user.ID,
        email=current_user.EMAIL,
        nickname=current_user.NICKNAME,
        provider=current_user.PROVIDER,
        created_at=current_user.CREATED_AT
    )


@router.get(
    "/config",
    response_model=AuthConfigResponse,
    summary="Get Auth Configuration",
    description="Get public authentication configuration (Client IDs for Google, Kakao, Naver)"
)
async def get_auth_config():
    """
    Get Authentication Configuration
    
    Returns public configuration needed for frontend OAuth flow.
    Note: Only returns public information (Client IDs), never secrets.
    
    Returns:
        AuthConfigResponse with Google, Kakao, and Naver Client IDs
    """
    import os
    from dotenv import load_dotenv
    from pathlib import Path
    
    # Load environment variables
    project_root = Path(__file__).parent.parent.parent
    env_path = project_root / ".env"
    if env_path.exists():
        load_dotenv(dotenv_path=env_path)
    
    google_client_id = os.getenv("GOOGLE_CLIENT_ID")
    kakao_client_id = os.getenv("KAKAO_CLIENT_ID")
    naver_client_id = os.getenv("NAVER_CLIENT_ID")
    
    if not google_client_id or not kakao_client_id or not naver_client_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OAuth Client IDs not fully configured in backend environment variables"
        )
    
    return AuthConfigResponse(
        google_client_id=google_client_id,
        kakao_client_id=kakao_client_id,
        naver_client_id=naver_client_id
    )


@router.get(
    "/health",
    summary="Health Check",
    description="Check if authentication service is running"
)
async def health_check():
    """
    Health Check
    
    Simple endpoint to verify authentication service is running
    
    Returns:
        Status message
    """
    return {"status": "ok", "service": "authentication"}

