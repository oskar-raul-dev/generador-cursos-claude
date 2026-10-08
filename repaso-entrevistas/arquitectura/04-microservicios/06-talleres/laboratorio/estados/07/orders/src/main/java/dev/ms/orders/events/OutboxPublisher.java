package dev.ms.orders.events;

import dev.ms.orders.config.OrdersProperties;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.propagation.TextMapGetter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

// El otro lado del outbox: lee lo pendiente, lo envía y lo marca. Tres decisiones:
//  - FOR UPDATE SKIP LOCKED: con varias instancias de orders, cada fila la publica una sola;
//  - send(...).get(): se espera la confirmación del broker ANTES de marcar; sin el get, la marca
//    iría por delante del envío;
//  - la clave es el orderId: todos los hechos de un pedido van a la misma partición, en orden.
// Si el proceso muere entre el envío y la marca, la siguiente ronda reenvía: al menos una vez.
@Component
@ConditionalOnProperty(name = "ms.events.mode", havingValue = "outbox", matchIfMissing = true)
public class OutboxPublisher {

    private static final Logger log = LoggerFactory.getLogger(OutboxPublisher.class);

    record Pending(UUID id, UUID aggregateId, String type, String payload, String traceContext) {}

    // Lee el traceparent guardado en la fila como si fuera un encabezado entrante (taller 07).
    private static final TextMapGetter<Map<String, String>> GETTER = new TextMapGetter<>() {
        @Override public Iterable<String> keys(Map<String, String> carrier) { return carrier.keySet(); }
        @Override public String get(Map<String, String> carrier, String key) { return carrier == null ? null : carrier.get(key); }
    };

    private final JdbcClient jdbc;
    private final KafkaTemplate<String, String> kafka;
    private final String topic;

    public OutboxPublisher(JdbcClient jdbc, KafkaTemplate<String, String> kafka, OrdersProperties props) {
        this.jdbc = jdbc; this.kafka = kafka; this.topic = props.events().topic();
    }

    @Scheduled(fixedDelayString = "${ms.events.poll-ms}")
    @Transactional
    public void publish() {
        var pending = jdbc.sql("""
                SELECT id, aggregate_id, type, payload, trace_context FROM outbox_events
                 WHERE published_at IS NULL ORDER BY occurred_at LIMIT 100
                   FOR UPDATE SKIP LOCKED""")
            .query((rs, n) -> new Pending(rs.getObject(1, UUID.class), rs.getObject(2, UUID.class), rs.getString(3), rs.getString(4), rs.getString(5)))
            .list();
        for (var e : pending) {
            // Taller 07: el envío se hace DENTRO del contexto de la petición original. El agente crea el
            // span de productor como hijo de esa petición y escribe SU traceparent en los encabezados
            // del mensaje; sin esto, el traceparent que viaja es el de esta ronda del planificador.
            try (var scope = parentOf(e).makeCurrent()) {
                kafka.send(topic, e.aggregateId().toString(), e.payload()).get();
            } catch (Exception ex) {
                log.warn("outbox: {} {} not published yet: {}", e.type(), e.id(), ex.getMessage());
                return;                                       // se reintenta en la siguiente ronda, en orden
            }
            jdbc.sql("UPDATE outbox_events SET published_at = clock_timestamp() WHERE id = ?").params(e.id()).update();
        }
    }

    private static Context parentOf(Pending e) {
        if (e.traceContext() == null) {
            return Context.current();
        }
        return GlobalOpenTelemetry.getPropagators().getTextMapPropagator()
            .extract(Context.root(), Map.of("traceparent", e.traceContext()), GETTER);
    }
}
