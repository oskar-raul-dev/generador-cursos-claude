package hex.orders.application.port.out;

import java.util.Optional;
import java.util.UUID;

// La clave de idempotencia se persiste con el efecto, en la misma transacción: un reintento tras
// una caída encuentra o la clave y el pedido, o ninguno de los dos.
public interface IdempotencyStore {

    record StoredResponse(String requestHash, int status, String body) {}

    Optional<StoredResponse> find(UUID actorId, String key);

    void save(UUID actorId, String key, String requestHash, int status, String body);
}
