package dev.ms.monolith.payments;

import java.math.BigDecimal;
import java.util.UUID;

// La costura del cobro (taller 03), como Inventory en el 02: el monolito pide "cobra este pedido"
// y recibe un resultado. Detrás está el PSP llamado directamente (LocalPayments) o el servicio
// payments (RemotePayments); lo decide ms.payments.mode.
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
