"""Configuración tipada y validada al arrancar. Valores por defecto: §11 de la guía."""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Config:
    port: int
    catalog: str  # postgres | mongo
    database_url: str
    mongo_url: str
    redis_url: str
    jwt_secret: str
    jwt_ttl_seconds: int
    outbox_poll_ms: int
    cors_origin: str


def load(env: dict[str, str] | None = None) -> Config:
    e = os.environ if env is None else env
    config = Config(
        port=int(e.get("PORT", "8084")),
        catalog=e.get("HEX_CATALOG", "postgres"),
        database_url=e.get("DATABASE_URL", "postgresql+psycopg://hex:hex-lab-pass@localhost:15432/hex_orders"),
        mongo_url=e.get("MONGO_URL", "mongodb://localhost:17017/hex_catalog"),
        redis_url=e.get("REDIS_URL", "redis://localhost:16379"),
        jwt_secret=e.get("JWT_SECRET", "hex-lab-dev-secret-change-me-0123456789"),
        jwt_ttl_seconds=int(e.get("JWT_TTL_SECONDS", "900")),
        outbox_poll_ms=int(e.get("OUTBOX_POLL_MS", "500")),
        cors_origin=e.get("CORS_ORIGIN", "http://localhost:5173"),
    )
    if config.catalog not in ("postgres", "mongo"):
        raise ValueError(f"HEX_CATALOG must be postgres or mongo, was {config.catalog!r}")
    if len(config.jwt_secret.encode()) < 32:
        raise ValueError("JWT_SECRET must be at least 32 bytes for HS256")
    return config
