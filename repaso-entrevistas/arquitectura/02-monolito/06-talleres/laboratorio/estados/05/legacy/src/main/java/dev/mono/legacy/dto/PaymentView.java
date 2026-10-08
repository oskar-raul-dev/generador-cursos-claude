package dev.mono.legacy.dto;

import dev.mono.legacy.entity.Payment;

// operationId: hasta el taller 07 el legado no tiene clave de operación y devuelve el id interno
public record PaymentView(String status, String operationId, String reference) {
    public static PaymentView from(Payment p) {
        return p == null ? null : new PaymentView(p.getStatus(), p.getId().toString(), p.getReference());
    }
}
