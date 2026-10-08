"""Los puertos de salida como typing.Protocol: contratos estructurales para el type checker, sin
herencia. Un adaptador los satisface por tener los métodos; nada lo declara. Es lo que dice el
capítulo 05/05, y lo que en runtime NO se comprueba: el contrato lo prueban las pruebas."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Protocol

from hexorders.domain.events import DomainEvent
from hexorders.domain.money import Money
from hexorders.domain.order import Order, OrderLine, Payment
from hexorders.domain.product import Product

from .actor import Role
from .page import Page, PageRequest


@dataclass(frozen=True, slots=True)
class User:
    id: str
    email: str
    password_hash: str
    role: Role


class Users(Protocol):
    def find_by_email(self, email: str) -> User | None: ...
    def find_by_id(self, id: str) -> User | None: ...


class PasswordHasher(Protocol):
    def matches(self, raw_password: str, hash: str) -> bool: ...


@dataclass(frozen=True, slots=True)
class IssuedToken:
    value: str
    token_id: str
    expires_at: datetime
    expires_in_seconds: int


class TokenIssuer(Protocol):
    def issue(self, user: User) -> IssuedToken: ...


class TokenRevocationStore(Protocol):
    def revoke(self, token_id: str, ttl: timedelta) -> None: ...
    def is_revoked(self, token_id: str) -> bool: ...


class Products(Protocol):
    """El catálogo. Ni SQLAlchemy ni pymongo asoman: la parte 3 cambia la implementación y nada más."""

    def find(self, sku: str) -> Product | None: ...
    def exists(self, sku: str) -> bool: ...
    def list(self, page: PageRequest) -> Page[Product]: ...
    def save(self, product: Product) -> None: ...


class Inventory(Protocol):
    """reserve descuenta todas las líneas o lanza InsufficientInventory; la atomicidad la da la
    unidad de trabajo que rodea al caso de uso."""

    def available_for(self, skus: list[str]) -> dict[str, int]: ...
    def initialize(self, sku: str, quantity: int) -> None: ...
    def reserve(self, order_id: str, lines: list[OrderLine]) -> None: ...
    def release(self, order_id: str) -> None: ...


class Orders(Protocol):
    def find(self, id: str) -> Order | None: ...
    def save(self, order: Order) -> None: ...
    def list(self, customer_id: str | None, page: PageRequest) -> Page[Order]: ...


class PaymentGateway(Protocol):
    def authorize(self, operation_id: str, amount: Money) -> Payment: ...


class Payments(Protocol):
    def record(self, order_id: str, payment: Payment, amount: Money) -> None: ...


@dataclass(frozen=True, slots=True)
class StoredResponse:
    request_hash: str
    status: int
    body: str


class IdempotencyStore(Protocol):
    """La clave se persiste con el efecto, en la misma transacción."""

    def find(self, actor_id: str, key: str) -> StoredResponse | None: ...
    def save(self, actor_id: str, key: str, request_hash: str, status: int, body: str) -> None: ...


class PendingPublications(Protocol):
    def add(self, event: DomainEvent) -> None: ...
    def next_batch(self, size: int) -> list[DomainEvent]: ...
    def mark_published(self, event_id: str) -> None: ...


class Notifier(Protocol):
    def notify(self, event: DomainEvent, recipient: str) -> None: ...


@dataclass(frozen=True, slots=True)
class Notification:
    id: str
    order_id: str
    type: str
    recipient: str
    created_at: datetime


class Notifications(Protocol):
    def list(self, order_id: str | None, page: PageRequest) -> Page[Notification]: ...


class UnitOfWork(Protocol):
    """El límite transaccional como capacidad: "ejecuta esto y confirma todo o nada"."""

    def run[T](self, work: Callable[[], T]) -> T: ...


class IdGenerator(Protocol):
    def next(self) -> str: ...


class Clock(Protocol):
    def now(self) -> datetime: ...
