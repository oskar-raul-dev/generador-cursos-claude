package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

@Entity
@Table(name = "idempotency_keys")
public class IdempotencyEntity {

    @EmbeddedId
    IdempotencyId id;

    @Column(name = "request_hash", nullable = false)
    String requestHash;

    @Column(name = "response_status", nullable = false)
    int responseStatus;

    // jsonb en PostgreSQL; aquí se guarda una referencia mínima ({"orderId": ...}), no el cuerpo HTTP
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "response_body", nullable = false, columnDefinition = "jsonb")
    String responseBody;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;
}
