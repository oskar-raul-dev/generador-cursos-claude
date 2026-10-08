package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.port.out.OrdersSummary;
import hex.orders.domain.DomainEvent;
import hex.orders.domain.Money;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Clock;
import java.util.List;
import java.util.UUID;

// Taller 09. Aplica cada hecho a la fila de su cliente, con lo que el hecho trae y nada más: la
// proyección es una función del log, y por eso se puede borrar y reconstruir desde el offset 0
// aunque la tabla orders ya no tenga esos pedidos (§9 del taller).
@Component
public class JpaOrdersSummary implements OrdersSummary {

    private final OrdersSummaryRepository repository;
    private final Clock clock;

    public JpaOrdersSummary(OrdersSummaryRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public void apply(DomainEvent event) {
        var row = repository.findById(event.customerId()).orElseGet(() -> {
            var fresh = new OrdersSummaryEntity();
            fresh.customerId = event.customerId();
            fresh.ordersCreated = 0;
            fresh.ordersCancelled = 0;
            fresh.openAmount = BigDecimal.ZERO;
            fresh.currency = "USD";
            return fresh;
        });
        switch (event) {
            case DomainEvent.OrderCreated e -> {
                row.ordersCreated += 1;
                row.openAmount = row.openAmount.add(new BigDecimal(e.total().amountAsText()));
                row.currency = e.total().currency();
            }
            case DomainEvent.OrderCancelled e -> {
                row.ordersCancelled += 1;
                row.openAmount = row.openAmount.subtract(new BigDecimal(e.total().amountAsText()));
            }
        }
        row.updatedAt = clock.instant();
        repository.save(row);
    }

    @Override
    public List<Row> readAll() {
        return repository.findAllByOrderByCustomerIdAsc().stream()
            .map(r -> new Row(r.customerId, r.ordersCreated, r.ordersCancelled,
                Money.of(r.openAmount.setScale(2).toPlainString(), r.currency), r.updatedAt))
            .toList();
    }
}
