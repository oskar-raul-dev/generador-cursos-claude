package dev.ms.monolith.service;

import dev.ms.monolith.entity.Payment;
import dev.ms.monolith.repository.OrderRepository;
import dev.ms.monolith.repository.PaymentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.json.JsonMapper;

import java.util.Map;
import java.util.UUID;

@Service
public class PaymentService {

    public record Result(int status, String body, boolean replay) {}

    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);

    private final OrderRepository orders;
    private final PaymentRepository payments;
    private final OrderService orderService;
    private final PspClient psp;
    private final Idempotency idempotency;
    private final JsonMapper json;

    public PaymentService(OrderRepository orders, PaymentRepository payments, OrderService orderService,
                          PspClient psp, Idempotency idempotency, JsonMapper json) {
        this.orders = orders; this.payments = payments; this.orderService = orderService;
        this.psp = psp; this.idempotency = idempotency; this.json = json;
    }

    // ⚠️ El defecto del monolito, a propósito: la llamada al proveedor ocurre DENTRO de la
    // transacción. Mientras el proveedor piensa, esta petición retiene una conexión del pool (y el
    // bloqueo de la fila del pedido). Con el proveedor lento, el pool se vacía y cae también el
    // catálogo, que no tenía nada que ver (taller 01). El taller 03 lo saca de aquí.
    @Transactional
    public Result pay(Actor actor, UUID orderId, String idempotencyKey) {
        var request = Map.of("orderId", orderId.toString());
        var replay = idempotency.lookup(idempotencyKey, actor, request);
        if (replay.isPresent()) return new Result(replay.get().status(), replay.get().body(), true);

        var order = OrderService.visible(actor, orders.findForUpdate(orderId).orElseThrow(Errors.OrderNotFound::new));
        if (!"CONFIRMED".equals(order.getStatus())) throw new Errors.OrderNotPayable(order.getStatus());

        String status, reference = null;
        try {
            var result = psp.authorize(order.getId(), order.getTotalAmount(), idempotencyKey);
            status = result.status();
            reference = result.reference();
        } catch (PspClient.PspUnavailable e) {
            log.warn("psp did not answer for order {}: {} → PENDING", orderId, e.getMessage());
            status = "PENDING";                        // no sabemos si cobró: NUNCA se convierte en rechazo
        }

        switch (status) {
            case "AUTHORIZED" -> { order.setStatus("PAID"); orderService.consumeReservations(orderId); }
            case "REJECTED" -> { order.setStatus("PAYMENT_REJECTED"); orderService.releaseReservations(orderId); }
            default -> order.setStatus("PAYMENT_PENDING");   // la reserva se queda: el cobro pudo ocurrir
        }
        var payment = payments.save(new Payment(orderId, idempotencyKey, status, reference, order.getTotalAmount()));
        var response = new Views.PaymentResponse(orderId.toString(), order.getStatus(), Views.PaymentView.of(payment));
        idempotency.remember(idempotencyKey, actor, request, 200, response);
        return new Result(200, json.writeValueAsString(response), false);
    }
}
