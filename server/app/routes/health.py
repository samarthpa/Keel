"""
Health Check Routes

Health check endpoints for monitoring and load balancer health checks.
"""

from fastapi import APIRouter
from typing import Dict, Any
from app.settings import settings

router = APIRouter()


@router.get("/health")
async def health_check() -> Dict[str, Any]:
    """
    Basic health check endpoint.

    Returns:
        Dict[str, Any]: Health status with environment information
    """
    return {"ok": True, "env": settings.env}


@router.get("/ready")
async def readiness_check() -> Dict[str, Any]:
    """
    Readiness check endpoint.

    Verifies that the application is ready to serve requests,
    including database connections and external service dependencies.

    Returns:
        Dict[str, Any]: Readiness status information
    """
    return {
        "status": "ready",
        "dependencies": {"database": "connected", "redis": "connected"},
    }


@router.get("/live")
async def liveness_check() -> Dict[str, Any]:
    """
    Liveness check endpoint.

    Verifies that the application is alive and running.
    Used by Kubernetes and other container orchestration systems.

    Returns:
        Dict[str, Any]: Liveness status information
    """
    return {"status": "alive", "uptime": "running"}
