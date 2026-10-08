package dev.mono.legacy.orders.web;

import dev.mono.legacy.orders.OrderService;
import dev.mono.legacy.orders.PaymentLookup;
import dev.mono.legacy.shared.Page;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.UUID;

// El pago ya no pasa por aquí: /orders/{id}/payment es de payments (misma ruta, otro dueño).
@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {
    private final OrderService orders;
    private final PaymentLookup payments;

    public OrderController(OrderService orders, PaymentLookup payments) {
        this.orders = orders;
        this.payments = payments;
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

    @PostMapping
    public ResponseEntity<OrderView> create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody CreateOrderRequest body) {
        var created = OrderView.from(orders.create(userId(jwt), body.lines()), payments);
        return ResponseEntity.created(URI.create("/api/v1/orders/" + created.id())).body(created);
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
