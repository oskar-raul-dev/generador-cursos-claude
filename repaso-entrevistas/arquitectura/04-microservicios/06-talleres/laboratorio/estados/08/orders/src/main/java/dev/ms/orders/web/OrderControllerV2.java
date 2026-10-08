package dev.ms.orders.web;

import dev.ms.orders.service.OrderService;
import dev.ms.orders.service.Views;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.UUID;

// Contrato v2 (taller 08): la consistencia eventual se filtra al contrato. El alta responde 202 con el
// pedido en PENDING y un Location; el cliente consulta hasta que la saga lo lleva a un estado final.
@RestController
public class OrderControllerV2 {

    private final OrderService orders;

    public OrderControllerV2(OrderService orders) { this.orders = orders; }

    @PostMapping("/api/v2/orders")
    ResponseEntity<String> create(@RequestHeader(name = OrderController.PAYLOAD, required = false) String payload,
                                  @RequestHeader(name = "Idempotency-Key", required = false) String key,
                                  @Valid @RequestBody OrderController.CreateOrderRequest request) {
        var lines = request.lines().stream().map(l -> new OrderService.LineRequest(l.sku(), l.quantity())).toList();
        var created = orders.createV2(ActorResolver.from(payload), lines, key);
        var response = ResponseEntity.status(HttpStatus.ACCEPTED);
        if (created.replay()) response.header("Idempotent-Replay", "true");
        else response.location(URI.create("/api/v2/orders/" + created.orderId()));
        return response.contentType(MediaType.APPLICATION_JSON).body(created.body());
    }

    @GetMapping("/api/v2/orders/{orderId}")
    Views.OrderView get(@RequestHeader(name = OrderController.PAYLOAD, required = false) String payload, @PathVariable UUID orderId) {
        return orders.get(ActorResolver.from(payload), orderId);
    }
}
