package hex.orders.application.error;

// La misma clave con otro cuerpo: el cliente se equivocó y hay que decírselo (422), no devolverle
// en silencio el resultado anterior.
public final class IdempotencyKeyReused extends ApplicationException {

    public IdempotencyKeyReused() {
        super("Idempotency-Key reused with a different payload");
    }
}
