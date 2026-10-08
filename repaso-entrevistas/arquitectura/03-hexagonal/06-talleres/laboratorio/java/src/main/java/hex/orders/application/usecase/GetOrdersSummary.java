package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.port.out.OrdersSummary;

import java.util.List;

// Taller 09. Solo operator: lee la proyección tal cual está (eventualmente consistente con /orders).
public final class GetOrdersSummary {

    private final OrdersSummary summary;

    public GetOrdersSummary(OrdersSummary summary) {
        this.summary = summary;
    }

    public List<OrdersSummary.Row> execute(Actor actor) {
        actor.requireOperator();
        return summary.readAll();
    }
}
