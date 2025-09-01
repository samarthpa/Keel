"""
Profile routes for user profile management.

This module provides API endpoints for user profile operations
using the auth_required dependency for authentication.
"""

from typing import Dict, Any
from fastapi import APIRouter, Depends, Request
from sqlmodel import Session

from app.stores.db import get_sqlite_session
from app.stores.user_store import UserStore
from app.routes.auth import auth_required

router = APIRouter(prefix="/v1", tags=["profile"])


@router.get("/profile")
async def get_profile(
    user_id: int = Depends(auth_required),
    session: Session = Depends(get_sqlite_session)
) -> Dict[str, Any]:
    """
    Get current user profile information.
    
    This endpoint demonstrates the use of the auth_required dependency.
    It extracts the user_id from the JWT token and returns basic
    profile information.
    
    Args:
        user_id: User ID from JWT token (injected by auth_required)
        session: Database session
        
    Returns:
        Dictionary containing user profile information
        
    Example:
        GET /v1/profile
        Authorization: Bearer <jwt_token>
        
        Response:
        {
            "user_id": 1,
            "email": "user@example.com",
            "created_at": "2024-01-01T00:00:00Z"
        }
    """
    try:
        # Get user details from database
        user_store = UserStore(session)
        user = user_store.get_by_id(user_id)
        
        if not user:
            return {
                "error": {
                    "code": "USER_NOT_FOUND",
                    "message": "User not found",
                    "retryable": False
                }
            }
        
        return {
            "user_id": user.id,
            "email": user.email,
            "created_at": user.created_at.isoformat()
        }
        
    except Exception as e:
        return {
            "error": {
                "code": "PROFILE_RETRIEVAL_FAILED",
                "message": "Failed to retrieve profile information",
                "retryable": True
            }
        }


@router.get("/profile/advanced")
async def get_advanced_profile(
    request: Request,
    session: Session = Depends(get_sqlite_session)
) -> Dict[str, Any]:
    """
    Get advanced profile information using request state.
    
    This endpoint demonstrates accessing user information stored
    in request.state by the auth_required dependency.
    
    Args:
        request: FastAPI request object
        session: Database session
        
    Returns:
        Dictionary containing advanced profile information
        
    Example:
        GET /v1/profile/advanced
        Authorization: Bearer <jwt_token>
        
        Response:
        {
            "user_id": 1,
            "email": "user@example.com",
            "created_at": "2024-01-01T00:00:00Z",
            "token_info": {
                "user_id": 1,
                "user_object": "User(id=1, email='user@example.com')"
            }
        }
    """
    try:
        # Access user information from request state
        user_id = getattr(request.state, 'user_id', None)
        user = getattr(request.state, 'user', None)
        
        if not user_id or not user:
            return {
                "error": {
                    "code": "AUTHENTICATION_REQUIRED",
                    "message": "Authentication required",
                    "retryable": False
                }
            }
        
        return {
            "user_id": user.id,
            "email": user.email,
            "created_at": user.created_at.isoformat(),
            "token_info": {
                "user_id": user_id,
                "user_object": str(user)
            }
        }
        
    except Exception as e:
        return {
            "error": {
                "code": "ADVANCED_PROFILE_FAILED",
                "message": "Failed to retrieve advanced profile",
                "retryable": True
            }
        }


@router.get("/profile/simple")
async def get_simple_profile(
    user_id: int = Depends(auth_required)
) -> Dict[str, Any]:
    """
    Get simple profile information (user_id only).
    
    This endpoint demonstrates the minimal use of auth_required
    dependency, returning only the user_id from the JWT token.
    
    Args:
        user_id: User ID from JWT token (injected by auth_required)
        
    Returns:
        Dictionary containing user ID
        
    Example:
        GET /v1/profile/simple
        Authorization: Bearer <jwt_token>
        
        Response:
        {
            "user_id": 1,
            "message": "Profile access successful"
        }
    """
    return {
        "user_id": user_id,
        "message": "Profile access successful"
    }
