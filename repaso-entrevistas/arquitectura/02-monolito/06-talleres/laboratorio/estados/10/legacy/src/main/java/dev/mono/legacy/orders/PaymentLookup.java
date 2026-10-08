package dev.mono.legacy.orders;

import java.util.Optional;
import java.util.UUID;

// Puerto que pedidos declara y payments implementa: el GET de un pedido muestra su último pago sin que
// pedidos dependa de payments.
public interface PaymentLookup {
    Optional<PaymentSummary> latestFor(UUID orderId);

    record PaymentSummary(String status, String operationId, String reference) {}
}
