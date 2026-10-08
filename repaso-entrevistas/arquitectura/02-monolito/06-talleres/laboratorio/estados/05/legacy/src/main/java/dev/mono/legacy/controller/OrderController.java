package dev.mono.legacy.controller;

import dev.mono.legacy.dto.CreateOrderRequest;
import dev.mono.legacy.dto.OrderView;
import dev.mono.legacy.dto.Page;
import dev.mono.legacy.dto.PaymentResult;
import dev.mono.legacy.entity.Order;
import dev.mono.legacy.service.OrderService;
import dev.mono.legacy.service.PaymentService;
import dev.mono.legacy.util.ErrorCode;
import dev.mono.legacy.util.LegacyException;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {
    private final OrderService orders;
    private final PaymentService payments;

    public OrderController(OrderService orders, PaymentService payments) {
        this.orders = orders;
        this.payments = payments;
    }

    private static UUID userId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }

    private static boolean isOperator(Jwt jwt) {
        return "operator".equals(jwt.getClaimAsString("role"));
    }

    // el pedido de otro cliente responde igual que uno inexistente: no se revela que existe
    private Order visible(Jwt jwt, UUID id) {
        Order o = orders.findEntity(id);
        if (o == null || (!isOperator(jwt) && !o.getCustomer().getId().equals(userId(jwt)))) {
            throw new LegacyException(ErrorCode.ORDER_NOT_FOUND, null);
        }
        return o;
    }

    @GetMapping
    public Page<OrderView> list(@AuthenticationPrincipal Jwt jwt, @RequestParam(required = false) String cursor,
                                @RequestParam(required = false) Integer limit) {
        return Page.slice(orders.list(userId(jwt), isOperator(jwt)), cursor, limit, OrderView::from);
    }

    @PostMapping
    public ResponseEntity<OrderView> create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody CreateOrderRequest body) {
        var created = OrderView.from(orders.create(userId(jwt), body.lines()));
        return ResponseEntity.created(URI.create("/api/v1/orders/" + created.id())).body(created);
    }

    @GetMapping("/{id}")
    public OrderView get(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        return OrderView.from(visible(jwt, id));
    }

    @PostMapping("/{id}/payment")
    public PaymentResult pay(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        visible(jwt, id);
        return PaymentResult.from(payments.pay(id));
    }

    @PostMapping("/{id}/cancel")
    public OrderView cancel(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        Order o = visible(jwt, id);
        if ("PAID".equals(o.getStatus())) {                 // la regla sigue viviendo aquí (taller 06)
            throw new LegacyException(ErrorCode.ORDER_NOT_CANCELLABLE, "order is PAID");
        }
        return OrderView.from(orders.cancel(id));
    }
}
