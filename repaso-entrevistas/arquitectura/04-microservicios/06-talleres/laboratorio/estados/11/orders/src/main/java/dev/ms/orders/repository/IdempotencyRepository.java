package dev.ms.orders.repository;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

// Respuesta guardada por (clave, actor). Con JdbcClient y no con JPA: es una tabla técnica, y el
// cuerpo se guarda tal cual se respondió.
@Repository
public class IdempotencyRepository {

    public record Stored(String requestHash, int status, String body) {}

    private final JdbcClient jdbc;

    public IdempotencyRepository(JdbcClient jdbc) { this.jdbc = jdbc; }

    public Optional<Stored> find(String key, UUID actorId) {
        return jdbc.sql("SELECT request_hash, response_status, response_body FROM idempotency_keys WHERE key = ? AND actor_id = ?")
            .params(key, actorId)
            .query((rs, n) -> new Stored(rs.getString(1), rs.getInt(2), rs.getString(3)))
            .optional();
    }

    public void replaceBody(String key, UUID actorId, String body) {
        jdbc.sql("UPDATE idempotency_keys SET response_body = ? WHERE key = ? AND actor_id = ?")
            .params(body, key, actorId).update();
    }

    public void save(String key, UUID actorId, String requestHash, int status, String body) {
        jdbc.sql("INSERT INTO idempotency_keys (key, actor_id, request_hash, response_status, response_body) VALUES (?, ?, ?, ?, ?)")
            .params(key, actorId, requestHash, status, body)
            .update();
    }
}
