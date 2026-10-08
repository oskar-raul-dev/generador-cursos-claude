package dev.ms.orders.service;

import dev.ms.orders.entity.Payment;
import dev.ms.orders.inventory.Inventory;
import dev.ms.orders.payments.Payments;
import dev.ms.orders.repository.OrderRepository;
import dev.ms.orders.repository.PaymentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

@Service
public class PaymentService {

    public record Result(int status, String body, boolean replay) {}

    private final OrderRepository orders;
    private final PaymentRepository payments;
    private final Inventory inventory;
    private final Payments gateway;
    private final Idempotency idempotency;
    private final TransactionTemplate tx;
    private final JsonMapper json;

    public PaymentService(OrderRepository orders, PaymentRepository payments, Inventory inventory, Payments gateway,
                          Idempotency idempotency, TransactionTemplate tx, JsonMapper json) {
        this.orders = orders; this.payments = payments; this.inventory = inventory; this.gateway = gateway;
        this.idempotency = idempotency; this.tx = tx; this.json = json;
    }

    // El defecto de 06/01, corregido (taller 03): la llamada al cobro ya NO ocurre dentro de una
    // transacción. Tres pasos:
    //   1. transacción corta: comprobar que el pedido es pagable y leer el importe;
    //   2. sin conexión tomada: cobrar (Payments, local o remoto), por lento que sea;
    //   3. transacción corta: aplicar el resultado y guardar la respuesta idempotente.
    // El precio: entre 1 y 3 el pedido no está bloqueado; una cancelación concurrente puede colarse,
    // y el paso 3 lo comprueba en vez de suponerlo.
    public Result pay(Actor actor, UUID orderId, String idempotencyKey) {
        var request = Map.of("orderId", orderId.toString());
        var replay = tx.execute(s -> idempotency.lookup(idempotencyKey, actor, request));
        if (replay.isPresent()) {
            var stored = json.readValue(replay.get().body(), Views.PaymentResponse.class);
            if (!"PAYMENT_PENDING".equals(stored.orderStatus())) return new Result(replay.get().status(), replay.get().body(), true);
            return resolvePending(actor, orderId, idempotencyKey, replay.get());
        }

        BigDecimal amount = tx.execute(s -> {
            var order = OrderService.visible(actor, orders.findForUpdate(orderId).orElseThrow(Errors.OrderNotFound::new));
            if (!"CONFIRMED".equals(order.getStatus())) throw new Errors.OrderNotPayable(order.getStatus());
            return order.getTotalAmount();
        });

        var result = gateway.authorize(orderId, amount, idempotencyKey);   // PaymentsUnavailable → 503, nada cambió

        var response = tx.execute(s -> {
            var order = orders.findForUpdate(orderId).orElseThrow(Errors.OrderNotFound::new);
            if (!"CONFIRMED".equals(order.getStatus())) throw new Errors.OrderNotPayable(order.getStatus());
            order.setStatus(switch (result.status()) {
                case "AUTHORIZED" -> "PAID";
                case "REJECTED" -> "PAYMENT_REJECTED";
                default -> "PAYMENT_PENDING";          // no sabemos si cobró: NUNCA se convierte en rechazo
            });
            var payment = payments.save(new Payment(orderId, idempotencyKey, result.status(), result.reference(), amount));
            var body = new Views.PaymentResponse(orderId.toString(), order.getStatus(), Views.PaymentView.of(payment));
            idempotency.remember(idempotencyKey, actor, request, 200, body);
            return body;
        });

        // el inventario, después del commit y fuera de la transacción: consume y release son idempotentes
        switch (result.status()) {
            case "AUTHORIZED" -> inventory.consume(orderId);
            case "REJECTED" -> inventory.release(orderId);
            default -> { }                              // la reserva se queda: el cobro pudo ocurrir
        }
        return new Result(200, json.writeValueAsString(response), false);
    }

    // PENDING no es una respuesta final (06/03 §7): la repetición del cliente con la MISMA clave
    // vuelve a preguntar, con esa misma clave, a quien cobra. Si ya hay respuesta firme, el pedido se
    // resuelve y la respuesta guardada se sustituye; si sigue sin haberla, se devuelve la de antes.
    private Result resolvePending(Actor actor, UUID orderId, String key, Idempotency.Replay stored) {
        BigDecimal amount = tx.execute(s -> orders.findById(orderId).orElseThrow(Errors.OrderNotFound::new).getTotalAmount());
        var result = gateway.authorize(orderId, amount, key);
        if ("PENDING".equals(result.status())) return new Result(stored.status(), stored.body(), true);

        var response = tx.execute(s -> {
            var order = orders.findForUpdate(orderId).orElseThrow(Errors.OrderNotFound::new);
            var payment = payments.findByOperationId(key).orElseThrow();
            if ("PAYMENT_PENDING".equals(order.getStatus())) {
                order.setStatus("AUTHORIZED".equals(result.status()) ? "PAID" : "PAYMENT_REJECTED");
                payment.resolve(result.status(), result.reference());
            }
            var body = new Views.PaymentResponse(orderId.toString(), order.getStatus(), Views.PaymentView.of(payment));
            idempotency.resolve(key, actor, body);
            return body;
        });
        if ("AUTHORIZED".equals(result.status())) inventory.consume(orderId); else inventory.release(orderId);
        return new Result(200, json.writeValueAsString(response), true);
    }
}
