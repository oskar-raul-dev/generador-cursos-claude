"""Revocación por jti con TTL: Redis olvida la clave cuando el token habría expirado."""

from __future__ import annotations

from datetime import timedelta

import redis

_PREFIX = "hex:revoked:"


class RedisTokenRevocationStore:
    def __init__(self, url: str) -> None:
        self.client = redis.Redis.from_url(url)
        self.client.ping()

    def close(self) -> None:
        self.client.close()

    def revoke(self, token_id: str, ttl: timedelta) -> None:
        self.client.set(_PREFIX + token_id, "1", ex=max(1, int(ttl.total_seconds())))

    def is_revoked(self, token_id: str) -> bool:
        return self.client.exists(_PREFIX + token_id) == 1
