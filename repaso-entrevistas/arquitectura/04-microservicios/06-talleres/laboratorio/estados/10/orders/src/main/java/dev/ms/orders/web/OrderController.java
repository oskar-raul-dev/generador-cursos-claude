package dev.ms.orders.web;

import dev.ms.orders.service.NotificationService;
import dev.ms.orders.service.OrderService;
import dev.ms.orders.service.PaymentService;
import dev.ms.orders.service.Views;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.List;
import java.util.UUID;

// Las mismas rutas y la misma forma que tenían en el monolito: la suite v1 no distingue quién responde.
@RestController
public class OrderController {

    static final String PAYLOAD = "x-jwt-payload";

    public record LineDto(@NotNull @Pattern(regexp = "^SKU-[0-9]{3,}$") String sku,
                          @NotNull @Min(1) @Max(1000) Integer quantity) {}
    public record CreateOrderRequest(@NotEmpty @Size(max = 50) List<@Valid LineDto> lines) {}

    private final OrderService orders;
    private final PaymentService payments;
    private final NotificationService notifications;

    public OrderController(OrderService orders, PaymentService payments, NotificationService notifications) {
        this.orders = orders; this.payments = payments; this.notifications = notifications;
    }

    @PostMapping("/api/v1/orders")
    ResponseEntity<String> create(@RequestHeader(name = PAYLOAD, required = false) String payload,
                                  @RequestHeader(name = "Idempotency-Key", required = false) String key,
                                  @Valid @RequestBody CreateOrderRequest request) {
        var lines = request.lines().stream().map(l -> new OrderService.LineRequest(l.sku(), l.quantity())).toList();
        var created = orders.create(ActorResolver.from(payload), lines, key);
        var response = created.replay()
            ? ResponseEntity.ok().header("Idempotent-Replay", "true")
            : ResponseEntity.created(URI.create("/api/v1/orders/" + created.orderId()));
        return response.contentType(MediaType.APPLICATION_JSON).body(created.body());
    }

    @GetMapping("/api/v1/orders")
    Views.Items<Views.OrderView> list(@RequestHeader(name = PAYLOAD, required = false) String payload) {
        return new Views.Items<>(orders.list(ActorResolver.from(payload)));
    }

    @GetMapping("/api/v1/orders/{orderId}")
    Views.OrderView get(@RequestHeader(name = PAYLOAD, required = false) String payload, @PathVariable UUID orderId) {
        return orders.get(ActorResolver.from(payload), orderId);
    }

    @PostMapping("/api/v1/orders/{orderId}/payment")
    ResponseEntity<String> pay(@RequestHeader(name = PAYLOAD, required = false) String payload, @PathVariable UUID orderId,
                               @RequestHeader(name = "Idempotency-Key", required = false) String key) {
        var result = payments.pay(ActorResolver.from(payload), orderId, key);
        var response = ResponseEntity.status(result.status());
        if (result.replay()) response.header("Idempotent-Replay", "true");
        return response.contentType(MediaType.APPLICATION_JSON).body(result.body());
    }

    @PostMapping("/api/v1/orders/{orderId}/cancel")
    Views.OrderView cancel(@RequestHeader(name = PAYLOAD, required = false) String payload, @PathVariable UUID orderId) {
        return orders.cancel(ActorResolver.from(payload), orderId);
    }

    @GetMapping("/api/v1/notifications")
    Views.Items<Views.NotificationView> notifications(@RequestHeader(name = PAYLOAD, required = false) String payload) {
        return new Views.Items<>(notifications.list(ActorResolver.from(payload)));
    }
}
