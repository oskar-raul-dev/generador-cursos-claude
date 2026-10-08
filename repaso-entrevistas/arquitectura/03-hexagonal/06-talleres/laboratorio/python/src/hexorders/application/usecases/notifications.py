from __future__ import annotations

from dataclasses import dataclass

from ..actor import Actor
from ..page import Page, PageRequest
from ..ports import Notification, Notifications, Notifier, PendingPublications, UnitOfWork, Users


@dataclass(frozen=True, slots=True)
class ListNotifications:
    """Parte 2. Solo operator: una ventana operativa a lo que entregó el Notifier."""

    notifications: Notifications

    def execute(self, actor: Actor, order_id: str | None, page: PageRequest) -> Page[Notification]:
        actor.require_operator()
        return self.notifications.list(order_id, page)


@dataclass(frozen=True, slots=True)
class DeliverPendingPublications:
    """Parte 2. La política de entrega. Quién lo dispara (un hilo, una CLI) es infraestructura.
    Al menos una vez: si el proceso cae entre notify y mark_published, la siguiente ronda repite
    la entrega y el Notifier debe tolerarlo."""

    pending: PendingPublications
    notifier: Notifier
    users: Users
    unit_of_work: UnitOfWork

    def execute(self, batch_size: int) -> int:
        def work() -> int:
            batch = self.pending.next_batch(batch_size)
            for event in batch:
                user = self.users.find_by_id(event.customer_id)
                self.notifier.notify(event, user.email if user else "unknown")
                self.pending.mark_published(event.event_id)
            return len(batch)

        return self.unit_of_work.run(work)
