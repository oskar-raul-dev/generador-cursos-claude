package dev.mono.legacy.orders.web;

import dev.mono.legacy.idempotency.Idempotency;
import dev.mono.legacy.orders.OrderService;
import dev.mono.legacy.orders.PaymentLookup;
import dev.mono.legacy.shared.Page;
import jakarta.validation.Valid;
import tools.jackson.databind.json.JsonMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

// El pago ya no pasa por aquí: /orders/{id}/payment es de payments (misma ruta, otro dueño).
@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {
    private final OrderService orders;
    private final PaymentLookup payments;
    private final Idempotency idempotency;
    private final JsonMapper json;

    public OrderController(OrderService orders, PaymentLookup payments, Idempotency idempotency, JsonMapper json) {
        this.orders = orders;
        this.payments = payments;
        this.idempotency = idempotency;
        this.json = json;
    }

    private static UUID userId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }

    private static boolean isOperator(Jwt jwt) {
        return "operator".equals(jwt.getClaimAsString("role"));
    }

    @GetMapping
    public Page<OrderView> list(@AuthenticationPrincipal Jwt jwt, @RequestParam(required = false) String cursor,
                                @RequestParam(required = false) Integer limit) {
        return Page.slice(orders.list(userId(jwt), isOperator(jwt)), cursor, limit, o -> OrderView.from(o, payments));
    }

    // taller 07: la clave va antes que el cuerpo para que su ausencia se diga primero (400)
    @PostMapping
    public ResponseEntity<String> create(@AuthenticationPrincipal Jwt jwt, @RequestHeader("Idempotency-Key") String key,
                                         @Valid @RequestBody CreateOrderRequest body) {
        UUID actor = userId(jwt);
        return idempotency.execute(actor, key, "POST /api/v1/orders " + body, () -> {
            var created = OrderView.from(orders.create(actor, body.lines()), payments);
            return new Idempotency.Stored(201, json.writeValueAsString(created), "/api/v1/orders/" + created.id(), false);
        }).toResponse();
    }

    @GetMapping("/{id}")
    public OrderView get(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        return OrderView.from(orders.findVisible(id, userId(jwt), isOperator(jwt)), payments);
    }

    @PostMapping("/{id}/cancel")
    public OrderView cancel(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        orders.findVisible(id, userId(jwt), isOperator(jwt));
        return OrderView.from(orders.cancel(id), payments);
    }
}
