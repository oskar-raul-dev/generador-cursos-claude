package dev.mono.legacy.payments.web;

import dev.mono.legacy.payments.internal.PaymentService;

import java.util.UUID;

// operationId: la Idempotency-Key del intento (taller 07)
public record PaymentResult(UUID orderId, String orderStatus, Payment payment) {

    public record Payment(String status, String operationId, String reference) {}

    public static PaymentResult from(PaymentService.Outcome outcome) {
        var p = outcome.payment();
        return new PaymentResult(outcome.order().id(), outcome.order().status(),
                                 new Payment(p.getStatus(), p.getOperationId(), p.getReference()));
    }
}
