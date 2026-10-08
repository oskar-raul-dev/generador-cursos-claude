"""El agregado: protege que haya líneas y que las transiciones sean las del contrato. No sabe de
HTTP, SQLAlchemy ni del proveedor de pagos. Es una clase ordinaria, no un modelo Pydantic ni ORM."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Literal

from .errors import EmptyOrder, OrderNotCancellable, OrderNotPayable
from .events import DomainEvent, OrderCancelled
from .money import Money

OrderStatus = Literal["CONFIRMED", "PAID", "PAYMENT_REJECTED", "PAYMENT_PENDING", "CANCELLED"]
PaymentStatus = Literal["AUTHORIZED", "REJECTED", "PENDING"]


@dataclass(frozen=True, slots=True)
class Payment:
    """Resultado de un intento de autorización. operation_id es la Idempotency-Key del intento."""

    status: PaymentStatus
    operation_id: str
    reference: str | None


@dataclass(frozen=True, slots=True)
class OrderLine:
    """Foto del catálogo en el momento de la venta."""

    sku: str
    name: str
    quantity: int
    unit_price: Money

    def __post_init__(self) -> None:
        if self.quantity < 1:
            raise ValueError("quantity must be positive")

    def line_total(self) -> Money:
        return self.unit_price.times(self.quantity)


class Order:
    __slots__ = ("id", "customer_id", "lines", "total", "created_at", "_status", "_payment", "version", "_events")

    def __init__(self, id: str, customer_id: str, lines: list[OrderLine], total: Money, created_at: datetime,
                 status: OrderStatus, payment: Payment | None, version: int) -> None:
        self.id, self.customer_id, self.lines, self.total, self.created_at = id, customer_id, tuple(lines), total, created_at
        self._status, self._payment, self.version = status, payment, version
        self._events: list[DomainEvent] = []

    @classmethod
    def place(cls, id: str, customer_id: str, lines: list[OrderLine], now: datetime) -> Order:
        """Crear un pedido: nace CONFIRMED (reservado, sin pagar)."""
        if not lines:
            raise EmptyOrder()
        total = lines[0].line_total()
        for line in lines[1:]:
            total = total.plus(line.line_total())
        return cls(id, customer_id, lines, total, now, "CONFIRMED", None, 0)

    @classmethod
    def reconstitute(cls, id: str, customer_id: str, lines: list[OrderLine], total: Money, created_at: datetime,
                     status: OrderStatus, payment: Payment | None, version: int) -> Order:
        return cls(id, customer_id, lines, total, created_at, status, payment, version)

    @property
    def status(self) -> OrderStatus:
        return self._status

    @property
    def payment(self) -> Payment | None:
        return self._payment

    def is_payable(self) -> bool:
        return self._status in ("CONFIRMED", "PAYMENT_REJECTED")

    def is_cancellable(self) -> bool:
        return self._status in ("CONFIRMED", "PAYMENT_REJECTED", "PAYMENT_PENDING")

    def apply_payment(self, result: Payment) -> None:
        """PENDING no es un rechazo: el pedido queda a la espera y no vuelve a ser pagable."""
        if not self.is_payable():
            raise OrderNotPayable(self._status)
        self._payment = result
        self._status = {"AUTHORIZED": "PAID", "REJECTED": "PAYMENT_REJECTED", "PENDING": "PAYMENT_PENDING"}[result.status]

    def cancel(self, now: datetime, event_id: str) -> bool:
        """Idempotente: la segunda vez no cambia nada ni emite el hecho. True si hubo transición."""
        if self._status == "CANCELLED":
            return False
        if not self.is_cancellable():
            raise OrderNotCancellable(self._status)
        self._status = "CANCELLED"
        self._events.append(OrderCancelled(event_id, self.id, self.customer_id, now))
        return True

    def pull_events(self) -> list[DomainEvent]:
        pulled, self._events = self._events, []
        return pulled
