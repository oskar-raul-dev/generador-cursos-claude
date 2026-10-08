package hex.orders.application.port.out;

import hex.orders.domain.DomainEvent;
import hex.orders.domain.Money;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

// Taller 09. La proyección "pedidos por cliente": se escribe aplicando hechos y se lee entera.
// No es el agregado Order ni una consulta sobre orders: es otro modelo, derivado y reconstruible.
public interface OrdersSummary {

    record Row(UUID customerId, int ordersCreated, int ordersCancelled, Money openAmount, Instant updatedAt) {}

    void apply(DomainEvent event);

    List<Row> readAll();
}
