"""
Error handling utilities.

Custom exception classes and error handling utilities for the API.
"""

from fastapi.responses import JSONResponse


def error_response(
    code: str, message: str, http_status: int = 400, retryable: bool = False
) -> JSONResponse:
    """
    Create a standardized error response.

    Args:
        code: Error code identifier
        message: Human-readable error message
        http_status: HTTP status code
        retryable: Whether the error is retryable

    Returns:
        JSONResponse: Standardized error response

    Example:
        >>> error_response("INVALID_INPUT", "Missing required field", 400, False)
        JSONResponse(
            status_code=400,
            content={"error": {"code": "INVALID_INPUT", "message": "Missing required field", "retryable": False}}
        )
    """
    return JSONResponse(
        status_code=http_status,
        content={"error": {"code": code, "message": message, "retryable": retryable}},
    )


def generic_exception_handler(exc: Exception) -> JSONResponse:
    """
    Generic exception handler for unexpected errors.

    Converts any unhandled exception into a standardized error response
    with a 502 status code and retryable flag set to True.

    Args:
        exc: The exception that was raised

    Returns:
        JSONResponse: Standardized error response

    Example:
        >>> try:
        ...     # Some operation that might fail
        ...     pass
        ... except Exception as e:
        ...     return generic_exception_handler(e)
        JSONResponse(
            status_code=502,
            content={"error": {"code": "INTERNAL_ERROR", "message": "An unexpected error occurred", "retryable": True}}
        )
    """
    return error_response(
        code="INTERNAL_ERROR",
        message="An unexpected error occurred",
        http_status=502,
        retryable=True,
    )
