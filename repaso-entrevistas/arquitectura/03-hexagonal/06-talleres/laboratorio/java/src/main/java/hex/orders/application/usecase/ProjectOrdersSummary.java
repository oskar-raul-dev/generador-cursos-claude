package hex.orders.application.usecase;

import hex.orders.application.port.out.AppliedEvents;
import hex.orders.application.port.out.OrdersSummary;
import hex.orders.application.port.out.UnitOfWork;
import hex.orders.domain.DomainEvent;

// Taller 09. Aplicar un hecho a la proyección, una sola vez: marcar el eventId y aplicar van en la
// misma transacción, así una segunda entrega (Kafka es al menos una vez) no cuenta dos veces.
public final class ProjectOrdersSummary {

    public static final String PROJECTION = "orders_summary";

    private final AppliedEvents applied;
    private final OrdersSummary summary;
    private final UnitOfWork unitOfWork;

    public ProjectOrdersSummary(AppliedEvents applied, OrdersSummary summary, UnitOfWork unitOfWork) {
        this.applied = applied;
        this.summary = summary;
        this.unitOfWork = unitOfWork;
    }

    // true si el hecho se aplicó ahora; false si ya estaba aplicado (re-entrega).
    public boolean execute(DomainEvent event) {
        return unitOfWork.run(() -> {
            if (!applied.markApplied(PROJECTION, event.eventId())) {
                return false;
            }
            summary.apply(event);
            return true;
        });
    }
}
