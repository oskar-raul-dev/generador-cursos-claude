package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.application.port.out.Orders;
import hex.orders.domain.Order;

public final class ListOrders {

    private final Orders orders;

    public ListOrders(Orders orders) {
        this.orders = orders;
    }

    public Page<Order> execute(Actor actor, PageRequest page) {
        // operator: todos (customerId null); customer: los suyos
        return orders.list(actor.isOperator() ? null : actor.id(), page);
    }
}
