package dev.mono.legacy.dto;

import dev.mono.legacy.entity.Payment;

import java.util.UUID;

public record PaymentResult(UUID orderId, String orderStatus, PaymentView payment) {
    public static PaymentResult from(Payment p) {
        return new PaymentResult(p.getOrder().getId(), p.getOrder().getStatus(), PaymentView.from(p));
    }
}
