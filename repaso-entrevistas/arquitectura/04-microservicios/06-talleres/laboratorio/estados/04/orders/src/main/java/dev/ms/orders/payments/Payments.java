package dev.ms.orders.payments;

import java.math.BigDecimal;
import java.util.UUID;

// El cobro, visto desde orders: "cobra este pedido" y un resultado. Viene del monolito (taller 03);
// en orders solo existe la implementación remota.
public interface Payments {

    /** AUTHORIZED, REJECTED o PENDING (no se sabe si cobró). reference, si el proveedor respondió. */
    record Result(String status, String reference) {}

    /**
     * Cobra el importe bajo la clave de operación del cliente. Lanza PaymentsUnavailable solo si es
     * SEGURO que no se cobró (no se pudo conectar, o el circuit breaker no dejó llamar); cualquier
     * duda se devuelve como PENDING.
     */
    Result authorize(UUID orderId, BigDecimal amount, String operationId);
}
