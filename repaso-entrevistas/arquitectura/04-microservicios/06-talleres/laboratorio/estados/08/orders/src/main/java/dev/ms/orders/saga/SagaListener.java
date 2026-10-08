package dev.ms.orders.saga;

import dev.ms.orders.config.OrdersProperties;
import dev.ms.orders.entity.Order;
import dev.ms.orders.entity.Payment;
import dev.ms.orders.events.OrderEvents;
import dev.ms.orders.repository.OrderRepository;
import dev.ms.orders.repository.PaymentRepository;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

// La parte de orders en la saga coreografiada (taller 08). orders no manda: escucha lo que otros
// hicieron y mueve el estado del pedido. Es una PROYECCIÓN de hechos ajenos, no el dueño de la saga:
// si un hecho no llega, el pedido se queda donde está y nadie lo nota (06/08 §7).
@Component
public class SagaListener {

    private static final Logger log = LoggerFactory.getLogger(SagaListener.class);

    private final OrderRepository orders;
    private final PaymentRepository payments;
    private final OrderEvents events;
    private final JdbcClient jdbc;
    private final TransactionTemplate tx;
    private final JsonMapper json;
    private final boolean retryOnRelease;

    public SagaListener(OrderRepository orders, PaymentRepository payments, OrderEvents events, JdbcClient jdbc,
                        TransactionTemplate tx, JsonMapper json, OrdersProperties props) {
        this.orders = orders; this.payments = payments; this.events = events; this.jdbc = jdbc; this.tx = tx;
        this.json = json; this.retryOnRelease = props.saga().retryOnRelease();
    }

    // El offset se confirma cuando este método vuelve sin excepción (ack-mode record); si lanza, el
    // manejador de errores reintenta y, al final, aparta el mensaje a <topic>.dlq (KafkaErrorConfig).
    @KafkaListener(topics = {"inventory.reservations", "payments.results"}, groupId = "orders")
    public void on(ConsumerRecord<String, String> rec) {
        JsonNode ev = json.readTree(rec.value());
        var eventId = UUID.fromString(ev.get("eventId").asString());
        var orderId = UUID.fromString(ev.get("orderId").asString());
        var type = ev.get("type").asString();
        var outcome = tx.execute(s -> {
            // inbox, en la misma transacción que el cambio de estado
            if (jdbc.sql("INSERT INTO processed_messages (consumer, event_id) VALUES ('orders', ?) ON CONFLICT DO NOTHING")
                    .param(eventId).update() == 0) {
                return "already applied, skipped";
            }
            var order = orders.findForUpdate(orderId).orElseThrow(() -> new IllegalStateException("unknown order " + orderId));
            return react(order, type, ev);
        });
        log.info("{} p{} o{} {} {} order={} → {}", rec.topic(), rec.partition(), rec.offset(), type,
            eventId.toString().substring(0, 8), orderId.toString().substring(0, 8), outcome);
    }

    private String react(Order order, String type, JsonNode ev) {
        return switch (type) {
            case "InventoryReserved" -> move(order, "CONFIRMED", "PENDING");
            case "InventoryReservationFailed" -> move(order, "CANCELLED", "PENDING");
            case "PaymentAuthorized" -> {
                record(order, ev);
                var result = move(order, "PAID", "CONFIRMED", "PENDING");
                if ("PAID".equals(order.getStatus())) events.paid(order);   // OrderPaid a orders.events: las ventas
                yield result;
            }
            case "PaymentRejected" -> {
                record(order, ev);
                yield move(order, "PAYMENT_REJECTED", "CONFIRMED", "PENDING");
            }
            case "InventoryReleased" -> retryOnRelease ? retry(order) : "stock released, nothing to do";
            default -> "ignored";
        };
    }

    // Un cambio solo se aplica desde los estados previstos. Los hechos llegan por DOS topics y entre
    // topics no hay orden: un PaymentAuthorized puede llegar antes que el InventoryReserved que lo causó.
    // Por eso PAID se acepta también desde PENDING, y el InventoryReserved tardío se ignora.
    private static String move(Order order, String to, String... from) {
        var was = order.getStatus();
        if (!List.of(from).contains(was)) return "ignored: order is " + was;
        order.setStatus(to);
        return was + " → " + to;
    }

    // El pago se registra POR SU operationId, que es la clave idempotente hacia el proveedor y se repite
    // en cada intento de la misma compra: si ya existe, se actualiza. Insertarlo a ciegas violaba la
    // unicidad en cuanto el mismo pedido se cobraba dos veces, y cada rechazo acababa en la DLQ (06/08 §9).
    private void record(Order order, JsonNode ev) {
        var p = ev.get("payment");
        var operationId = p.get("operationId").asString();
        var status = p.get("status").asString();
        var reference = p.get("reference").asString();
        payments.findByOperationId(operationId).ifPresentOrElse(
            existing -> existing.resolve(status, reference),
            () -> payments.save(new Payment(order.getId(), operationId, status, reference, new BigDecimal(p.get("amount").asString()))));
    }

    // PROVOCACIÓN (ms.saga.retry-on-release, 06/08 §8): "si liberaron el stock tras un rechazo,
    // reintentamos la compra". Leída aquí parece razonable. Con un pago que el proveedor rechaza
    // siempre, cierra un ciclo que ningún servicio ve entero.
    private String retry(Order order) {
        if (!List.of("PAYMENT_REJECTED", "CONFIRMED").contains(order.getStatus())) return "ignored: order is " + order.getStatus();
        var was = order.getStatus();
        order.setStatus("PENDING");
        events.placedForSaga(order);
        return was + " → PENDING, OrderPlaced again (retry-on-release)";
    }
}
