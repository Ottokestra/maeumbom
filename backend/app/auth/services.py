"""
Business logic for authentication services
"""
import os
import logging
import httpx
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from dotenv import load_dotenv
from pathlib import Path

from .models import User
from .utils import create_access_token, create_refresh_token, verify_token
from .schemas import TokenResponse

# Setup logger
logger = logging.getLogger(__name__)

# Load environment variables
project_root = Path(__file__).parent.parent.parent
env_path = project_root / ".env"
if env_path.exists():
    load_dotenv(dotenv_path=env_path)
    logger.info(f"[Auth] Environment variables loaded from: {env_path}")
else:
    logger.warning(f"[Auth] .env file not found at: {env_path}")

# Google OAuth configuration
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"
GOOGLE_TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo"

# Log Google OAuth configuration status
if GOOGLE_CLIENT_ID:
    logger.info(f"[Auth] Google Client ID loaded: {GOOGLE_CLIENT_ID[:20]}...{GOOGLE_CLIENT_ID[-10:]}")
else:
    logger.error("[Auth] Google Client ID not found in environment variables")
if GOOGLE_CLIENT_SECRET:
    logger.info("[Auth] Google Client Secret loaded (hidden)")
else:
    logger.error("[Auth] Google Client Secret not found in environment variables")

# Kakao OAuth configuration
KAKAO_CLIENT_ID = os.getenv("KAKAO_CLIENT_ID")
KAKAO_CLIENT_SECRET = os.getenv("KAKAO_CLIENT_SECRET")
KAKAO_TOKEN_URL = "https://kauth.kakao.com/oauth/token"
KAKAO_USERINFO_URL = "https://kapi.kakao.com/v2/user/me"

# Naver OAuth configuration
NAVER_CLIENT_ID = os.getenv("NAVER_CLIENT_ID")
NAVER_CLIENT_SECRET = os.getenv("NAVER_CLIENT_SECRET")
NAVER_TOKEN_URL = "https://nid.naver.com/oauth2.0/token"
NAVER_USERINFO_URL = "https://openapi.naver.com/v1/nid/me"


async def get_google_access_token(auth_code: str, redirect_uri: str) -> str:
    """
    Exchange authorization code for Google access token
    
    Args:
        auth_code: Authorization code from Google OAuth
        redirect_uri: Redirect URI used in OAuth flow
        
    Returns:
        Google access token
        
    Raises:
        HTTPException: If token exchange fails
    """
    logger.info(f"[Auth] Starting Google access token exchange - redirect_uri: {redirect_uri}")
    logger.debug(f"[Auth] Auth code length: {len(auth_code) if auth_code else 0}")
    
    if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
        logger.error("[Auth] Google OAuth credentials not configured")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Google OAuth credentials not configured"
        )
    
    payload = {
        "code": auth_code,
        "client_id": GOOGLE_CLIENT_ID,
        "client_secret": GOOGLE_CLIENT_SECRET,
        "redirect_uri": redirect_uri,
        "grant_type": "authorization_code"
    }
    
    logger.debug(f"[Auth] Token exchange request - client_id: {GOOGLE_CLIENT_ID[:20]}...")
    
    async with httpx.AsyncClient() as client:
        try:
            logger.info("[Auth] Sending token exchange request to Google")
            response = await client.post(GOOGLE_TOKEN_URL, data=payload)
            logger.debug(f"[Auth] Google token exchange response status: {response.status_code}")
            response.raise_for_status()
            data = response.json()
            access_token = data.get("access_token")
            if access_token:
                logger.info("[Auth] Successfully obtained Google access token")
            else:
                logger.error(f"[Auth] No access_token in response: {data}")
            return access_token
        except httpx.HTTPStatusError as e:
            logger.error(f"[Auth] Google token exchange failed - Status: {e.response.status_code}, Response: {e.response.text}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to get Google access token: {e.response.text}"
            )
        except Exception as e:
            logger.exception(f"[Auth] Unexpected error during Google token exchange: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error communicating with Google: {str(e)}"
            )


async def verify_google_id_token(id_token: str) -> Dict[str, Any]:
    """
    Verify Google ID Token and extract user information
    
    Args:
        id_token: Google ID Token (JWT)
        
    Returns:
        Dictionary containing verified user info from token claims
        
    Raises:
        HTTPException: If token verification fails
    """
    logger.info("[Auth] Verifying Google ID Token")
    
    if not GOOGLE_CLIENT_ID:
        logger.error("[Auth] Google Client ID not configured")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Google OAuth credentials not configured"
        )
    
    async with httpx.AsyncClient() as client:
        try:
            logger.debug("[Auth] Sending ID Token verification request to Google")
            response = await client.get(
                GOOGLE_TOKENINFO_URL,
                params={"id_token": id_token}
            )
            logger.debug(f"[Auth] Google tokeninfo response status: {response.status_code}")
            response.raise_for_status()
            token_info = response.json()
            
            # Verify the audience (aud) matches our client ID
            aud = token_info.get("aud")
            if aud != GOOGLE_CLIENT_ID:
                logger.error(f"[Auth] ID Token audience mismatch - expected: {GOOGLE_CLIENT_ID}, got: {aud}")
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid ID Token: audience mismatch"
                )
            
            # Extract user information from token claims
            user_info = {
                "sub": token_info.get("sub"),  # Google user ID
                "email": token_info.get("email"),
                "name": token_info.get("name"),
                "picture": token_info.get("picture"),
                "email_verified": token_info.get("email_verified", False),
            }
            
            logger.info(f"[Auth] Successfully verified ID Token - email: {user_info.get('email', 'N/A')}, sub: {user_info.get('sub', 'N/A')}")
            return user_info
            
        except httpx.HTTPStatusError as e:
            logger.error(f"[Auth] ID Token verification failed - Status: {e.response.status_code}, Response: {e.response.text}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to verify Google ID Token: {e.response.text}"
            )
        except Exception as e:
            logger.exception(f"[Auth] Unexpected error during ID Token verification: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error verifying Google ID Token: {str(e)}"
            )


async def get_google_user_info(access_token: str) -> Dict[str, Any]:
    """
    Get user information from Google
    
    Args:
        access_token: Google access token
        
    Returns:
        Dictionary containing user info (sub, email, name, etc.)
        
    Raises:
        HTTPException: If user info retrieval fails
    """
    logger.info("[Auth] Fetching user info from Google")
    headers = {"Authorization": f"Bearer {access_token}"}
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(GOOGLE_USERINFO_URL, headers=headers)
            logger.debug(f"[Auth] Google userinfo response status: {response.status_code}")
            response.raise_for_status()
            user_info = response.json()
            logger.info(f"[Auth] Successfully retrieved user info - email: {user_info.get('email', 'N/A')}, sub: {user_info.get('sub', 'N/A')}")
            return user_info
        except httpx.HTTPStatusError as e:
            logger.error(f"[Auth] Failed to get Google user info - Status: {e.response.status_code}, Response: {e.response.text}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to get Google user info: {e.response.text}"
            )
        except Exception as e:
            logger.exception(f"[Auth] Unexpected error during Google userinfo retrieval: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error communicating with Google: {str(e)}"
            )


async def google_login(
    auth_code: Optional[str] = None,
    id_token: Optional[str] = None,
    redirect_uri: str = "",
    db: Session = None
) -> TokenResponse:
    """
    Handle Google OAuth login with either authorization code or ID Token
    
    Supports two authentication methods:
    1. Authorization Code Flow: Exchange auth_code for access token, then get user info
    2. ID Token Flow: Verify ID Token directly and extract user info from token claims
    
    Process:
    1. Verify ID Token OR exchange auth_code for access token
    2. Get user info from Google (from token or API)
    3. Find or create user in database
    4. Generate JWT tokens
    5. Store refresh token in database (Whitelist)
    
    Args:
        auth_code: Authorization code from Google (optional, used with serverAuthCode flow)
        id_token: ID Token from Google (optional, preferred for mobile apps)
        redirect_uri: Redirect URI for OAuth callback (required for auth_code flow)
        db: Database session
        
    Returns:
        TokenResponse with access and refresh tokens
        
    Raises:
        HTTPException: If login process fails
    """
    logger.info("[Auth] ===== Google OAuth Login Started =====")
    
    # Determine authentication method
    if id_token:
        logger.info("[Auth] Using ID Token authentication method")
        logger.debug(f"[Auth] ID Token length: {len(id_token)}")
        
        # Step 1: Verify ID Token and extract user info
        user_info = await verify_google_id_token(id_token)
        
    elif auth_code:
        logger.info("[Auth] Using Authorization Code authentication method")
        logger.info(f"[Auth] Step 1: Exchange auth_code for access token - redirect_uri: {redirect_uri}")
        
        # Step 1: Get Google access token
        google_access_token = await get_google_access_token(auth_code, redirect_uri)
        
        logger.info("[Auth] Step 2: Get user info from Google")
        # Step 2: Get user info from Google
        user_info = await get_google_user_info(google_access_token)
    else:
        logger.error("[Auth] Neither auth_code nor id_token provided")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either auth_code or id_token must be provided"
        )
    
    social_id = user_info.get("sub") or user_info.get("id")  # Google's unique user ID (sub)
    email = user_info.get("email")
    name = user_info.get("name", email.split("@")[0] if email else "User")  # Use email prefix if name not available
    
    logger.info(f"[Auth] Step 3: Process user info - social_id: {social_id}, email: {email}, name: {name}")
    
    if not social_id or not email:
        logger.error(f"[Auth] Missing required user info - social_id: {social_id}, email: {email}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to get required user information from Google"
        )
    
    # Step 3: Find or create user
    logger.info(f"[Auth] Step 4: Find or create user in database - social_id: {social_id}")
    user = db.query(User).filter(User.SOCIAL_ID == social_id, User.PROVIDER == "google").first()
    
    if not user:
        # Create new user (회원가입)
        logger.info(f"[Auth] Creating new user - email: {email}")
        user = User(
            SOCIAL_ID=social_id,
            PROVIDER="google",
            EMAIL=email,
            NICKNAME=name
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"[Auth] New user created: {user.ID} ({user.EMAIL})")
    else:
        # Update existing user info (로그인)
        logger.info(f"[Auth] Updating existing user - user_id: {user.ID}, email: {email}")
        user.EMAIL = email
        user.NICKNAME = name
        db.commit()
        db.refresh(user)
        logger.info(f"[Auth] User logged in: {user.ID} ({user.EMAIL})")
    
    # Step 4: Generate JWT tokens
    logger.info(f"[Auth] Step 5: Generate JWT tokens for user_id: {user.ID}")
    access_token = create_access_token(user.ID)
    refresh_token = create_refresh_token(user.ID)
    
    # Step 5: Store refresh token in database (Whitelist)
    logger.info(f"[Auth] Step 6: Store refresh token in database")
    user.REFRESH_TOKEN = refresh_token
    db.commit()
    
    logger.info(f"[Auth] ===== Google OAuth Login Completed Successfully =====")
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )


def refresh_access_token(refresh_token: str, db: Session) -> TokenResponse:
    """
    Refresh access token using refresh token (RTR strategy)
    
    Process:
    1. Verify refresh token
    2. Check if token is whitelisted in database
    3. Generate new access token and refresh token (RTR)
    4. Invalidate old refresh token and store new one (Whitelist)
    
    Args:
        refresh_token: Current refresh token
        db: Database session
        
    Returns:
        TokenResponse with new access and refresh tokens
        
    Raises:
        HTTPException: If refresh fails
    """
    # Step 1: Verify refresh token
    try:
        payload = verify_token(refresh_token, token_type="refresh")
        user_id = int(payload["sub"])
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid refresh token: {str(e)}"
        )
    
    # Step 2: Check if token is whitelisted
    user = db.query(User).filter(User.ID == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    if user.REFRESH_TOKEN != refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token not valid (not whitelisted or already used)"
        )
    
    # Step 3: Generate new tokens (RTR - Refresh Token Rotation)
    new_access_token = create_access_token(user.ID)
    new_refresh_token = create_refresh_token(user.ID)
    
    # Step 4: Update refresh token in database (invalidate old, store new)
    user.REFRESH_TOKEN = new_refresh_token
    db.commit()
    
    print(f"[Auth] Token refreshed for user: {user.ID}")
    
    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer"
    )


def logout(user_id: int, db: Session) -> None:
    """
    Logout user by invalidating refresh token
    
    Args:
        user_id: User ID to logout
        db: Database session
        
    Raises:
        HTTPException: If user not found
    """
    user = db.query(User).filter(User.ID == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Invalidate refresh token
    user.REFRESH_TOKEN = None
    db.commit()
    
    print(f"[Auth] User logged out: {user.ID}")


# ============================================================================
# Kakao OAuth Functions
# ============================================================================

async def get_kakao_access_token(auth_code: str, redirect_uri: str) -> str:
    """
    Exchange authorization code for Kakao access token
    
    Args:
        auth_code: Authorization code from Kakao OAuth
        redirect_uri: Redirect URI used in OAuth flow
        
    Returns:
        Kakao access token
        
    Raises:
        HTTPException: If token exchange fails
    """
    if not KAKAO_CLIENT_ID:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Kakao OAuth credentials not configured"
        )
    
    payload = {
        "grant_type": "authorization_code",
        "client_id": KAKAO_CLIENT_ID,
        "redirect_uri": redirect_uri,
        "code": auth_code
    }
    
    # Add client_secret if configured (optional for Kakao)
    if KAKAO_CLIENT_SECRET:
        payload["client_secret"] = KAKAO_CLIENT_SECRET
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(KAKAO_TOKEN_URL, data=payload)
            response.raise_for_status()
            data = response.json()
            return data["access_token"]
        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to get Kakao access token: {e.response.text}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error communicating with Kakao: {str(e)}"
            )


async def get_kakao_user_info(access_token: str) -> Dict[str, Any]:
    """
    Get user information from Kakao
    
    Args:
        access_token: Kakao access token
        
    Returns:
        Dictionary containing user info (id, kakao_account, properties, etc.)
        
    Raises:
        HTTPException: If user info retrieval fails
    """
    headers = {"Authorization": f"Bearer {access_token}"}
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(KAKAO_USERINFO_URL, headers=headers)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to get Kakao user info: {e.response.text}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error communicating with Kakao: {str(e)}"
            )


async def kakao_login(auth_code: str, redirect_uri: str, db: Session) -> TokenResponse:
    """
    Handle Kakao OAuth login
    
    Process:
    1. Check if auth_code is actually an access_token (from Kakao SDK)
    2. If not, exchange auth_code for Kakao access token
    3. Get user info from Kakao
    4. Find or create user in database
    5. Generate JWT tokens
    6. Store refresh token in database (Whitelist)
    
    Args:
        auth_code: Authorization code from Kakao (or access_token from Kakao SDK)
        redirect_uri: Redirect URI for OAuth callback
        db: Database session
        
    Returns:
        TokenResponse with access and refresh tokens
        
    Raises:
        HTTPException: If login process fails
    """
    # Step 1: Check if auth_code is actually an access_token (from Kakao SDK)
    # Kakao SDK에서 직접 access_token을 받은 경우, 토큰 교환 과정을 건너뜀
    # Access token은 일반적으로 길이가 길고 특정 형식을 가짐
    if len(auth_code) > 50:  # Access token은 보통 50자 이상, authCode는 30-40자
        kakao_access_token = auth_code
    else:
        # Authorization code인 경우 토큰 교환
        kakao_access_token = await get_kakao_access_token(auth_code, redirect_uri)
    
    # Step 2: Get user info from Kakao
    user_info = await get_kakao_user_info(kakao_access_token)
    
    social_id = str(user_info.get("id"))  # Kakao user ID
    kakao_account = user_info.get("kakao_account", {})
    properties = user_info.get("properties", {})
    
    email = kakao_account.get("email", f"kakao_{social_id}@kakao.local")
    nickname = properties.get("nickname", kakao_account.get("profile", {}).get("nickname", f"kakao_user_{social_id}"))
    
    if not social_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to get required user information from Kakao"
        )
    
    # Step 3: Find or create user
    user = db.query(User).filter(User.SOCIAL_ID == social_id, User.PROVIDER == "kakao").first()
    
    if not user:
        # Create new user (회원가입)
        user = User(
            SOCIAL_ID=social_id,
            PROVIDER="kakao",
            EMAIL=email,
            NICKNAME=nickname
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        print(f"[Auth] New Kakao user created: {user.ID} ({user.EMAIL})")
    else:
        # Update existing user info (로그인)
        user.EMAIL = email
        user.NICKNAME = nickname
        db.commit()
        db.refresh(user)
        print(f"[Auth] Kakao user logged in: {user.ID} ({user.EMAIL})")
    
    # Step 4: Generate JWT tokens
    access_token = create_access_token(user.ID)
    refresh_token = create_refresh_token(user.ID)
    
    # Step 5: Store refresh token in database (Whitelist)
    user.REFRESH_TOKEN = refresh_token
    db.commit()
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )


# ============================================================================
# Naver OAuth Functions
# ============================================================================

async def get_naver_access_token(auth_code: str, state: str) -> str:
    """
    Exchange authorization code for Naver access token
    
    Args:
        auth_code: Authorization code from Naver OAuth
        state: State value for CSRF protection
        
    Returns:
        Naver access token
        
    Raises:
        HTTPException: If token exchange fails
    """
    if not NAVER_CLIENT_ID or not NAVER_CLIENT_SECRET:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Naver OAuth credentials not configured"
        )
    
    payload = {
        "grant_type": "authorization_code",
        "client_id": NAVER_CLIENT_ID,
        "client_secret": NAVER_CLIENT_SECRET,
        "code": auth_code,
        "state": state
    }
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(NAVER_TOKEN_URL, data=payload)
            response.raise_for_status()
            data = response.json()
            return data["access_token"]
        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to get Naver access token: {e.response.text}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error communicating with Naver: {str(e)}"
            )


async def get_naver_user_info(access_token: str) -> Dict[str, Any]:
    """
    Get user information from Naver
    
    Args:
        access_token: Naver access token
        
    Returns:
        Dictionary containing user info (response.id, response.email, response.nickname, etc.)
        
    Raises:
        HTTPException: If user info retrieval fails
    """
    headers = {"Authorization": f"Bearer {access_token}"}
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(NAVER_USERINFO_URL, headers=headers)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to get Naver user info: {e.response.text}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error communicating with Naver: {str(e)}"
            )


async def naver_login(auth_code: str, state: str, db: Session) -> TokenResponse:
    """
    Handle Naver OAuth login
    
    Process:
    1. Exchange auth_code for Naver access token
    2. Get user info from Naver
    3. Find or create user in database
    4. Generate JWT tokens
    5. Store refresh token in database (Whitelist)
    
    Args:
        auth_code: Authorization code from Naver
        state: State value for CSRF protection
        db: Database session
        
    Returns:
        TokenResponse with access and refresh tokens
        
    Raises:
        HTTPException: If login process fails
    """
    # Step 1: Get Naver access token
    naver_access_token = await get_naver_access_token(auth_code, state)
    
    # Step 2: Get user info from Naver
    user_info = await get_naver_user_info(naver_access_token)
    
    response_data = user_info.get("response", {})
    social_id = response_data.get("id")
    email = response_data.get("email", f"naver_{social_id}@naver.local")
    nickname = response_data.get("nickname", response_data.get("name", f"naver_user_{social_id}"))
    
    if not social_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to get required user information from Naver"
        )
    
    # Step 3: Find or create user
    user = db.query(User).filter(User.SOCIAL_ID == social_id, User.PROVIDER == "naver").first()
    
    if not user:
        # Create new user (회원가입)
        user = User(
            SOCIAL_ID=social_id,
            PROVIDER="naver",
            EMAIL=email,
            NICKNAME=nickname
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        print(f"[Auth] New Naver user created: {user.ID} ({user.EMAIL})")
    else:
        # Update existing user info (로그인)
        user.EMAIL = email
        user.NICKNAME = nickname
        db.commit()
        db.refresh(user)
        print(f"[Auth] Naver user logged in: {user.ID} ({user.EMAIL})")
    
    # Step 4: Generate JWT tokens
    access_token = create_access_token(user.ID)
    refresh_token = create_refresh_token(user.ID)
    
    # Step 5: Store refresh token in database (Whitelist)
    user.REFRESH_TOKEN = refresh_token
    db.commit()
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )

