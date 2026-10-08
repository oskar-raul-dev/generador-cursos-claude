package dev.mono.legacy.controller;

import dev.mono.legacy.entity.Order;
import dev.mono.legacy.service.OrderService;
import dev.mono.legacy.service.PaymentService;
import dev.mono.legacy.util.Json;
import dev.mono.legacy.util.LegacyException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
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

    @GetMapping
    public Object list(@AuthenticationPrincipal Jwt jwt) {
        return orders.list(userId(jwt), isOperator(jwt));
    }

    @PostMapping
    @SuppressWarnings("unchecked")
    public Object create(@AuthenticationPrincipal Jwt jwt, @RequestBody Map<String, Object> body) {
        try {
            return orders.create(userId(jwt), (List<Map<String, Object>>) body.get("lines"));
        } catch (LegacyException e) {
            return Json.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public Object get(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        Order o = orders.findEntity(id);
        if (o == null || (!isOperator(jwt) && !o.getCustomer().getId().equals(userId(jwt)))) {
            return Json.error("Order not found");
        }
        return o;
    }

    @PostMapping("/{id}/payment")
    public Object pay(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        try {
            return payments.pay(id);
        } catch (LegacyException e) {
            return Json.error(e.getMessage());
        }
    }

    @PostMapping("/{id}/cancel")
    public Object cancel(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        Order o = orders.findEntity(id);
        if (o == null) {
            return Json.error("Order not found");
        }
        if ("PAID".equals(o.getStatus())) {                 // la regla vive aquí, no en el servicio
            return Json.error("Paid orders can not be cancelled");
        }
        try {
            return orders.cancel(id);
        } catch (LegacyException e) {
            return Json.error(e.getMessage());
        }
    }
}
