package dev.mono.legacy.idempotency.internal;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.time.Instant;
import java.util.UUID;

public interface IdempotencyRepository extends JpaRepository<IdempotencyRecord, String> {
    // 1 si la clave era nueva; 0 si ya existía (y, si otra transacción la tenía sin confirmar, después
    // de esperar a que termine)
    @Modifying
    @Query(value = """
        INSERT INTO idempotency_keys (id, actor_id, idem_key, fingerprint, created_at)
        VALUES (:id, :actor, :key, :fingerprint, :createdAt)
        ON CONFLICT (id) DO NOTHING""", nativeQuery = true)
    int insertIfAbsent(String id, UUID actor, String key, String fingerprint, Instant createdAt);
}
