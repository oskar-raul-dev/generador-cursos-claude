package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

// Clave compuesta (clave, actor): la misma Idempotency-Key de dos actores distintos no choca.
@Embeddable
public class IdempotencyId implements Serializable {

    @Column(name = "key", nullable = false)
    String key;

    @Column(name = "actor_id", nullable = false)
    UUID actorId;

    protected IdempotencyId() {}

    IdempotencyId(String key, UUID actorId) {
        this.key = key;
        this.actorId = actorId;
    }

    @Override
    public boolean equals(Object o) {
        return o instanceof IdempotencyId other && key.equals(other.key) && actorId.equals(other.actorId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(key, actorId);
    }
}
