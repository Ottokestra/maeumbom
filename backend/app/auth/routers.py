"""
API endpoints for authentication (Controller layer)
"""
import logging
from fastapi import APIRouter, Depends, HTTPException, status, Request
from starlette.responses import RedirectResponse
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

# Setup logger
logger = logging.getLogger(__name__)

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
    logger.info("=" * 80)
    logger.info("[Auth Router] Google OAuth login request received")
    logger.info(f"[Auth Router] Redirect URI: {request.redirect_uri}")
    logger.info(f"[Auth Router] Auth code provided: {request.auth_code is not None}")
    logger.info(f"[Auth Router] ID Token provided: {request.id_token is not None}")
    if request.auth_code:
        logger.info(f"[Auth Router] Auth code length: {len(request.auth_code)}")
        logger.info(f"[Auth Router] Auth code (first 20 chars): {request.auth_code[:20]}...")
    if request.id_token:
        logger.info(f"[Auth Router] ID Token length: {len(request.id_token)}")
        logger.info(f"[Auth Router] ID Token (first 20 chars): {request.id_token[:20]}...")
    
    try:
        result = await google_login(
            auth_code=request.auth_code,
            id_token=request.id_token,
            redirect_uri=request.redirect_uri,
            db=db
        )
        logger.info("[Auth Router] Google OAuth login completed successfully")
        logger.info("=" * 80)
        return result
    except HTTPException as e:
        logger.error(f"[Auth Router] Google OAuth login failed - Status: {e.status_code}, Detail: {e.detail}")
        logger.info("=" * 80)
        raise
    except Exception as e:
        logger.exception(f"[Auth Router] Unexpected error during Google OAuth login: {str(e)}")
        logger.info("=" * 80)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error: {str(e)}"
        )


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


@router.get(
    "/callback/google",
    summary="Google OAuth Callback",
    description="Receives OAuth callback from Google and redirects to app scheme"
)
async def google_callback(request: Request):
    """Google OAuth Callback - redirects to app scheme"""
    code = request.query_params.get("code")
    state = request.query_params.get("state")
    error = request.query_params.get("error")

    app_scheme_url = "com.maeumbom.app://auth/callback"

    if error:
        return RedirectResponse(url=f"{app_scheme_url}?error={error}")
    if not code:
        return RedirectResponse(url=f"{app_scheme_url}?error=no_code")

    if state:
        return RedirectResponse(url=f"{app_scheme_url}?code={code}&state={state}&provider=google")
    else:
        return RedirectResponse(url=f"{app_scheme_url}?code={code}&provider=google")


@router.get(
    "/callback/kakao",
    summary="Kakao OAuth Callback",
    description="Receives OAuth callback from Kakao and redirects to app scheme"
)
async def kakao_callback(request: Request):
    """Kakao OAuth Callback - redirects to app scheme"""
    code = request.query_params.get("code")
    error = request.query_params.get("error")

    app_scheme_url = "com.maeumbom.app://auth/callback"

    if error:
        return RedirectResponse(url=f"{app_scheme_url}?error={error}")
    if not code:
        return RedirectResponse(url=f"{app_scheme_url}?error=no_code")

    return RedirectResponse(url=f"{app_scheme_url}?code={code}&provider=kakao")


@router.get(
    "/callback/naver",
    summary="Naver OAuth Callback",
    description="Receives OAuth callback from Naver and redirects to app scheme"
)
async def naver_callback(request: Request):
    """Naver OAuth Callback - redirects to app scheme (with state for CSRF)"""
    import logging
    from fastapi.responses import HTMLResponse
    
    logger = logging.getLogger(__name__)
    
    code = request.query_params.get("code")
    state = request.query_params.get("state")
    error = request.query_params.get("error")

    app_scheme_url = "com.maeumbom.app://auth/callback"
    
    # 로깅 추가
    logger.info(f"Naver callback received - code: {'present' if code else 'missing'}, "
                f"state: {'present' if state else 'missing'}, error: {error}")

    # 리다이렉트 URL 생성
    if error:
        redirect_url = f"{app_scheme_url}?error={error}"
        logger.warning(f"Naver OAuth error: {error}")
    elif not code or not state:
        redirect_url = f"{app_scheme_url}?error=missing_params"
        logger.error("Missing code or state in Naver callback")
    else:
        redirect_url = f"{app_scheme_url}?code={code}&state={state}&provider=naver"
        logger.info(f"Naver callback successful, redirecting to: {redirect_url}")

    # HTML 페이지로 앱 스킴 리다이렉트 (FlutterWebAuth2 호환)
    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>로그인 처리중</title>
    <style>
        body {{ font-family: sans-serif; text-align: center; padding: 50px; }}
        .spinner {{ border: 4px solid #f3f3f3; border-top: 4px solid #3498db; 
                    border-radius: 50%; width: 40px; height: 40px; 
                    animation: spin 1s linear infinite; margin: 20px auto; }}
        @keyframes spin {{ 0% {{ transform: rotate(0deg); }} 100% {{ transform: rotate(360deg); }} }}
    </style>
</head>
<body>
    <div class="spinner"></div>
    <h2>로그인 처리 중...</h2>
    <p>잠시만 기다려주세요</p>
    <script>
        // 즉시 리다이렉트 시도
        setTimeout(function() {{
            window.location.href = "{redirect_url}";
        }}, 100);
        
        // 백업: 1초 후에도 시도
        setTimeout(function() {{
            window.location.replace("{redirect_url}");
        }}, 1000);
        
        // 최종 백업: 2초 후
        setTimeout(function() {{
            window.location = "{redirect_url}";
        }}, 2000);
    </script>
    <p style="margin-top: 30px; font-size: 12px; color: #666;">
        자동으로 이동하지 않으면 <a href="{redirect_url}" style="color: #3498db;">여기를 클릭</a>하세요
    </p>
</body>
</html>"""
    
    return HTMLResponse(content=html_content)

