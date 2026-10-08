package hex.orders.infrastructure.inbound.http;

// Regla del borde HTTP, no del núcleo: la operación exige la cabecera del contrato.
public final class MissingIdempotencyKey extends RuntimeException {

    public MissingIdempotencyKey() {
        super("Idempotency-Key header is required");
    }
}
