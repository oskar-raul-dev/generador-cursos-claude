package dev.mono.legacy.orders.internal;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

public interface OutboxRepository extends JpaRepository<OutboxEvent, UUID> {
    // el más antiguo pendiente que nadie tenga bloqueado: dos despachadores (dos instancias) nunca
    // toman el mismo evento, y ninguno espera al otro
    @Query(value = """
        SELECT * FROM outbox_events WHERE published_at IS NULL
        ORDER BY occurred_at LIMIT 1 FOR UPDATE SKIP LOCKED""", nativeQuery = true)
    Optional<OutboxEvent> lockNextPending();

    @Modifying
    @Query("update OutboxEvent e set e.attempts = e.attempts + 1, e.lastError = :error where e.id = :id")
    int recordFailure(UUID id, String error);
}
