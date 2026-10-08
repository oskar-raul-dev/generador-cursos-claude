package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

// Una fila por hecho a publicar, en la misma transacción que el cambio de estado (04/03).
@Entity
@Table(name = "outbox")
public class OutboxEntity {

    @Id
    UUID id;

    @Column(name = "aggregate_type", nullable = false)
    String aggregateType;

    @Column(name = "aggregate_id", nullable = false)
    UUID aggregateId;

    @Column(name = "event_type", nullable = false)
    String eventType;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false, columnDefinition = "jsonb")
    String payload;

    @Column(name = "occurred_at", nullable = false)
    Instant occurredAt;

    @Column(name = "published_at")
    Instant publishedAt;

    @Column(nullable = false)
    int attempts;
}
