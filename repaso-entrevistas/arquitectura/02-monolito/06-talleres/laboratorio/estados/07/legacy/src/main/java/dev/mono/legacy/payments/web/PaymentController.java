package dev.mono.legacy.payments.web;

import dev.mono.legacy.payments.internal.PaymentService;
import org.springframework.http.ResponseEntity;
import tools.jackson.databind.json.JsonMapper;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

// Taller 06: la ruta es la misma del contrato; el dueño pasa de OrderController a payments
@RestController
public class PaymentController {
    private final PaymentService payments;
    private final JsonMapper json;

    public PaymentController(PaymentService payments, JsonMapper json) {
        this.payments = payments;
        this.json = json;
    }

    @PostMapping("/api/v1/orders/{id}/payment")
    public ResponseEntity<String> pay(@AuthenticationPrincipal Jwt jwt, @RequestHeader("Idempotency-Key") String key,
                                      @PathVariable UUID id) {
        boolean operator = "operator".equals(jwt.getClaimAsString("role"));
        return payments.pay(id, UUID.fromString(jwt.getSubject()), operator, key,
                            outcome -> json.writeValueAsString(PaymentResult.from(outcome))).toResponse();
    }
}
