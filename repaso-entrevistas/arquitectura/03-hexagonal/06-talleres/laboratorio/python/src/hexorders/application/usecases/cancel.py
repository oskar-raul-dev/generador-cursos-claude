from __future__ import annotations

from dataclasses import dataclass

from hexorders.domain.order import Order

from ..actor import Actor
from ..ports import Clock, IdGenerator, Inventory, Orders, PendingPublications, UnitOfWork
from .orders import load_visible


@dataclass(frozen=True, slots=True)
class CancelOrder:
    """Parte 2. El agregado decide si puede; aplicación coordina liberar la reserva y dejar el
    hecho en la outbox, todo en la misma transacción. La entrega ocurre después del commit."""

    orders: Orders
    inventory: Inventory
    pending: PendingPublications
    ids: IdGenerator
    clock: Clock
    unit_of_work: UnitOfWork

    def execute(self, actor: Actor, order_id: str) -> Order:
        def work() -> Order:
            order = load_visible(self.orders, actor, order_id)
            if order.cancel(self.clock.now(), self.ids.next()):
                self.inventory.release(order.id)
                self.orders.save(order)
                for event in order.pull_events():
                    self.pending.add(event)
            return order

        return self.unit_of_work.run(work)
