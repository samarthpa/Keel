"""
Redis Store

Redis client wrapper for caching and data storage.
"""

import json
import redis.asyncio as redis
from typing import Any, Optional
from app.settings import settings


class RedisStore:
    """
    Redis store for caching and data persistence.

    Provides async Redis operations with JSON serialization
    and connection management.
    """

    def __init__(self):
        """
        Initialize the Redis store.
        """
        self.redis_url = settings.redis_url
        self.redis_password = settings.redis_password
        self.client: Optional[redis.Redis] = None

    async def connect(self):
        """
        Establish connection to Redis.
        """
        # TODO: Implement Redis connection
        # This will create a Redis client connection

        try:
            self.client = redis.from_url(
                self.redis_url, password=self.redis_password, decode_responses=True
            )
            await self.client.ping()
        except Exception as e:
            # TODO: Add proper logging
            print(f"Failed to connect to Redis: {e}")
            self.client = None

    async def disconnect(self):
        """
        Close Redis connection.
        """
        if self.client:
            await self.client.close()
            self.client = None

    async def set_idempotency(self, key: str, ttl_sec: int = 86400) -> bool:
        """
        Set an idempotency key using Redis NX (only if not exists) semantics.

        This function is used to prevent duplicate processing of requests by setting
        a key that represents a unique request identifier. The key will only be set
        if it doesn't already exist, ensuring idempotent behavior.

        Key Shape: "idempotency:{request_hash}"
        TTL Rationale: 24 hours (86400 seconds) is sufficient for most API requests
        to complete and prevents indefinite key accumulation while allowing for
        reasonable retry windows.

        Args:
            key: Unique identifier for the request (typically a hash of request data)
            ttl_sec: Time to live in seconds (default: 86400 = 24 hours)

        Returns:
            bool: True if the key was newly set (first time), False if it already existed

        Example:
            >>> await redis_store.set_idempotency("abc123", 3600)
            True  # Key was set for the first time
            >>> await redis_store.set_idempotency("abc123", 3600)
            False # Key already existed, no change made
        """
        if not self.client:
            await self.connect()

        try:
            # Use NX flag to only set if key doesn't exist
            # Returns 1 if key was set, 0 if key already existed
            result = await self.client.set(
                f"idempotency:{key}", "1", ex=ttl_sec, nx=True
            )
            return result is True  # True if key was newly set
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error setting idempotency key {key}: {e}")
            return False

    async def place_cache_get(self, place_id: str) -> Optional[str]:
        """
        Get cached merchant ID for a Google Places place_id.

        This function retrieves the merchant ID that was previously cached for a
        given Google Places place_id. This reduces API calls to Google Places
        and improves response times for repeated lookups.

        Key Shape: "place_cache:{place_id}"
        TTL Rationale: Place data changes infrequently, so longer cache times
        are acceptable. The default TTL is set in place_cache_set().

        Args:
            place_id: Google Places place_id to look up

        Returns:
            Optional[str]: Cached merchant ID if found, None otherwise

        Example:
            >>> await redis_store.place_cache_get("ChIJN1t_tDeuEmsRUsoyG83frY4")
            "merchant_12345"  # Returns cached merchant ID
            >>> await redis_store.place_cache_get("nonexistent_place")
            None  # No cached data found
        """
        if not self.client:
            await self.connect()

        try:
            cached_value = await self.client.get(f"place_cache:{place_id}")
            return cached_value
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error getting place cache for {place_id}: {e}")
            return None

    async def place_cache_set(
        self, place_id: str, merchant_id: str, ttl_sec: int = 604800
    ) -> bool:
        """
        Cache merchant ID for a Google Places place_id.

        This function stores the merchant ID associated with a Google Places place_id
        for future lookups. This reduces API calls to Google Places and improves
        response times for repeated lookups.

        Key Shape: "place_cache:{place_id}"
        TTL Rationale: 7 days (604800 seconds) balances cache effectiveness with
        data freshness. Place data changes infrequently, but businesses can close,
        change names, or move locations. 7 days ensures reasonable data freshness
        while maximizing cache hit rates.

        Args:
            place_id: Google Places place_id
            merchant_id: Internal merchant ID to cache
            ttl_sec: Time to live in seconds (default: 604800 = 7 days)

        Returns:
            bool: True if successfully cached, False otherwise

        Example:
            >>> await redis_store.place_cache_set("ChIJN1t_tDeuEmsRUsoyG83frY4", "merchant_12345")
            True  # Successfully cached
        """
        if not self.client:
            await self.connect()

        try:
            await self.client.set(f"place_cache:{place_id}", merchant_id, ex=ttl_sec)
            return True
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error setting place cache for {place_id}: {e}")
            return False

    async def get(self, key: str) -> Optional[Any]:
        """
        Get a value from Redis.

        Args:
            key: Redis key

        Returns:
            Optional[Any]: Value if found, None otherwise
        """
        if not self.client:
            await self.connect()

        try:
            value = await self.client.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error getting key {key}: {e}")
            return None

    async def set(self, key: str, value: Any, expire: Optional[int] = None) -> bool:
        """
        Set a value in Redis.

        Args:
            key: Redis key
            value: Value to store
            expire: Expiration time in seconds

        Returns:
            bool: True if successful
        """
        if not self.client:
            await self.connect()

        try:
            serialized_value = json.dumps(value)
            await self.client.set(key, serialized_value, ex=expire)
            return True
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error setting key {key}: {e}")
            return False

    async def delete(self, key: str) -> bool:
        """
        Delete a key from Redis.

        Args:
            key: Redis key to delete

        Returns:
            bool: True if successful
        """
        if not self.client:
            await self.connect()

        try:
            result = await self.client.delete(key)
            return result > 0
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error deleting key {key}: {e}")
            return False

    async def exists(self, key: str) -> bool:
        """
        Check if a key exists in Redis.

        Args:
            key: Redis key to check

        Returns:
            bool: True if key exists
        """
        if not self.client:
            await self.connect()

        try:
            result = await self.client.exists(key)
            return result > 0
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error checking key {key}: {e}")
            return False

    async def expire(self, key: str, seconds: int) -> bool:
        """
        Set expiration time for a key.

        Args:
            key: Redis key
            seconds: Expiration time in seconds

        Returns:
            bool: True if successful
        """
        if not self.client:
            await self.connect()

        try:
            result = await self.client.expire(key, seconds)
            return result > 0
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error setting expiration for key {key}: {e}")
            return False

    async def ttl(self, key: str) -> int:
        """
        Get time to live for a key.

        Args:
            key: Redis key

        Returns:
            int: TTL in seconds, -1 if no expiration, -2 if key doesn't exist
        """
        if not self.client:
            await self.connect()

        try:
            return await self.client.ttl(key)
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error getting TTL for key {key}: {e}")
            return -2

    async def flush_db(self) -> bool:
        """
        Clear all keys from the current database.

        Returns:
            bool: True if successful
        """
        if not self.client:
            await self.connect()

        try:
            await self.client.flushdb()
            return True
        except Exception as e:
            # TODO: Add proper logging
            print(f"Error flushing database: {e}")
            return False

    async def ping(self) -> bool:
        """
        Ping Redis server to check connectivity.

        Returns:
            bool: True if Redis is responsive
        """
        if not self.client:
            await self.connect()

        try:
            await self.client.ping()
            return True
        except Exception as e:
            # TODO: Add proper logging
            print(f"Redis ping failed: {e}")
            return False
