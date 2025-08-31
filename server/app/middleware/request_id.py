"""
Request ID Middleware

Middleware to add unique request IDs to all requests for tracking
and debugging purposes. This enables distributed tracing across
microservices and helps correlate logs from different components.
"""

import uuid
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp


class RequestIDMiddleware(BaseHTTPMiddleware):
    """
    Middleware that adds a unique request ID to each request.

    This middleware enables distributed tracing by:
    - Reading existing X-Request-ID header or generating a new UUID
    - Binding the request ID to the request context for logging
    - Adding the request ID to response headers for client correlation

    Benefits for traceability:
    - Correlate logs across multiple services in a request chain
    - Track request flow through different components
    - Debug issues by following a single request ID
    - Monitor performance and identify bottlenecks
    """

    def __init__(self, app: ASGIApp):
        """
        Initialize the request ID middleware.

        Args:
            app: The ASGI application to wrap
        """
        super().__init__(app)

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Process the request and add a request ID.

        This method:
        1. Checks for existing X-Request-ID header from client
        2. Generates a new UUID if no header exists
        3. Binds the request ID to request.state for logging
        4. Processes the request through the application
        5. Adds the request ID to response headers

        Args:
            request: The incoming request
            call_next: The next middleware or route handler

        Returns:
            Response: The response with request ID header
        """
        # Check for existing request ID from client
        request_id = request.headers.get("X-Request-ID")

        # Generate new UUID if no request ID provided
        if not request_id:
            request_id = str(uuid.uuid4())

        # Bind request ID to request state for logging context
        # This allows all loggers to access the request ID
        request.state.request_id = request_id

        # Process the request through the application
        response = await call_next(request)

        # Add request ID to response headers for client correlation
        # This helps clients correlate their requests with server logs
        response.headers["X-Request-ID"] = request_id

        return response
