package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.error.NotFound;
import hex.orders.application.port.out.Inventory;
import hex.orders.application.port.out.Orders;
import hex.orders.application.port.out.PendingPublications;
import hex.orders.application.port.out.UnitOfWork;
import hex.orders.domain.Order;

import java.time.Clock;
import java.util.UUID;

// Parte 2. Cancelar: el agregado decide si puede; aplicación coordina liberar la reserva y dejar
// el hecho en la outbox, todo en la misma transacción. La entrega ocurre después del commit.
public final class CancelOrder {

    private final Orders orders;
    private final Inventory inventory;
    private final PendingPublications pending;
    private final Clock clock;
    private final UnitOfWork unitOfWork;

    public CancelOrder(Orders orders, Inventory inventory, PendingPublications pending, Clock clock, UnitOfWork unitOfWork) {
        this.orders = orders;
        this.inventory = inventory;
        this.pending = pending;
        this.clock = clock;
        this.unitOfWork = unitOfWork;
    }

    public Order execute(Actor actor, UUID orderId) {
        return unitOfWork.run(() -> {
            var order = orders.find(orderId)
                .filter(actor::canSee)
                .orElseThrow(() -> NotFound.order(orderId.toString()));
            boolean changed = order.cancel(clock.instant());
            if (changed) {
                inventory.release(order.id());
                orders.save(order);
                order.pullEvents().forEach(pending::add);
            }
            return order;
        });
    }
}
