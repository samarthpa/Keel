"""
User store for CRUD operations on user data.

This module provides database operations for user management
including creation, retrieval, and authentication.
"""

from typing import Optional
from sqlmodel import Session, select
from app.models.user import User
from app.security.passwords import hash_password, verify_password


class UserStore:
    """
    User store for database operations on user data.
    """
    
    def __init__(self, session: Session):
        """
        Initialize user store with database session.
        
        Args:
            session: Database session for operations
        """
        self.session = session
    
    def get_by_email(self, email: str) -> Optional[User]:
        """
        Get user by email address.
        
        Args:
            email: User's email address
            
        Returns:
            User object or None if not found
        """
        statement = select(User).where(User.email == email)
        return self.session.exec(statement).first()
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        """
        Get user by ID.
        
        Args:
            user_id: User's ID
            
        Returns:
            User object or None if not found
        """
        statement = select(User).where(User.id == user_id)
        return self.session.exec(statement).first()
    
    def create_user(self, email: str, hashed_password: str) -> User:
        """
        Create a new user with hashed password.
        
        Args:
            email: User's email address
            hashed_password: Already hashed password
            
        Returns:
            Created user object
            
        Raises:
            ValueError: If email already exists
        """
        # Check if user already exists
        if self.get_by_email(email):
            raise ValueError(f"User with email {email} already exists")
        
        user = User(email=email, hashed_password=hashed_password)
        self.session.add(user)
        self.session.commit()
        self.session.refresh(user)
        return user
    
    def authenticate_user(self, email: str, password: str) -> Optional[User]:
        """
        Authenticate user with email and password.
        
        Args:
            email: User's email address
            password: Plain text password
            
        Returns:
            User object if authentication successful, None otherwise
        """
        user = self.get_by_email(email)
        if not user:
            return None
        
        if not verify_password(password, user.hashed_password):
            return None
        
        return user
    
    def user_exists(self, email: str) -> bool:
        """
        Check if user with email exists.
        
        Args:
            email: Email to check
            
        Returns:
            True if user exists, False otherwise
        """
        return self.get_by_email(email) is not None
