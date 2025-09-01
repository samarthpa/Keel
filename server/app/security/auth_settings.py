"""
JWT and crypto configuration settings.

This module contains settings for JWT token generation, validation,
and cryptographic operations used in authentication.

Environment Variables:
    JWT_SECRET: Secret key for JWT signing (required)
    JWT_ALGO: JWT algorithm (default: HS256)
    ACCESS_TOKEN_EXPIRES_MIN: Access token expiration in minutes (default: 43200 = 30 days)
    REFRESH_TOKEN_EXPIRES_DAYS: Refresh token expiration in days (default: 30)
    PASSWORD_MIN_LENGTH: Minimum password length (default: 8)
    BCRYPT_ROUNDS: Number of bcrypt rounds (default: 12)

Security Notes:
    - JWT_SECRET should be a strong, random string (32+ characters)
    - For production, use environment-specific secrets
    - For staging, use shorter token expiry times
    - Rotate secrets regularly and invalidate old tokens
"""

import os
from typing import Optional
from pydantic import BaseModel, Field, validator
from pydantic_settings import BaseSettings


class JWTConfig(BaseModel):
    """
    Typed configuration object for JWT operations.
    
    This object provides type-safe access to JWT configuration
    and can be used directly by jwt_tokens module.
    """
    
    secret_key: str = Field(..., description="Secret key for JWT signing")
    algorithm: str = Field(default="HS256", description="JWT signing algorithm")
    access_token_expire_minutes: int = Field(default=43200, description="Access token expiry in minutes")
    refresh_token_expire_days: int = Field(default=30, description="Refresh token expiry in days")
    
    @validator('secret_key')
    def validate_secret_key(cls, v):
        """Validate that secret key is strong enough."""
        if len(v) < 32:
            raise ValueError("JWT secret must be at least 32 characters long")
        return v
    
    @validator('algorithm')
    def validate_algorithm(cls, v):
        """Validate JWT algorithm."""
        allowed_algorithms = ['HS256', 'HS384', 'HS512', 'RS256', 'RS384', 'RS512']
        if v not in allowed_algorithms:
            raise ValueError(f"JWT algorithm must be one of: {allowed_algorithms}")
        return v
    
    @validator('access_token_expire_minutes')
    def validate_access_token_expiry(cls, v):
        """Validate access token expiry time."""
        if v < 1 or v > 525600:  # Between 1 minute and 1 year
            raise ValueError("Access token expiry must be between 1 minute and 1 year")
        return v
    
    @validator('refresh_token_expire_days')
    def validate_refresh_token_expiry(cls, v):
        """Validate refresh token expiry time."""
        if v < 1 or v > 365:  # Between 1 day and 1 year
            raise ValueError("Refresh token expiry must be between 1 day and 1 year")
        return v


class AuthSettings(BaseSettings):
    """
    Authentication settings loaded from environment variables.
    
    This class loads configuration from environment variables
    and provides validation and defaults.
    """
    
    # JWT Settings
    jwt_secret: str = Field(..., description="Secret key for JWT signing")
    jwt_algorithm: str = Field(default="HS256", description="JWT signing algorithm")
    access_token_expires_min: int = Field(default=43200, description="Access token expiry in minutes (30 days)")
    refresh_token_expires_days: int = Field(default=30, description="Refresh token expiry in days")
    
    # Password Settings
    password_min_length: int = Field(default=8, description="Minimum password length")
    password_require_special_chars: bool = Field(default=True, description="Require special characters in password")
    password_require_numbers: bool = Field(default=True, description="Require numbers in password")
    password_require_uppercase: bool = Field(default=True, description="Require uppercase letters in password")
    
    # Security Settings
    bcrypt_rounds: int = Field(default=12, description="Number of bcrypt rounds")
    max_login_attempts: int = Field(default=5, description="Maximum login attempts before lockout")
    lockout_duration_minutes: int = Field(default=15, description="Lockout duration in minutes")
    
    class Config:
        env_prefix = "AUTH_"
        env_file = ".env"
        case_sensitive = False
    
    @validator('jwt_secret')
    def validate_jwt_secret(cls, v):
        """Validate JWT secret strength."""
        if not v or len(v) < 32:
            raise ValueError("JWT_SECRET must be at least 32 characters long")
        return v
    
    @validator('access_token_expires_min')
    def validate_access_token_expiry(cls, v):
        """Validate access token expiry time."""
        if v < 1:
            raise ValueError("ACCESS_TOKEN_EXPIRES_MIN must be at least 1 minute")
        return v
    
    @validator('bcrypt_rounds')
    def validate_bcrypt_rounds(cls, v):
        """Validate bcrypt rounds."""
        if v < 10 or v > 16:
            raise ValueError("BCRYPT_ROUNDS must be between 10 and 16")
        return v
    
    def get_jwt_config(self) -> JWTConfig:
        """
        Get typed JWT configuration object.
        
        Returns:
            JWTConfig: Typed configuration object for JWT operations
            
        Example:
            >>> config = auth_settings.get_jwt_config()
            >>> token = create_access_token(data, config)
        """
        return JWTConfig(
            secret_key=self.jwt_secret,
            algorithm=self.jwt_algorithm,
            access_token_expire_minutes=self.access_token_expires_min,
            refresh_token_expire_days=self.refresh_token_expires_days
        )
    
    def get_staging_config(self) -> JWTConfig:
        """
        Get staging-specific JWT configuration with shorter expiry times.
        
        This method provides a configuration suitable for staging environments
        with shorter token expiry times for easier testing and debugging.
        
        Returns:
            JWTConfig: Staging configuration with shorter expiry times
            
        Example:
            >>> config = auth_settings.get_staging_config()
            >>> # Use shorter expiry for staging
        """
        return JWTConfig(
            secret_key=self.jwt_secret,
            algorithm=self.jwt_algorithm,
            access_token_expire_minutes=60,  # 1 hour for staging
            refresh_token_expire_days=7      # 1 week for staging
        )


# Global settings instance
auth_settings = AuthSettings()


def get_jwt_config() -> JWTConfig:
    """
    Get JWT configuration for the current environment.
    
    Returns:
        JWTConfig: Typed configuration object for JWT operations
    """
    return auth_settings.get_jwt_config()


def get_staging_jwt_config() -> JWTConfig:
    """
    Get staging JWT configuration with shorter expiry times.
    
    Returns:
        JWTConfig: Staging configuration with shorter expiry times
    """
    return auth_settings.get_staging_config()
