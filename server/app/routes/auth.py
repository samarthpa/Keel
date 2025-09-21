"""
Authentication routes for user registration, login, and profile management.

This module provides API endpoints for user authentication including
registration, login, profile retrieval, and token refresh.

Rate Limiting:
    These endpoints should be protected by rate limiting to prevent
    abuse. Consider implementing rate limiting via API gateway or
    middleware with the following limits:
    - /auth/register: 5 requests per hour per IP
    - /auth/login: 10 requests per minute per IP
    - /auth/me: 100 requests per minute per user
    - /auth/refresh: 20 requests per minute per user
"""

from datetime import timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlmodel import Session

from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    AuthResponse,
    MeResponse,
    RefreshTokenRequest,
    ChangePasswordRequest
)
from app.models.user import User
from app.stores.user_store import UserStore
from app.stores.db import get_sqlite_session
from app.security.jwt_tokens import (
    create_access_token, 
    create_refresh_token, 
    verify_access_token, 
    verify_refresh_token,
    extract_user_id_from_token, 
    create_tokens_for_user,
    JWTTokenError,
    JWTTokenExpiredError,
    JWTTokenInvalidError,
    JWTTokenDecodeError
)
from app.security.passwords import validate_password_strength, hash_password, verify_password
from app.security.auth_settings import auth_settings, get_jwt_config
from app.utils.errors import error_response

# Security scheme for JWT tokens
security = HTTPBearer()

router = APIRouter(prefix="/auth", tags=["authentication"])


def auth_required(request: Request, session: Session = Depends(get_sqlite_session)) -> int:
    """
    FastAPI dependency that requires authentication.
    
    Extracts Bearer token from Authorization header, verifies JWT,
    and injects user_id into request state. Returns 401 error if
    authentication fails.
    
    Args:
        request: FastAPI request object
        session: Database session
        
    Returns:
        int: User ID from JWT token
        
    Raises:
        HTTPException: If authentication fails (401 Unauthorized)
        
    Example:
        @router.get("/protected")
        async def protected_route(user_id: int = Depends(auth_required)):
            return {"user_id": user_id}
    """
    # Get Authorization header
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header required",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Extract Bearer token
    if not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    token = auth_header[7:]  # Remove "Bearer " prefix
    
    try:
        # Verify the access token
        payload = verify_access_token(token)
        user_id = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Verify user exists in database
        user_store = UserStore(session)
        user = user_store.get_by_id(int(user_id))
        
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Store user_id in request state for potential use by other dependencies
        request.state.user_id = int(user_id)
        request.state.user = user
        
        return int(user_id)
        
    except JWTTokenExpiredError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except (JWTTokenInvalidError, JWTTokenDecodeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except JWTTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token error: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    session: Session = Depends(get_sqlite_session)
) -> User:
    """
    Get current authenticated user from JWT token.
    
    Args:
        credentials: HTTP Bearer token credentials
        session: Database session
        
    Returns:
        Current user object
        
    Raises:
        HTTPException: If token is invalid or user not found
    """
    token = credentials.credentials
    
    try:
        # Verify the access token
        payload = verify_access_token(token)
        user_id = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        user_store = UserStore(session)
        user = user_store.get_by_id(int(user_id))
        
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return user
        
    except JWTTokenExpiredError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except (JWTTokenInvalidError, JWTTokenDecodeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except JWTTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token error: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


@router.post("/register", response_model=AuthResponse)
async def register(
    request: RegisterRequest,
    session: Session = Depends(get_sqlite_session)
):
    """
    Register a new user account.
    
    Validates input, checks email uniqueness, hashes password,
    creates user, and returns JWT access token.
    
    Args:
        request: Registration request data
        session: Database session
        
    Returns:
        Authentication response with access token
        
    Raises:
        HTTPException: If validation fails or user already exists
        
    Rate Limiting:
        Recommended: 5 requests per hour per IP address
    """
    user_store = UserStore(session)
    
    # Check if user already exists
    if user_store.user_exists(request.email):
        return error_response(
            code="EMAIL_ALREADY_EXISTS",
            message="User with this email already exists",
            http_status=400,
            retryable=False
        )
    
    try:
        # Create user with hashed password
        hashed_password = hash_password(request.password)
        user = user_store.create_user(request.email, hashed_password)
        
        # Generate access token with user ID as subject
        jwt_config = get_jwt_config()
        access_token = create_access_token(sub=str(user.id), config=jwt_config)
        
        return AuthResponse(
            access_token=access_token,
            token_type="Bearer",
            expires_in=jwt_config.access_token_expire_minutes * 60,
            user_id=user.id,
            email=user.email
        )
    except ValueError as e:
        return error_response(
            code="VALIDATION_ERROR",
            message=str(e),
            http_status=400,
            retryable=False
        )
    except Exception as e:
        return error_response(
            code="REGISTRATION_FAILED",
            message="Failed to create user account",
            http_status=500,
            retryable=True
        )


@router.post("/login", response_model=AuthResponse)
async def login(
    request: LoginRequest,
    session: Session = Depends(get_sqlite_session)
):
    """
    Authenticate user and return access token.
    
    Verifies credentials and returns JWT access token
    if authentication is successful.
    
    Args:
        request: Login request data
        session: Database session
        
    Returns:
        Authentication response with access token
        
    Raises:
        HTTPException: If authentication fails
        
    Rate Limiting:
        Recommended: 10 requests per minute per IP address
    """
    user_store = UserStore(session)
    user = user_store.authenticate_user(request.email, request.password)
    
    if not user:
        return error_response(
            code="INVALID_CREDENTIALS",
            message="Incorrect email or password",
            http_status=401,
            retryable=False
        )
    
    try:
        # Generate access token with user ID as subject
        jwt_config = get_jwt_config()
        access_token = create_access_token(sub=str(user.id), config=jwt_config)
        
        return AuthResponse(
            access_token=access_token,
            token_type="Bearer",
            expires_in=jwt_config.access_token_expire_minutes * 60,
            user_id=user.id,
            email=user.email
        )
    except Exception as e:
        return error_response(
            code="LOGIN_FAILED",
            message="Failed to generate access token",
            http_status=500,
            retryable=True
        )


@router.get("/me", response_model=MeResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    """
    Get current user information.
    
    Requires Authorization: Bearer <token> header.
    Verifies JWT token and fetches user information.
    
    Args:
        current_user: Current authenticated user (from JWT token)
        
    Returns:
        Current user information
        
    Rate Limiting:
        Recommended: 100 requests per minute per user
    """
    try:
        return MeResponse(
            id=current_user.id,
            email=current_user.email,
            created_at=current_user.created_at
        )
    except Exception as e:
        return error_response(
            code="USER_INFO_FAILED",
            message="Failed to retrieve user information",
            http_status=500,
            retryable=True
        )


@router.post("/refresh", response_model=AuthResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    session: Session = Depends(get_sqlite_session)
):
    """
    Refresh access token using refresh token.
    
    Verifies refresh token and returns new access token
    if refresh token is valid.
    
    Args:
        request: Refresh token request data
        session: Database session
        
    Returns:
        New authentication response with access token
        
    Raises:
        HTTPException: If refresh token is invalid
        
    Rate Limiting:
        Recommended: 20 requests per minute per user
    """
    try:
        # Verify the refresh token
        payload = verify_refresh_token(request.refresh_token)
        user_id = payload.get("sub")
        
        if user_id is None:
            return error_response(
                code="INVALID_TOKEN_PAYLOAD",
                message="Invalid token payload",
                http_status=401,
                retryable=False
            )
        
        user_store = UserStore(session)
        user = user_store.get_by_id(int(user_id))
        
        if user is None:
            return error_response(
                code="USER_NOT_FOUND",
                message="User not found",
                http_status=401,
                retryable=False
            )
        
        # Generate new access token
        jwt_config = get_jwt_config()
        access_token = create_access_token(sub=str(user.id), config=jwt_config)
        
        return AuthResponse(
            access_token=access_token,
            token_type="Bearer",
            expires_in=jwt_config.access_token_expire_minutes * 60,
            user_id=user.id,
            email=user.email
        )
        
    except JWTTokenExpiredError:
        return error_response(
            code="TOKEN_EXPIRED",
            message="Refresh token has expired",
            http_status=401,
            retryable=False
        )
    except (JWTTokenInvalidError, JWTTokenDecodeError):
        return error_response(
            code="INVALID_REFRESH_TOKEN",
            message="Invalid refresh token",
            http_status=401,
            retryable=False
        )
    except JWTTokenError as e:
        return error_response(
            code="TOKEN_ERROR",
            message=f"Token error: {str(e)}",
            http_status=401,
            retryable=False
        )
    except Exception as e:
        return error_response(
            code="REFRESH_FAILED",
            message="Failed to refresh token",
            http_status=500,
            retryable=True
        )


@router.post("/change-password")
async def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_sqlite_session)
):
    """
    Change user password.
    
    Requires Authorization: Bearer <token> header.
    Validates current password and updates to new password.
    
    Args:
        request: Password change request data
        current_user: Current authenticated user
        session: Database session
        
    Returns:
        Success message
        
    Raises:
        HTTPException: If validation fails
        
    Rate Limiting:
        Recommended: 5 requests per hour per user
    """
    try:
        # Validate current password
        if not verify_password(request.current_password, current_user.hashed_password):
            return error_response(
                code="INVALID_CURRENT_PASSWORD",
                message="Current password is incorrect",
                http_status=400,
                retryable=False
            )
        
        # Update password
        hashed_password = hash_password(request.new_password)
        current_user.hashed_password = hashed_password
        session.add(current_user)
        session.commit()
        
        return {"message": "Password changed successfully"}
        
    except Exception as e:
        return error_response(
            code="PASSWORD_CHANGE_FAILED",
            message="Failed to change password",
            http_status=500,
            retryable=True
        )

