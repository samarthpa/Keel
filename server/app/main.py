"""
Main FastAPI Application

Entry point for the Keel API server. Configures the FastAPI application,
includes middleware, registers routes, and handles application lifecycle.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes import health, resolve, score, config, events
from app.middleware.request_id import RequestIDMiddleware
from app.utils.logging import configure_logging
from app.settings import settings

# Configure logging on import
configure_logging()


def create_app() -> FastAPI:
    """
    Create and configure the FastAPI application.

    Returns:
        FastAPI: Configured FastAPI application instance
    """
    app = FastAPI(
        title=settings.app_name,
        description="Location-based credit card recommendation service",
        version=settings.app_version,
    )

    # Add RequestID middleware for request tracing
    app.add_middleware(RequestIDMiddleware)

    # Add CORS middleware with permissive settings
    # "*" allowed in development, should be restricted in production
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Register route modules under their defined paths
    app.include_router(health.router, tags=["health"])
    app.include_router(config.router, tags=["config"])
    app.include_router(score.router, tags=["score"])
    app.include_router(resolve.router, tags=["resolve"])
    app.include_router(events.router, tags=["events"])

    # TODO: Register exception handlers from utils/errors if desired
    # Example: app.add_exception_handler(Exception, generic_exception_handler)
    # Example: app.add_exception_handler(ValidationError, validation_error_handler)

    return app


app = create_app()


@app.on_event("startup")
async def startup_event():
    """
    Application startup event handler.
    Initialize services, connections, and perform startup tasks.
    """
    # TODO: Initialize database connections
    # TODO: Initialize Redis connections
    # TODO: Validate external API keys
    pass


@app.on_event("shutdown")
async def shutdown_event():
    """
    Application shutdown event handler.
    Clean up resources, close connections, and perform cleanup tasks.
    """
    # TODO: Close database connections
    # TODO: Close Redis connections
    # TODO: Clean up any open resources
    pass
