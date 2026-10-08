package hex.orders.infrastructure.outbound.postgres;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface AppliedEventRepository extends JpaRepository<AppliedEventEntity, AppliedEventId> {

    // Un INSERT que no falla si ya existe y dice cuántas filas escribió: 1 la primera vez, 0 después.
    // Es atómico frente a dos consumidores aplicando el mismo hecho a la vez.
    @Modifying
    @Query(value = "INSERT INTO applied_events (projection, event_id, applied_at) VALUES (:projection, :eventId, now()) ON CONFLICT DO NOTHING", nativeQuery = true)
    int insertIfAbsent(@Param("projection") String projection, @Param("eventId") UUID eventId);
}
