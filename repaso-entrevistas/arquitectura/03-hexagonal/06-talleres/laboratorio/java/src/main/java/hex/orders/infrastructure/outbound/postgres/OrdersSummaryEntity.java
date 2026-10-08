package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

// Taller 09: una fila por cliente en la proyección orders_summary.
@Entity
@Table(name = "orders_summary")
public class OrdersSummaryEntity {

    @Id
    @Column(name = "customer_id")
    UUID customerId;

    @Column(name = "orders_created", nullable = false)
    int ordersCreated;

    @Column(name = "orders_cancelled", nullable = false)
    int ordersCancelled;

    @Column(name = "open_amount", nullable = false, precision = 12, scale = 2)
    BigDecimal openAmount;

    @Column(nullable = false)
    String currency;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;
}
