package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.port.out.IdempotencyStore;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.util.Optional;
import java.util.UUID;

// La clave vive en PostgreSQL, en la misma transacción que el efecto: no en memoria del controller.
@Component
public class JpaIdempotencyStore implements IdempotencyStore {

    private final IdempotencyRepository repository;
    private final Clock clock;

    public JpaIdempotencyStore(IdempotencyRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public Optional<StoredResponse> find(UUID actorId, String key) {
        return repository.findById(new IdempotencyId(key, actorId))
            .map(e -> new StoredResponse(e.requestHash, e.responseStatus, unwrap(e.responseBody)));
    }

    @Override
    public void save(UUID actorId, String key, String requestHash, int status, String body) {
        var entity = new IdempotencyEntity();
        entity.id = new IdempotencyId(key, actorId);
        entity.requestHash = requestHash;
        entity.responseStatus = status;
        entity.responseBody = "{\"ref\":\"" + body + "\"}";   // jsonb: referencia mínima al efecto
        entity.createdAt = clock.instant();
        repository.save(entity);
    }

    // jsonb no devuelve el texto que se guardó sino el JSON normalizado ({"ref": "…"}, con espacio):
    // se lee por patrón, no por posición.
    private static final java.util.regex.Pattern REF = java.util.regex.Pattern.compile("\"ref\"\\s*:\\s*\"([^\"]+)\"");

    private static String unwrap(String json) {
        var m = REF.matcher(json);
        if (!m.find()) {
            throw new IllegalStateException("idempotency row without ref: " + json);
        }
        return m.group(1);
    }
}
