package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "payments")
public class PaymentEntity {

    @Id
    UUID id;

    @Column(name = "order_id", nullable = false)
    UUID orderId;

    @Column(name = "operation_id", nullable = false, unique = true)
    String operationId;

    @Column(nullable = false)
    String status;

    String reference;

    @Column(nullable = false, precision = 12, scale = 2)
    BigDecimal amount;

    @Column(nullable = false, length = 3)
    String currency;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;
}
