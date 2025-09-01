"""
Password hashing and verification utilities using bcrypt.

This module provides secure password hashing and verification using
the bcrypt algorithm through passlib. Bcrypt is designed to be
computationally expensive to prevent brute force attacks.

Security Features:
    - Bcrypt with configurable rounds (default: 12)
    - Automatic salt generation
    - Constant-time comparison to prevent timing attacks
    - Password strength validation
    - Configurable password requirements

Cost Factor Considerations:
    - Rounds 12: ~250ms on modern hardware (recommended)
    - Rounds 14: ~1 second (high security)
    - Rounds 16: ~4 seconds (maximum security)
    - Balance security with user experience
"""

from passlib.context import CryptContext
from app.security.auth_settings import auth_settings


# Password context using bcrypt with configurable rounds
# bcrypt automatically handles salt generation and storage
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=auth_settings.bcrypt_rounds
)


def hash_password(password: str) -> str:
    """
    Hash a password using bcrypt.
    
    This function uses bcrypt to create a secure hash of the password.
    The hash includes the salt and cost factor, making it safe to store
    in a database. Bcrypt is designed to be computationally expensive
    to prevent brute force attacks.
    
    Args:
        password: Plain text password to hash
        
    Returns:
        Hashed password string (includes salt and cost factor)
        
    Example:
        >>> hashed = hash_password("my_password")
        >>> # Returns: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8KqQK8e"
        
    Security Notes:
        - Never store plain text passwords
        - Each hash is unique due to random salt
        - Cost factor makes brute force attacks expensive
        - Hash is safe to store in database
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain password against its hash.
    
    This function performs a constant-time comparison of the plain
    password against the stored hash. It uses bcrypt's verification
    which automatically extracts the salt and cost factor from the hash.
    
    Args:
        plain_password: Plain text password to verify
        hashed_password: Stored hash to check against
        
    Returns:
        True if password matches, False otherwise
        
    Example:
        >>> is_valid = verify_password("my_password", stored_hash)
        >>> # Returns: True if password matches
        
    Security Notes:
        - Constant-time comparison prevents timing attacks
        - Never compare plain text passwords directly
        - Hash includes salt, so same password has different hashes
        - Verification is computationally expensive (by design)
    """
    return pwd_context.verify(plain_password, hashed_password)


def validate_password_strength(password: str) -> bool:
    """
    Validate password strength based on configured requirements.
    
    This function checks if a password meets the configured strength
    requirements including length, character types, and complexity.
    
    Args:
        password: Password to validate
        
    Returns:
        True if password meets requirements, False otherwise
        
    Example:
        >>> is_strong = validate_password_strength("MyPass123!")
        >>> # Returns: True if meets all requirements
        
    Requirements (configurable):
        - Minimum length: 8 characters
        - Numbers: At least one digit
        - Uppercase: At least one uppercase letter
        - Special chars: At least one special character
    """
    # Check minimum length
    if len(password) < auth_settings.password_min_length:
        return False
    
    # Check for numbers if required
    if auth_settings.password_require_numbers and not any(c.isdigit() for c in password):
        return False
    
    # Check for uppercase letters if required
    if auth_settings.password_require_uppercase and not any(c.isupper() for c in password):
        return False
    
    # Check for special characters if required
    if auth_settings.password_require_special_chars:
        special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        if not any(c in special_chars for c in password):
            return False
    
    return True


def get_password_strength_feedback(password: str) -> dict:
    """
    Get detailed feedback on password strength.
    
    This function provides detailed feedback about password strength,
    including which requirements are met and suggestions for improvement.
    
    Args:
        password: Password to analyze
        
    Returns:
        Dictionary with strength analysis and feedback
        
    Example:
        >>> feedback = get_password_strength_feedback("weak")
        >>> # Returns: {"is_strong": False, "issues": ["too_short", "no_numbers"]}
    """
    feedback = {
        "is_strong": True,
        "issues": [],
        "suggestions": []
    }
    
    # Check length
    if len(password) < auth_settings.password_min_length:
        feedback["is_strong"] = False
        feedback["issues"].append("too_short")
        feedback["suggestions"].append(f"Password must be at least {auth_settings.password_min_length} characters")
    
    # Check for numbers
    if auth_settings.password_require_numbers and not any(c.isdigit() for c in password):
        feedback["is_strong"] = False
        feedback["issues"].append("no_numbers")
        feedback["suggestions"].append("Include at least one number")
    
    # Check for uppercase
    if auth_settings.password_require_uppercase and not any(c.isupper() for c in password):
        feedback["is_strong"] = False
        feedback["issues"].append("no_uppercase")
        feedback["suggestions"].append("Include at least one uppercase letter")
    
    # Check for special characters
    if auth_settings.password_require_special_chars:
        special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        if not any(c in special_chars for c in password):
            feedback["is_strong"] = False
            feedback["issues"].append("no_special_chars")
            feedback["suggestions"].append("Include at least one special character (!@#$%^&*)")
    
    return feedback


def generate_secure_password(length: int = 16) -> str:
    """
    Generate a cryptographically secure random password.
    
    This function generates a secure random password that meets
    all configured strength requirements. Useful for generating
    temporary passwords or testing.
    
    Args:
        length: Length of password to generate (default: 16)
        
    Returns:
        Secure random password
        
    Example:
        >>> password = generate_secure_password()
        >>> # Returns: "Kj9#mN2$pQ7@vX5!"
        
    Security Notes:
        - Uses cryptographically secure random number generator
        - Ensures all character types are included
        - Meets all configured strength requirements
        - Suitable for temporary passwords only
    """
    import secrets
    import string
    
    # Define character sets
    lowercase = string.ascii_lowercase
    uppercase = string.ascii_uppercase
    digits = string.digits
    special = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    
    # Ensure at least one character from each required set
    password_chars = []
    
    # Add required character types
    if auth_settings.password_require_numbers:
        password_chars.append(secrets.choice(digits))
    if auth_settings.password_require_uppercase:
        password_chars.append(secrets.choice(uppercase))
    if auth_settings.password_require_special_chars:
        password_chars.append(secrets.choice(special))
    
    # Fill remaining length with random characters
    all_chars = lowercase + uppercase + digits + special
    remaining_length = length - len(password_chars)
    
    for _ in range(remaining_length):
        password_chars.append(secrets.choice(all_chars))
    
    # Shuffle the password to avoid predictable patterns
    password_list = list(password_chars)
    secrets.SystemRandom().shuffle(password_list)
    
    return ''.join(password_list)


# Legacy function names for backward compatibility
def hash_password_legacy(password: str) -> str:
    """
    Legacy function name for backward compatibility.
    
    This function is identical to hash_password() and is provided
    for backward compatibility with existing code.
    
    Args:
        password: Plain text password to hash
        
    Returns:
        Hashed password string
    """
    return hash_password(password)


def verify_password_legacy(plain_password: str, hashed_password: str) -> bool:
    """
    Legacy function name for backward compatibility.
    
    This function is identical to verify_password() and is provided
    for backward compatibility with existing code.
    
    Args:
        plain_password: Plain text password to verify
        hashed_password: Stored hash to check against
        
    Returns:
        True if password matches, False otherwise
    """
    return verify_password(plain_password, hashed_password)

