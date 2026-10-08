package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.error.NotFound;
import hex.orders.application.port.out.Orders;
import hex.orders.domain.Order;

import java.util.UUID;

// Un customer solo ve lo suyo; lo ajeno responde "no existe", no "prohibido".
public final class GetOrder {

    private final Orders orders;

    public GetOrder(Orders orders) {
        this.orders = orders;
    }

    public Order execute(Actor actor, UUID orderId) {
        return orders.find(orderId)
            .filter(actor::canSee)
            .orElseThrow(() -> NotFound.order(orderId.toString()));
    }
}
