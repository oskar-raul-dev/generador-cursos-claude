package hex.orders.domain;

import java.util.Objects;

// Resultado de un intento de autorización. `operationId` es la Idempotency-Key del intento: es
// lo que impide cobrar dos veces cuando la respuesta del proveedor se perdió.
public record Payment(Status status, String operationId, String reference) {

    public enum Status { AUTHORIZED, REJECTED, PENDING }

    public Payment {
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(operationId, "operationId");
    }
}
