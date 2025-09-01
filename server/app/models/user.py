"""
User model for authentication and user management.

This module defines the User table using SQLModel for database operations.
"""

from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field


class User(SQLModel, table=True):
    """
    User model for authentication and user management.
    
    Attributes:
        id: Primary key (auto-incrementing integer)
        email: User's email address (unique, indexed)
        hashed_password: Bcrypt hashed password
        created_at: Account creation timestamp (UTC)
    """
    
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True, max_length=255)
    hashed_password: str = Field(max_length=255)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        schema_extra = {
            "example": {
                "id": 1,
                "email": "user@example.com",
                "created_at": "2024-01-01T00:00:00Z"
            }
        }
