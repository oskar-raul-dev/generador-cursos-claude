package dev.mono.legacy.payments.web;

import dev.mono.legacy.payments.internal.PaymentService;

import java.util.UUID;

// operationId: hasta el taller 07 el legado no tiene clave de operación y devuelve el id interno
public record PaymentResult(UUID orderId, String orderStatus, Payment payment) {

    public record Payment(String status, String operationId, String reference) {}

    public static PaymentResult from(PaymentService.Outcome outcome) {
        var p = outcome.payment();
        return new PaymentResult(outcome.order().id(), outcome.order().status(),
                                 new Payment(p.getStatus(), p.getId().toString(), p.getReference()));
    }
}
