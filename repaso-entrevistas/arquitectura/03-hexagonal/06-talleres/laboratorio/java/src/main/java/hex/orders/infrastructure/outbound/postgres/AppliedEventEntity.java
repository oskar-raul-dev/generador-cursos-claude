package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

// Taller 09: (proyección, eventId) ya aplicado. La clave primaria compuesta es la deduplicación.
@Entity
@Table(name = "applied_events")
@IdClass(AppliedEventId.class)
public class AppliedEventEntity {

    @Id
    String projection;

    @Id
    @Column(name = "event_id")
    UUID eventId;

    @Column(name = "applied_at", nullable = false)
    Instant appliedAt;
}
