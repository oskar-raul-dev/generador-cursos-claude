"""Hechos del dominio con identidad propia desde que nacen: la outbox y el consumidor deduplican
por event_id, y nunca se regenera por intento."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True, slots=True)
class OrderCancelled:
    event_id: str
    order_id: str
    customer_id: str
    occurred_at: datetime

    @property
    def type(self) -> str:
        return "ORDER_CANCELLED"


DomainEvent = OrderCancelled
