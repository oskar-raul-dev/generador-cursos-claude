"""Cursores opacos: el cliente los devuelve tal cual; solo el adaptador sabe qué llevan dentro.
Un cursor ilegible se trata como "primera página"."""

from __future__ import annotations

import base64
from datetime import datetime


def encode(raw: str) -> str:
    return base64.urlsafe_b64encode(raw.encode()).decode().rstrip("=")


def decode(cursor: str | None) -> str | None:
    if not cursor:
        return None
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        return base64.urlsafe_b64decode(padded).decode()
    except Exception:
        return None


def encode_time(ts: datetime, id: str) -> str:
    return encode(f"{ts.isoformat()}|{id}")


def decode_time(cursor: str | None) -> tuple[datetime, str] | None:
    raw = decode(cursor)
    if not raw or "|" not in raw:
        return None
    ts, id = raw.split("|", 1)
    try:
        return datetime.fromisoformat(ts), id
    except ValueError:
        return None
