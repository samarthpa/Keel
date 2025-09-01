"""
JWT token creation and verification utilities.

This module provides functions for creating and validating JWT tokens
for user authentication and session management. It includes standard
JWT claims and custom exception handling for better error messages.

Standard Claims:
    - sub: Subject (user ID)
    - iat: Issued at (timestamp)
    - exp: Expiration (timestamp)
    - type: Token type (access/refresh)

Custom Exceptions:
    - JWTTokenError: Base exception for JWT errors
    - JWTTokenExpiredError: Token has expired
    - JWTTokenInvalidError: Token is invalid or malformed
    - JWTTokenDecodeError: Token cannot be decoded
"""

from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from app.security.auth_settings import get_jwt_config, JWTConfig


class JWTTokenError(Exception):
    """Base exception for JWT token errors."""
    pass


class JWTTokenExpiredError(JWTTokenError):
    """Exception raised when a JWT token has expired."""
    pass


class JWTTokenInvalidError(JWTTokenError):
    """Exception raised when a JWT token is invalid or malformed."""
    pass


class JWTTokenDecodeError(JWTTokenError):
    """Exception raised when a JWT token cannot be decoded."""
    pass


def create_access_token(
    sub: str, 
    ttl_minutes: Optional[int] = None,
    config: Optional[JWTConfig] = None
) -> str:
    """
    Create a JWT access token with standard claims.
    
    This function creates a JWT access token with the standard claims:
    - sub: Subject (user ID)
    - iat: Issued at timestamp
    - exp: Expiration timestamp
    - type: Token type (access)
    
    Args:
        sub: Subject identifier (usually user ID)
        ttl_minutes: Time to live in minutes (uses config default if None)
        config: JWT configuration object (uses default if not provided)
        
    Returns:
        JWT access token string
        
    Raises:
        JWTTokenError: If token creation fails
        
    Example:
        >>> token = create_access_token("user123", 30)
        >>> # Returns: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        
    Security Notes:
        - Token includes standard JWT claims
        - Expiration is set relative to current time
        - Token type helps distinguish from refresh tokens
        - Subject should be user ID or unique identifier
    """
    if config is None:
        config = get_jwt_config()
    
    # Use provided TTL or config default
    if ttl_minutes is None:
        ttl_minutes = config.access_token_expire_minutes
    
    # Calculate timestamps
    now = datetime.utcnow()
    expires = now + timedelta(minutes=ttl_minutes)
    
    # Create payload with standard claims
    payload = {
        "sub": sub,                    # Subject (user ID)
        "iat": now,                    # Issued at
        "exp": expires,                # Expiration
        "type": "access",              # Token type
        "iss": "keel-api",             # Issuer
        "aud": "keel-client"           # Audience
    }
    
    try:
        # Encode the token
        encoded_jwt = jwt.encode(
            payload, 
            config.secret_key, 
            algorithm=config.algorithm
        )
        return encoded_jwt
    except Exception as e:
        raise JWTTokenError(f"Failed to create access token: {str(e)}")


def verify_access_token(token: str, config: Optional[JWTConfig] = None) -> Dict[str, Any]:
    """
    Verify and decode a JWT access token.
    
    This function verifies the JWT token signature, checks expiration,
    and validates the token type. It returns the decoded payload
    if the token is valid.
    
    Args:
        token: JWT token to verify
        config: JWT configuration object (uses default if not provided)
        
    Returns:
        Decoded token payload
        
    Raises:
        JWTTokenExpiredError: If token has expired
        JWTTokenInvalidError: If token is invalid or malformed
        JWTTokenDecodeError: If token cannot be decoded
        JWTTokenError: For other JWT-related errors
        
    Example:
        >>> payload = verify_access_token(token)
        >>> # Returns: {"sub": "user123", "iat": ..., "exp": ..., "type": "access"}
        
    Security Notes:
        - Verifies token signature using secret key
        - Checks token expiration automatically
        - Validates token type to prevent misuse
        - Returns payload only if all checks pass
    """
    if config is None:
        config = get_jwt_config()
    
    try:
        # Decode and verify the token
        payload = jwt.decode(
            token, 
            config.secret_key, 
            algorithms=[config.algorithm]
        )
        
        # Validate token type
        token_type = payload.get("type")
        if token_type != "access":
            raise JWTTokenInvalidError(f"Invalid token type: {token_type}. Expected 'access'")
        
        # Check if token has expired (jwt.decode handles this automatically, but we check explicitly)
        exp = payload.get("exp")
        if exp and datetime.utcnow() > datetime.fromtimestamp(exp):
            raise JWTTokenExpiredError("Token has expired")
        
        return payload
        
    except JWTError as e:
        # Re-raise our custom exceptions
        if "expired" in str(e).lower():
            raise JWTTokenExpiredError("Token has expired")
        elif "invalid" in str(e).lower():
            raise JWTTokenInvalidError("Token is invalid or malformed")
        else:
            raise JWTTokenDecodeError(f"Failed to decode token: {str(e)}")
    except Exception as e:
        raise JWTTokenError(f"Unexpected error verifying token: {str(e)}")


def create_refresh_token(
    sub: str, 
    config: Optional[JWTConfig] = None
) -> str:
    """
    Create a JWT refresh token with standard claims.
    
    This function creates a JWT refresh token with longer expiration
    than access tokens. Refresh tokens are used to obtain new access
    tokens without requiring user re-authentication.
    
    Args:
        sub: Subject identifier (usually user ID)
        config: JWT configuration object (uses default if not provided)
        
    Returns:
        JWT refresh token string
        
    Raises:
        JWTTokenError: If token creation fails
        
    Example:
        >>> refresh_token = create_refresh_token("user123")
        >>> # Returns: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        
    Security Notes:
        - Longer expiration than access tokens
        - Token type is "refresh" to distinguish from access tokens
        - Should be stored securely (httpOnly cookie recommended)
        - Used only to obtain new access tokens
    """
    if config is None:
        config = get_jwt_config()
    
    # Calculate timestamps
    now = datetime.utcnow()
    expires = now + timedelta(days=config.refresh_token_expire_days)
    
    # Create payload with standard claims
    payload = {
        "sub": sub,                    # Subject (user ID)
        "iat": now,                    # Issued at
        "exp": expires,                # Expiration
        "type": "refresh",             # Token type
        "iss": "keel-api",             # Issuer
        "aud": "keel-client"           # Audience
    }
    
    try:
        # Encode the token
        encoded_jwt = jwt.encode(
            payload, 
            config.secret_key, 
            algorithm=config.algorithm
        )
        return encoded_jwt
    except Exception as e:
        raise JWTTokenError(f"Failed to create refresh token: {str(e)}")


def verify_refresh_token(token: str, config: Optional[JWTConfig] = None) -> Dict[str, Any]:
    """
    Verify and decode a JWT refresh token.
    
    This function verifies the JWT refresh token signature, checks expiration,
    and validates the token type. It returns the decoded payload
    if the token is valid.
    
    Args:
        token: JWT refresh token to verify
        config: JWT configuration object (uses default if not provided)
        
    Returns:
        Decoded token payload
        
    Raises:
        JWTTokenExpiredError: If token has expired
        JWTTokenInvalidError: If token is invalid or malformed
        JWTTokenDecodeError: If token cannot be decoded
        JWTTokenError: For other JWT-related errors
        
    Example:
        >>> payload = verify_refresh_token(refresh_token)
        >>> # Returns: {"sub": "user123", "iat": ..., "exp": ..., "type": "refresh"}
        
    Security Notes:
        - Verifies token signature using secret key
        - Checks token expiration automatically
        - Validates token type is "refresh"
        - Should be used only for token refresh operations
    """
    if config is None:
        config = get_jwt_config()
    
    try:
        # Decode and verify the token
        payload = jwt.decode(
            token, 
            config.secret_key, 
            algorithms=[config.algorithm]
        )
        
        # Validate token type
        token_type = payload.get("type")
        if token_type != "refresh":
            raise JWTTokenInvalidError(f"Invalid token type: {token_type}. Expected 'refresh'")
        
        # Check if token has expired
        exp = payload.get("exp")
        if exp and datetime.utcnow() > datetime.fromtimestamp(exp):
            raise JWTTokenExpiredError("Refresh token has expired")
        
        return payload
        
    except JWTError as e:
        # Re-raise our custom exceptions
        if "expired" in str(e).lower():
            raise JWTTokenExpiredError("Refresh token has expired")
        elif "invalid" in str(e).lower():
            raise JWTTokenInvalidError("Refresh token is invalid or malformed")
        else:
            raise JWTTokenDecodeError(f"Failed to decode refresh token: {str(e)}")
    except Exception as e:
        raise JWTTokenError(f"Unexpected error verifying refresh token: {str(e)}")


def extract_user_id_from_token(token: str, config: Optional[JWTConfig] = None) -> Optional[str]:
    """
    Extract user ID from a JWT token.
    
    This function extracts the user ID (subject) from a JWT token
    without performing full verification. Use this only when you
    need the user ID and don't need to verify the token's validity.
    
    Args:
        token: JWT token to extract from
        config: JWT configuration object (uses default if not provided)
        
    Returns:
        User ID (subject) or None if extraction fails
        
    Example:
        >>> user_id = extract_user_id_from_token(token)
        >>> # Returns: "user123" or None
        
    Security Notes:
        - Does not verify token signature or expiration
        - Use only when full verification is not required
        - For authentication, use verify_access_token instead
        - Useful for logging or analytics purposes
    """
    if config is None:
        config = get_jwt_config()
    
    try:
        # Decode without verification
        payload = jwt.decode(
            token, 
            config.secret_key, 
            algorithms=[config.algorithm],
            options={"verify_signature": False}
        )
        return payload.get("sub")
    except Exception:
        return None


def is_token_expired(token: str, config: Optional[JWTConfig] = None) -> bool:
    """
    Check if a JWT token is expired.
    
    This function checks if a JWT token has expired without
    performing full verification. Use this for quick expiration
    checks when you don't need the full payload.
    
    Args:
        token: JWT token to check
        config: JWT configuration object (uses default if not provided)
        
    Returns:
        True if token is expired, False otherwise
        
    Example:
        >>> is_expired = is_token_expired(token)
        >>> # Returns: True or False
        
    Security Notes:
        - Does not verify token signature
        - Only checks expiration timestamp
        - Use verify_access_token for full validation
        - Useful for client-side expiration checks
    """
    try:
        payload = verify_access_token(token, config)
        return False  # If verification succeeds, token is not expired
    except JWTTokenExpiredError:
        return True
    except Exception:
        return True  # Treat any error as expired for safety


def create_tokens_for_user(
    user_id: str, 
    config: Optional[JWTConfig] = None
) -> Dict[str, str]:
    """
    Create both access and refresh tokens for a user.
    
    This function creates both access and refresh tokens for a user
    in a single call. This is commonly used during login or token
    refresh operations.
    
    Args:
        user_id: User's ID
        config: JWT configuration object (uses default if not provided)
        
    Returns:
        Dictionary containing access_token and refresh_token
        
    Raises:
        JWTTokenError: If token creation fails
        
    Example:
        >>> tokens = create_tokens_for_user("user123")
        >>> # Returns: {"access_token": "...", "refresh_token": "..."}
        
    Security Notes:
        - Creates both token types with appropriate expiration
        - Access token has shorter expiration for security
        - Refresh token has longer expiration for convenience
        - Both tokens include standard JWT claims
    """
    if config is None:
        config = get_jwt_config()
    
    try:
        access_token = create_access_token(user_id, config=config)
        refresh_token = create_refresh_token(user_id, config=config)
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token
        }
    except Exception as e:
        raise JWTTokenError(f"Failed to create tokens for user: {str(e)}")


def get_token_expiration_time(token: str, config: Optional[JWTConfig] = None) -> Optional[datetime]:
    """
    Get the expiration time of a JWT token.
    
    This function extracts the expiration time from a JWT token
    without performing full verification.
    
    Args:
        token: JWT token to check
        config: JWT configuration object (uses default if not provided)
        
    Returns:
        Expiration datetime or None if extraction fails
        
    Example:
        >>> exp_time = get_token_expiration_time(token)
        >>> # Returns: datetime(2024, 1, 1, 12, 0, 0) or None
        
    Security Notes:
        - Does not verify token signature
        - Only extracts expiration timestamp
        - Use verify_access_token for full validation
        - Useful for displaying token expiration to users
    """
    if config is None:
        config = get_jwt_config()
    
    try:
        # Decode without verification
        payload = jwt.decode(
            token, 
            config.secret_key, 
            algorithms=[config.algorithm],
            options={"verify_signature": False}
        )
        
        exp = payload.get("exp")
        if exp:
            return datetime.fromtimestamp(exp)
        return None
    except Exception:
        return None

