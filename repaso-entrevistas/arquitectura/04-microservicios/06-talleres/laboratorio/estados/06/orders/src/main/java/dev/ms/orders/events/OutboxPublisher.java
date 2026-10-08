package dev.ms.orders.events;

import dev.ms.orders.config.OrdersProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

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

    record Pending(UUID id, UUID aggregateId, String type, String payload) {}

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
                SELECT id, aggregate_id, type, payload FROM outbox_events
                 WHERE published_at IS NULL ORDER BY occurred_at LIMIT 100
                   FOR UPDATE SKIP LOCKED""")
            .query((rs, n) -> new Pending(rs.getObject(1, UUID.class), rs.getObject(2, UUID.class), rs.getString(3), rs.getString(4)))
            .list();
        for (var e : pending) {
            try {
                kafka.send(topic, e.aggregateId().toString(), e.payload()).get();
            } catch (Exception ex) {
                log.warn("outbox: {} {} not published yet: {}", e.type(), e.id(), ex.getMessage());
                return;                                       // se reintenta en la siguiente ronda, en orden
            }
            jdbc.sql("UPDATE outbox_events SET published_at = clock_timestamp() WHERE id = ?").params(e.id()).update();
        }
    }
}
