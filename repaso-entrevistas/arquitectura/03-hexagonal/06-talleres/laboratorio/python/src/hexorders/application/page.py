"""Página con cursor opaco (None en la última). El cursor lo fabrica y lo lee el adaptador."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

MAX_LIMIT = 100
DEFAULT_LIMIT = 20


@dataclass(frozen=True, slots=True)
class Page[T]:
    items: list[T]
    next_cursor: str | None

    def map[R](self, fn: Callable[[T], R]) -> Page[R]:
        return Page([fn(i) for i in self.items], self.next_cursor)


@dataclass(frozen=True, slots=True)
class PageRequest:
    cursor: str | None
    limit: int

    @staticmethod
    def of(cursor: str | None, limit: int | None) -> PageRequest:
        """El servidor acota el tamaño aunque el cliente pida más (decisión del contrato)."""
        bounded = DEFAULT_LIMIT if not limit or limit < 1 else min(limit, MAX_LIMIT)
        return PageRequest(cursor or None, bounded)
