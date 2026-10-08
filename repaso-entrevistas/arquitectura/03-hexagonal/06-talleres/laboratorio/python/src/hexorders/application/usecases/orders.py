from __future__ import annotations

from dataclasses import dataclass

from hexorders.domain.order import Order, OrderLine

from ..actor import Actor
from ..errors import IdempotencyKeyReused, NotFound
from ..page import Page, PageRequest
from ..ports import Clock, IdempotencyStore, IdGenerator, Inventory, Orders, Products, UnitOfWork


@dataclass(frozen=True, slots=True)
class LineRequest:
    sku: str
    quantity: int


@dataclass(frozen=True, slots=True)
class CreateOrderCommand:
    actor: Actor
    idempotency_key: str
    request_hash: str
    lines: list[LineRequest]


@dataclass(frozen=True, slots=True)
class CreateOrderResult:
    order: Order
    replayed: bool


@dataclass(frozen=True, slots=True)
class CreateOrder:
    """Crear un pedido reservando el inventario de todas sus líneas, o nada. Una transacción rodea
    idempotencia, catálogo, pedido, reserva y clave: si algo falla, todo se revierte."""

    products: Products
    inventory: Inventory
    orders: Orders
    idempotency: IdempotencyStore
    ids: IdGenerator
    clock: Clock
    unit_of_work: UnitOfWork

    def execute(self, command: CreateOrderCommand) -> CreateOrderResult:
        def work() -> CreateOrderResult:
            actor_id = command.actor.id
            stored = self.idempotency.find(actor_id, command.idempotency_key)
            if stored is not None:
                if stored.request_hash != command.request_hash:
                    raise IdempotencyKeyReused()
                previous = self.orders.find(stored.body)
                if previous is None:
                    raise RuntimeError(f"idempotency key points to a missing order {stored.body}")
                return CreateOrderResult(previous, replayed=True)

            # Catálogo primero (404), inventario después (409): un SKU inexistente no deja reservas.
            lines: list[OrderLine] = []
            for line in command.lines:
                product = self.products.find(line.sku)
                if product is None:
                    raise NotFound("PRODUCT", line.sku)
                lines.append(OrderLine(product.sku, product.name, line.quantity, product.unit_price))

            order = Order.place(self.ids.next(), actor_id, lines, self.clock.now())
            self.orders.save(order)                    # primero el pedido: las reservas lo referencian
            self.inventory.reserve(order.id, lines)    # InsufficientInventory → rollback de todo
            self.idempotency.save(actor_id, command.idempotency_key, command.request_hash, 201, order.id)
            return CreateOrderResult(order, replayed=False)

        return self.unit_of_work.run(work)


def load_visible(orders: Orders, actor: Actor, order_id: str) -> Order:
    """Un customer solo ve lo suyo; lo ajeno responde "no existe"."""
    order = orders.find(order_id)
    if order is None or not actor.can_see(order):
        raise NotFound("ORDER", order_id)
    return order


@dataclass(frozen=True, slots=True)
class GetOrder:
    orders: Orders

    def execute(self, actor: Actor, order_id: str) -> Order:
        return load_visible(self.orders, actor, order_id)


@dataclass(frozen=True, slots=True)
class ListOrders:
    orders: Orders

    def execute(self, actor: Actor, page: PageRequest) -> Page[Order]:
        return self.orders.list(None if actor.is_operator() else actor.id, page)
