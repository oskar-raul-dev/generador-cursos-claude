package dev.mono.legacy.idempotency;

import dev.mono.legacy.idempotency.internal.IdempotencyRecord;
import dev.mono.legacy.idempotency.internal.IdempotencyRepository;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.net.URI;
import java.time.Instant;
import java.util.UUID;
import java.util.function.Supplier;

// Taller 07. Una clave se reclama con INSERT ... ON CONFLICT DO NOTHING dentro de la transacción del
// comando: si otra petición con la misma clave está en curso, PostgreSQL hace esperar a esta hasta que
// aquella confirme o deshaga, y entonces decide. Nunca se ejecuta el comando dos veces.
@Service
public class Idempotency {
    private final IdempotencyRepository records;
    private final TransactionTemplate tx;

    public Idempotency(IdempotencyRepository records, TransactionTemplate tx) {
        this.records = records;
        this.tx = tx;
    }

    public sealed interface Claim permits Fresh, Replay, InProgress {}
    public record Fresh() implements Claim {}
    public record Replay(Stored stored) implements Claim {}
    public record InProgress() implements Claim {}

    // la respuesta tal como salió la primera vez: estado, cuerpo JSON y, si hubo, Location
    public record Stored(int status, String body, String location, boolean replay) {
        public ResponseEntity<String> toResponse() {
            if (replay) {
                return ResponseEntity.ok().header("Idempotent-Replay", "true")
                    .contentType(MediaType.APPLICATION_JSON).body(body);
            }
            var builder = ResponseEntity.status(status).contentType(MediaType.APPLICATION_JSON);
            if (location != null) {
                builder.location(URI.create(location));
            }
            return builder.body(body);
        }
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public Claim claim(UUID actor, String key, String fingerprint) {
        if (key.length() < 8 || key.length() > 128) {
            throw new LegacyException(ErrorCode.VALIDATION_FAILED, "Idempotency-Key must have 8 to 128 characters");
        }
        String id = actor + ":" + key;
        if (records.insertIfAbsent(id, actor, key, fingerprint, Instant.now()) == 1) {
            return new Fresh();
        }
        IdempotencyRecord existing = records.findById(id).orElseThrow();
        if (!existing.getFingerprint().equals(fingerprint)) {
            throw new LegacyException(ErrorCode.IDEMPOTENCY_KEY_REUSED, null);
        }
        if (existing.getResponseStatus() == null) {
            return new InProgress();
        }
        return new Replay(new Stored(existing.getResponseStatus(), existing.getResponseBody(), null, true));
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public Stored complete(UUID actor, String key, Stored response) {
        IdempotencyRecord r = records.findById(actor + ":" + key).orElseThrow();
        r.setResponseStatus(response.status());
        r.setResponseBody(response.body());
        return response;
    }

    // Para un comando de una sola transacción (crear un pedido): reclamar, ejecutar y guardar la
    // respuesta se confirman juntos. Si el comando falla, la clave no queda reclamada.
    public Stored execute(UUID actor, String key, String fingerprint, Supplier<Stored> command) {
        return tx.execute(status -> switch (claim(actor, key, fingerprint)) {
            case Replay r -> r.stored();
            case InProgress p -> throw new IllegalStateException("claimed in the same transaction");
            case Fresh f -> complete(actor, key, command.get());
        });
    }
}
