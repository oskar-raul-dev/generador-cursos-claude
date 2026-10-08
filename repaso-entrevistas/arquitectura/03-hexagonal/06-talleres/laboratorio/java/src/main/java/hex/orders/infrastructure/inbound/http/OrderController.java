package hex.orders.infrastructure.inbound.http;

import hex.orders.application.PageRequest;
import hex.orders.application.usecase.AuthorizePayment;
import hex.orders.application.usecase.CancelOrder;
import hex.orders.application.usecase.CreateOrder;
import hex.orders.application.usecase.GetOrder;
import hex.orders.application.usecase.ListOrders;
import hex.orders.infrastructure.inbound.http.ApiDtos.CreateOrderRequest;
import hex.orders.infrastructure.inbound.http.ApiDtos.OrderResponse;
import hex.orders.infrastructure.inbound.http.ApiDtos.PageResponse;
import hex.orders.infrastructure.inbound.http.ApiDtos.PaymentResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.UUID;

// Traduce HTTP a intenciones: DTO → comando, resultado → DTO, y las decisiones que son del
// contrato (201 + Location al crear, 200 + Idempotent-Replay al repetir). Ninguna regla de negocio.
@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    private final CreateOrder createOrder;
    private final GetOrder getOrder;
    private final ListOrders listOrders;
    private final AuthorizePayment authorizePayment;
    private final CancelOrder cancelOrder;
    private final ActorResolver actors;

    public OrderController(CreateOrder createOrder, GetOrder getOrder, ListOrders listOrders,
                           AuthorizePayment authorizePayment, CancelOrder cancelOrder, ActorResolver actors) {
        this.createOrder = createOrder;
        this.getOrder = getOrder;
        this.listOrders = listOrders;
        this.authorizePayment = authorizePayment;
        this.cancelOrder = cancelOrder;
        this.actors = actors;
    }

    @PostMapping
    ResponseEntity<OrderResponse> create(@AuthenticationPrincipal Jwt jwt,
                                         @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
                                         @Valid @RequestBody CreateOrderRequest body) {
        String key = IdempotencyKeys.require(idempotencyKey);
        var result = createOrder.execute(new CreateOrder.Command(
            actors.from(jwt), key, IdempotencyKeys.hash(body.canonical()),
            body.lines().stream().map(l -> new CreateOrder.LineRequest(l.sku(), l.quantity())).toList()));
        var response = OrderResponse.from(result.order());
        if (result.replayed()) {
            return ResponseEntity.ok().header("Idempotent-Replay", "true").body(response);
        }
        return ResponseEntity.created(URI.create("/api/v1/orders/" + response.id())).body(response);
    }

    @GetMapping("/{orderId}")
    OrderResponse get(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID orderId) {
        return OrderResponse.from(getOrder.execute(actors.from(jwt), orderId));
    }

    @GetMapping
    PageResponse<OrderResponse> list(@AuthenticationPrincipal Jwt jwt,
                                     @RequestParam(required = false) String cursor,
                                     @RequestParam(required = false) Integer limit) {
        return PageResponse.from(listOrders.execute(actors.from(jwt), PageRequest.of(cursor, limit)).map(OrderResponse::from));
    }

    @PostMapping("/{orderId}/payment")
    ResponseEntity<PaymentResponse> pay(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID orderId,
                                        @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {
        String key = IdempotencyKeys.require(idempotencyKey);
        var result = authorizePayment.execute(new AuthorizePayment.Command(actors.from(jwt), orderId, key));
        var response = PaymentResponse.from(result.order(), result.payment());
        return result.replayed()
            ? ResponseEntity.ok().header("Idempotent-Replay", "true").body(response)
            : ResponseEntity.ok(response);
    }

    @PostMapping("/{orderId}/cancel")
    OrderResponse cancel(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID orderId) {
        return OrderResponse.from(cancelOrder.execute(actors.from(jwt), orderId));
    }
}
