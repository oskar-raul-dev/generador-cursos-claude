from __future__ import annotations

from dataclasses import dataclass

from hexorders.domain.errors import OrderNotPayable
from hexorders.domain.order import Order, Payment

from ..actor import Actor
from ..errors import IdempotencyKeyReused
from ..ports import IdempotencyStore, Orders, PaymentGateway, Payments, UnitOfWork
from .orders import load_visible


@dataclass(frozen=True, slots=True)
class AuthorizePaymentResult:
    order: Order
    payment: Payment
    replayed: bool


@dataclass(frozen=True, slots=True)
class AuthorizePayment:
    """La llamada al proveedor queda FUERA de la transacción: una transacción abierta durante una
    llamada remota bloquea filas mientras espera a un tercero. Dos unidades de trabajo."""

    orders: Orders
    payments: Payments
    gateway: PaymentGateway
    idempotency: IdempotencyStore
    unit_of_work: UnitOfWork

    def execute(self, actor: Actor, order_id: str, idempotency_key: str) -> AuthorizePaymentResult:
        request_hash = f"payment:{order_id}"

        # 1. Comprobar: repetición, existencia, visibilidad y estado pagable.
        def check() -> Order | None:
            stored = self.idempotency.find(actor.id, idempotency_key)
            if stored is not None:
                if stored.request_hash != request_hash:
                    raise IdempotencyKeyReused()
                return None  # repetición: se resuelve abajo
            found = load_visible(self.orders, actor, order_id)
            if not found.is_payable():
                raise OrderNotPayable(found.status)
            return found

        order = self.unit_of_work.run(check)
        if order is None:
            previous = load_visible(self.orders, actor, order_id)
            assert previous.payment is not None
            return AuthorizePaymentResult(previous, previous.payment, replayed=True)

        # 2. Proveedor, sin transacción abierta. La clave del intento es la del cliente y no se regenera.
        payment = self.gateway.authorize(idempotency_key, order.total)

        # 3. Aplicar el resultado y guardar la clave con el efecto.
        def apply() -> AuthorizePaymentResult:
            current = load_visible(self.orders, actor, order_id)
            current.apply_payment(payment)
            self.orders.save(current)
            self.payments.record(current.id, payment, current.total)
            self.idempotency.save(actor.id, idempotency_key, request_hash, 200, current.id)
            return AuthorizePaymentResult(current, payment, replayed=False)

        return self.unit_of_work.run(apply)
