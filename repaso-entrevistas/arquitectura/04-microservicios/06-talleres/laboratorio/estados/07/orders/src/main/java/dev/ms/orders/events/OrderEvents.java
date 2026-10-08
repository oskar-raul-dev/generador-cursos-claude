package dev.ms.orders.events;

import dev.ms.orders.config.OrdersProperties;
import dev.ms.orders.entity.Order;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.context.Context;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import tools.jackson.databind.json.JsonMapper;

import java.time.Instant;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

// Los hechos del pedido (taller 06): OrderPlaced, OrderPaid, OrderCancelled. Se llama DENTRO de la
// transacción que cambia el pedido. En modo `outbox` (el del laboratorio) el hecho se inserta en
// outbox_events en esa misma transacción: sale si y solo si el cambio se confirmó. En modo `direct`
// (la provocación) se publica en Kafka DESPUÉS del commit: si el proceso muere entre medias, el
// pedido existe y el hecho no.
@Component
public class OrderEvents {

    private static final Logger log = LoggerFactory.getLogger(OrderEvents.class);

    private final JdbcClient jdbc;
    private final KafkaTemplate<String, String> kafka;
    private final JsonMapper json;
    private final OrdersProperties.Events cfg;

    public OrderEvents(JdbcClient jdbc, KafkaTemplate<String, String> kafka, JsonMapper json, OrdersProperties props) {
        this.jdbc = jdbc; this.kafka = kafka; this.json = json; this.cfg = props.events();
    }

    public void placed(Order o) { record("OrderPlaced", o); }
    public void paid(Order o) { record("OrderPaid", o); }
    public void cancelled(Order o) { record("OrderCancelled", o); }

    private void record(String type, Order o) {
        var eventId = UUID.randomUUID();
        var payload = new LinkedHashMap<String, Object>();
        payload.put("eventId", eventId.toString());
        payload.put("type", type);
        payload.put("version", 1);
        payload.put("occurredAt", Instant.now().toString());
        payload.put("orderId", o.getId().toString());
        payload.put("customerId", o.getCustomerId().toString());
        payload.put("total", Map.of("amount", o.getTotalAmount().toPlainString(), "currency", o.getCurrency()));
        payload.put("lines", o.getLines().stream().map(l -> Map.of("sku", l.getSku(), "quantity", l.getQuantity())).toList());
        var body = json.writeValueAsString(payload);

        if ("direct".equals(cfg.mode())) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override public void afterCommit() { publishDirect(o.getId(), type, body); }
            });
            return;
        }
        jdbc.sql("INSERT INTO outbox_events (id, aggregate_id, type, payload, trace_context) VALUES (?, ?, ?, ?, ?)")
            .params(eventId, o.getId(), type, body, currentTraceparent()).update();
    }

    // Taller 07: el publicador corre en otro hilo y en otra transacción, donde la traza de la petición
    // ya no existe. Por eso el contexto se guarda AQUÍ, mientras la petición sigue en curso, con el
    // mismo formato que viaja por HTTP (W3C traceparent). Sin agente, la API devuelve un no-op y el
    // campo queda vacío.
    private String currentTraceparent() {
        if (!cfg.propagateTrace()) {
            return null;
        }
        var carrier = new HashMap<String, String>();
        GlobalOpenTelemetry.getPropagators().getTextMapPropagator().inject(Context.current(), carrier, Map::put);
        return carrier.get("traceparent");
    }

    private void publishDirect(UUID orderId, String type, String body) {
        if ("crash-before-publish".equals(cfg.chaos())) {
            log.error("CHAOS crash-before-publish: {} for order {} committed, halting before send", type, orderId);
            Runtime.getRuntime().halt(137);
        }
        kafka.send(cfg.topic(), orderId.toString(), body);
    }

}
