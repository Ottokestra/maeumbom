"""
Pydantic schemas for request/response validation (DTO)
"""
from pydantic import BaseModel, Field, EmailStr, model_validator
from typing import Optional
from datetime import datetime


class GoogleLoginRequest(BaseModel):
    """
    Request schema for Google OAuth login
    
    Attributes:
        auth_code: Authorization code from Google OAuth (optional, used with serverAuthCode flow)
        id_token: ID Token from Google OAuth (optional, preferred method for mobile apps)
        redirect_uri: Redirect URI used in OAuth flow (dynamic for web/app support)
    """
    auth_code: Optional[str] = Field(None, description="Authorization code from Google OAuth")
    id_token: Optional[str] = Field(None, description="ID Token from Google OAuth")
    redirect_uri: str = Field(..., description="Redirect URI for OAuth callback")
    
    class Config:
        json_schema_extra = {
            "example": {
                "auth_code": "4/0AY0e-g7xxxxxxxxxxxxxxxxxxx",
                "id_token": "eyJhbGciOiJSUzI1NiIs...",
                "redirect_uri": "http://localhost:5173/auth/callback"
            }
        }
        
    @model_validator(mode='after')
    def validate_auth_method(self):
        """Ensure at least one authentication method is provided"""
        if not self.auth_code and not self.id_token:
            raise ValueError("Either auth_code or id_token must be provided")
        return self


class KakaoLoginRequest(BaseModel):
    """
    Request schema for Kakao OAuth login
    
    Attributes:
        auth_code: Authorization code from Kakao OAuth
        redirect_uri: Redirect URI used in OAuth flow
    """
    auth_code: str = Field(..., description="Authorization code from Kakao OAuth")
    redirect_uri: str = Field(..., description="Redirect URI for OAuth callback")
    
    class Config:
        json_schema_extra = {
            "example": {
                "auth_code": "xxxxxxxxxxxxxxxxxxxxxxxxxxx",
                "redirect_uri": "http://localhost:5173/auth/callback"
            }
        }


class NaverLoginRequest(BaseModel):
    """
    Request schema for Naver OAuth login
    
    Attributes:
        auth_code: Authorization code from Naver OAuth
        redirect_uri: Redirect URI used in OAuth flow
        state: State value for CSRF protection
    """
    auth_code: str = Field(..., description="Authorization code from Naver OAuth")
    redirect_uri: str = Field(..., description="Redirect URI for OAuth callback")
    state: str = Field(..., description="State value for CSRF protection")
    
    class Config:
        json_schema_extra = {
            "example": {
                "auth_code": "xxxxxxxxxxxxxxxxxxxxxxxxxxx",
                "redirect_uri": "http://localhost:5173/auth/callback",
                "state": "random_state_string"
            }
        }


class TokenResponse(BaseModel):
    """
    Response schema for token operations
    
    Attributes:
        access_token: JWT access token
        refresh_token: JWT refresh token
        token_type: Token type (always "bearer")
    """
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field(default="bearer", description="Token type")
    
    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer"
            }
        }


class RefreshRequest(BaseModel):
    """
    Request schema for token refresh
    
    Attributes:
        refresh_token: Current refresh token
    """
    refresh_token: str = Field(..., description="Current refresh token")
    
    class Config:
        json_schema_extra = {
            "example": {
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
            }
        }


class UserResponse(BaseModel):
    """
    Response schema for user information
    
    Attributes:
        id: User ID
        email: User email
        nickname: User display name
        provider: OAuth provider name
        created_at: Account creation timestamp
    """
    id: int = Field(..., description="User ID")
    email: str = Field(..., description="User email")
    nickname: str = Field(..., description="User display name")
    provider: str = Field(..., description="OAuth provider")
    created_at: datetime = Field(..., description="Account creation timestamp")
    
    class Config:
        from_attributes = True  # Enable ORM mode for SQLAlchemy models
        json_schema_extra = {
            "example": {
                "id": 1,
                "email": "user@example.com",
                "nickname": "홍길동",
                "provider": "google",
                "created_at": "2024-01-01T00:00:00"
            }
        }


class LogoutResponse(BaseModel):
    """
    Response schema for logout
    
    Attributes:
        message: Success message
    """
    message: str = Field(default="Logged out successfully")
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": "Logged out successfully"
            }
        }


class AuthConfigResponse(BaseModel):
    """
    Response schema for authentication configuration
    
    Attributes:
        google_client_id: Google OAuth Client ID (public, safe to expose)
        kakao_client_id: Kakao OAuth REST API Key (public, safe to expose)
        naver_client_id: Naver OAuth Client ID (public, safe to expose)
    """
    google_client_id: str = Field(..., description="Google OAuth Client ID")
    kakao_client_id: str = Field(..., description="Kakao OAuth REST API Key")
    naver_client_id: str = Field(..., description="Naver OAuth Client ID")
    
    class Config:
        json_schema_extra = {
            "example": {
                "google_client_id": "123456789-abcdefghijklmnop.apps.googleusercontent.com",
                "kakao_client_id": "abcdef1234567890abcdef12",
                "naver_client_id": "AbCdEfGhIjKlMnOp"
            }
        }

