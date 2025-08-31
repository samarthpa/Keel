"""
Logging Utilities

Logging configuration and utilities for the Keel API.
"""

import logging
import sys
import structlog
from typing import Optional
from app.settings import settings


def configure_logging(
    log_level: Optional[str] = None, log_format: Optional[str] = None
) -> None:
    """
    Configure structlog to output JSON lines with ISO timestamps.

    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_format: Log message format string (not used with structlog)
    """
    level = log_level or settings.log_level

    # Configure structlog for JSON output with ISO timestamps
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer(),
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    # Configure standard library logging to use structlog
    logging.basicConfig(
        format="%(message)s", stream=sys.stdout, level=getattr(logging, level.upper())
    )

    # Set specific logger levels
    logging.getLogger("uvicorn").setLevel(logging.INFO)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)

    # Create application logger
    logger = structlog.get_logger("keel")
    logger.setLevel(getattr(logging, level.upper()))


def setup_logging(
    log_level: Optional[str] = None, log_format: Optional[str] = None
) -> None:
    """
    Setup application logging configuration.

    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_format: Log message format string
    """
    # Use the new structlog configuration
    configure_logging(log_level, log_format)


def get_logger(name: str) -> structlog.BoundLogger:
    """
    Get a structlog logger instance for the specified name.

    Args:
        name: Logger name

    Returns:
        structlog.BoundLogger: Logger instance
    """
    return structlog.get_logger(f"keel.{name}")


class RequestLogger:
    """
    Logger for HTTP request/response logging.
    """

    def __init__(self, logger: structlog.BoundLogger):
        """
        Initialize the request logger.

        Args:
            logger: Logger instance
        """
        self.logger = logger

    def log_request(
        self,
        method: str,
        url: str,
        request_id: str,
        user_agent: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> None:
        """
        Log incoming HTTP request.

        Args:
            method: HTTP method
            url: Request URL
            request_id: Unique request ID
            user_agent: User agent string
            ip_address: Client IP address
        """
        # TODO: Implement request logging
        # This will log structured request information

        self.logger.info(
            "Incoming request",
            request_id=request_id,
            method=method,
            url=url,
            user_agent=user_agent,
            ip_address=ip_address,
            event_type="request_start",
        )

    def log_response(
        self,
        request_id: str,
        status_code: int,
        response_time: float,
        content_length: Optional[int] = None,
    ) -> None:
        """
        Log HTTP response.

        Args:
            request_id: Unique request ID
            status_code: HTTP status code
            response_time: Response time in seconds
            content_length: Response content length
        """
        # TODO: Implement response logging
        # This will log structured response information

        self.logger.info(
            "Response completed",
            request_id=request_id,
            status_code=status_code,
            response_time=response_time,
            content_length=content_length,
            event_type="request_end",
        )

    def log_error(
        self, request_id: str, error: Exception, status_code: Optional[int] = None
    ) -> None:
        """
        Log request error.

        Args:
            request_id: Unique request ID
            error: Exception that occurred
            status_code: HTTP status code if available
        """
        # TODO: Implement error logging
        # This will log structured error information

        self.logger.error(
            "Request error",
            request_id=request_id,
            error_type=type(error).__name__,
            error_message=str(error),
            status_code=status_code,
            event_type="request_error",
            exc_info=True,
        )


class PerformanceLogger:
    """
    Logger for performance and timing information.
    """

    def __init__(self, logger: structlog.BoundLogger):
        """
        Initialize the performance logger.

        Args:
            logger: Logger instance
        """
        self.logger = logger

    def log_timing(
        self, operation: str, duration: float, metadata: Optional[dict] = None
    ) -> None:
        """
        Log operation timing information.

        Args:
            operation: Operation name
            duration: Duration in seconds
            metadata: Additional metadata
        """
        # TODO: Implement timing logging
        # This will log performance metrics

        self.logger.info(
            "Operation timing",
            operation=operation,
            duration=duration,
            metadata=metadata or {},
            event_type="performance",
        )

    def log_memory_usage(
        self, memory_mb: float, component: Optional[str] = None
    ) -> None:
        """
        Log memory usage information.

        Args:
            memory_mb: Memory usage in MB
            component: Component name
        """
        # TODO: Implement memory logging
        # This will log memory usage metrics

        self.logger.info(
            "Memory usage",
            memory_mb=memory_mb,
            component=component,
            event_type="memory",
        )


class BusinessLogger:
    """
    Logger for business logic events.
    """

    def __init__(self, logger: structlog.BoundLogger):
        """
        Initialize the business logger.

        Args:
            logger: Logger instance
        """
        self.logger = logger

    def log_merchant_resolution(
        self,
        lat: float,
        lon: float,
        merchant: str,
        confidence: float,
        request_id: Optional[str] = None,
    ) -> None:
        """
        Log merchant resolution events.

        Args:
            lat: Latitude coordinate
            lon: Longitude coordinate
            merchant: Resolved merchant name
            confidence: Resolution confidence
            request_id: Request ID if available
        """
        # TODO: Implement merchant resolution logging
        # This will log business events for analytics

        self.logger.info(
            "Merchant resolved",
            lat=lat,
            lon=lon,
            merchant=merchant,
            confidence=confidence,
            request_id=request_id,
            event_type="merchant_resolution",
        )

    def log_card_recommendation(
        self,
        merchant: str,
        category: str,
        recommended_card: str,
        score: float,
        request_id: Optional[str] = None,
    ) -> None:
        """
        Log card recommendation events.

        Args:
            merchant: Merchant name
            category: Merchant category
            recommended_card: Recommended card
            score: Recommendation score
            request_id: Request ID if available
        """
        # TODO: Implement card recommendation logging
        # This will log business events for analytics

        self.logger.info(
            "Card recommended",
            merchant=merchant,
            category=category,
            recommended_card=recommended_card,
            score=score,
            request_id=request_id,
            event_type="card_recommendation",
        )
