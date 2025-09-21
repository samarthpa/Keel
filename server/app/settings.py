"""
Application Settings

Configuration management for the Keel API. Handles environment variables,
default values, and configuration validation.
"""

from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    """

    # Application
    app_name: str = "Keel API"
    app_version: str = "1.0.0"
    debug: bool = False
    env: str = "development"  # Environment (development, staging, production)

    # Server
    host: str = "0.0.0.0"
    port: int = 8000

    # Database
    database_url: Optional[str] = None

    # Redis
    redis_url: str = "redis://localhost:6379"
    redis_password: Optional[str] = None

    # External APIs
    google_places_api_key: Optional[str] = "AIzaSyALPTBqIfOHe2X1LGDafnqPgp549kWQQAE"
    openai_api_key: Optional[str] = (
        "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"
    )

    # Google Places API Settings
    places_radius: int = 100  # Search radius in meters
    places_timeout: int = 10  # Request timeout in seconds
    places_retries: int = 3  # Number of retry attempts

    # Rewards Configuration
    rewards_version: str = "1.0"  # Version of rewards rules being used
    model_version: str = "1.0"  # Version of ML model (future use)
    min_confidence: float = 0.5  # Minimum confidence threshold for merchant resolution

    # Logging
    log_level: str = "INFO"
    log_format: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    # CORS
    cors_origins: list = ["*"]

    # Security
    secret_key: str = "your-secret-key-here"
    access_token_expire_minutes: int = 30

    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "allow"


# Global settings instance
settings = Settings()
