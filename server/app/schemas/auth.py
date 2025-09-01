"""
Authentication schemas for API requests and responses.

This module defines Pydantic models for authentication-related
API requests and responses with proper validation and examples.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, validator


class RegisterRequest(BaseModel):
    """
    User registration request schema.
    
    Attributes:
        email: User's email address (validated format)
        password: Plain text password (minimum 8 characters)
        name: Optional user name (for future use)
    """
    
    email: EmailStr = Field(
        ..., 
        description="User's email address",
        example="user@example.com"
    )
    password: str = Field(
        ..., 
        min_length=8,
        description="Plain text password (minimum 8 characters)",
        example="SecurePass123!"
    )
    name: Optional[str] = Field(
        None,
        max_length=100,
        description="Optional user name (for future use)",
        example="John Doe"
    )
    
    @validator('password')
    def validate_password_strength(cls, v):
        """
        Validate password strength requirements.
        
        Args:
            v: Password value to validate
            
        Returns:
            Validated password
            
        Raises:
            ValueError: If password doesn't meet requirements
        """
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long")
        
        # Check for at least one number
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one number")
        
        # Check for at least one uppercase letter
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        
        # Check for at least one special character
        special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        if not any(c in special_chars for c in v):
            raise ValueError("Password must contain at least one special character")
        
        return v
    
    class Config:
        schema_extra = {
            "example": {
                "email": "user@example.com",
                "password": "SecurePass123!",
                "name": "John Doe"
            }
        }


class LoginRequest(BaseModel):
    """
    User login request schema.
    
    Attributes:
        email: User's email address
        password: Plain text password
    """
    
    email: EmailStr = Field(
        ..., 
        description="User's email address",
        example="user@example.com"
    )
    password: str = Field(
        ..., 
        description="Plain text password",
        example="SecurePass123!"
    )
    
    class Config:
        schema_extra = {
            "example": {
                "email": "user@example.com",
                "password": "SecurePass123!"
            }
        }


class AuthResponse(BaseModel):
    """
    Authentication response schema.
    
    Attributes:
        access_token: JWT access token
        token_type: Token type (default: "Bearer")
        expires_in: Token expiration time in seconds
        user_id: User's ID
        email: User's email address
    """
    
    access_token: str = Field(
        ..., 
        description="JWT access token",
        example="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
    )
    token_type: str = Field(
        default="Bearer",
        description="Token type",
        example="Bearer"
    )
    expires_in: int = Field(
        ..., 
        description="Token expiration time in seconds",
        example=1800
    )
    user_id: int = Field(
        ..., 
        description="User's ID",
        example=1
    )
    email: str = Field(
        ..., 
        description="User's email address",
        example="user@example.com"
    )
    
    class Config:
        schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
                "token_type": "Bearer",
                "expires_in": 1800,
                "user_id": 1,
                "email": "user@example.com"
            }
        }


class MeResponse(BaseModel):
    """
    Current user information response schema.
    
    Attributes:
        id: User's ID
        email: User's email address
        created_at: Account creation timestamp
    """
    
    id: int = Field(
        ..., 
        description="User's ID",
        example=1
    )
    email: str = Field(
        ..., 
        description="User's email address",
        example="user@example.com"
    )
    created_at: datetime = Field(
        ..., 
        description="Account creation timestamp",
        example="2024-01-01T00:00:00Z"
    )
    
    class Config:
        schema_extra = {
            "example": {
                "id": 1,
                "email": "user@example.com",
                "created_at": "2024-01-01T00:00:00Z"
            }
        }


class RefreshTokenRequest(BaseModel):
    """
    Token refresh request schema.
    
    Attributes:
        refresh_token: JWT refresh token
    """
    
    refresh_token: str = Field(
        ..., 
        description="JWT refresh token",
        example="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
    )
    
    class Config:
        schema_extra = {
            "example": {
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
            }
        }


class ChangePasswordRequest(BaseModel):
    """
    Password change request schema.
    
    Attributes:
        current_password: Current password
        new_password: New password (minimum 8 characters)
        confirm_password: New password confirmation
    """
    
    current_password: str = Field(
        ..., 
        description="Current password",
        example="OldPass123!"
    )
    new_password: str = Field(
        ..., 
        min_length=8,
        description="New password (minimum 8 characters)",
        example="NewPass456!"
    )
    confirm_password: str = Field(
        ..., 
        description="New password confirmation",
        example="NewPass456!"
    )
    
    @validator('new_password')
    def validate_new_password_strength(cls, v):
        """
        Validate new password strength requirements.
        
        Args:
            v: New password value to validate
            
        Returns:
            Validated password
            
        Raises:
            ValueError: If password doesn't meet requirements
        """
        if len(v) < 8:
            raise ValueError("New password must be at least 8 characters long")
        
        # Check for at least one number
        if not any(c.isdigit() for c in v):
            raise ValueError("New password must contain at least one number")
        
        # Check for at least one uppercase letter
        if not any(c.isupper() for c in v):
            raise ValueError("New password must contain at least one uppercase letter")
        
        # Check for at least one special character
        special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        if not any(c in special_chars for c in v):
            raise ValueError("New password must contain at least one special character")
        
        return v
    
    @validator('confirm_password')
    def validate_password_confirmation(cls, v, values):
        """
        Validate password confirmation matches.
        
        Args:
            v: Confirmation password value
            values: Other field values
            
        Returns:
            Validated confirmation password
            
        Raises:
            ValueError: If passwords don't match
        """
        if 'new_password' in values and v != values['new_password']:
            raise ValueError("Password confirmation does not match new password")
        return v
    
    class Config:
        schema_extra = {
            "example": {
                "current_password": "OldPass123!",
                "new_password": "NewPass456!",
                "confirm_password": "NewPass456!"
            }
        }


class ErrorResponse(BaseModel):
    """
    Error response schema for authentication failures.
    
    Attributes:
        error: Error details
        message: Human-readable error message
        code: Error code for client handling
    """
    
    error: str = Field(
        ..., 
        description="Error type",
        example="validation_error"
    )
    message: str = Field(
        ..., 
        description="Human-readable error message",
        example="Password must be at least 8 characters long"
    )
    code: Optional[str] = Field(
        None,
        description="Error code for client handling",
        example="PASSWORD_TOO_SHORT"
    )
    
    class Config:
        schema_extra = {
            "example": {
                "error": "validation_error",
                "message": "Password must be at least 8 characters long",
                "code": "PASSWORD_TOO_SHORT"
            }
        }

