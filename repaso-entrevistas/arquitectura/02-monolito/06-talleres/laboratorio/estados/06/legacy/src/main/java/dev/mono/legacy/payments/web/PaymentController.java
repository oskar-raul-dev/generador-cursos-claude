package dev.mono.legacy.payments.web;

import dev.mono.legacy.payments.internal.PaymentService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

// Taller 06: la ruta es la misma del contrato; el dueño pasa de OrderController a payments
@RestController
public class PaymentController {
    private final PaymentService payments;

    public PaymentController(PaymentService payments) {
        this.payments = payments;
    }

    @PostMapping("/api/v1/orders/{id}/payment")
    public PaymentResult pay(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        boolean operator = "operator".equals(jwt.getClaimAsString("role"));
        return PaymentResult.from(payments.pay(id, UUID.fromString(jwt.getSubject()), operator));
    }
}
