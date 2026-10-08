package dev.ms.orders.overview;

import dev.ms.orders.config.OrdersProperties;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

// El proyector del read model (taller 11). Lee orders.events con SU grupo (orders-overview) y mantiene
// dos tablas con la forma exacta de la pantalla. Las filas por pedido se escriben con operaciones que
// se pueden repetir (insertar si no existe, fijar un estado); el resumen por cliente SUMA, y sumar dos
// veces es contar dos veces. Por eso pasa por el inbox, salvo en la provocación (ms.overview.inbox=false).
@Component
public class OverviewProjector {

    private static final Logger log = LoggerFactory.getLogger(OverviewProjector.class);
    private static final String CONSUMER = "orders-overview";

    private final JdbcClient jdbc;
    private final TransactionTemplate tx;
    private final JsonMapper json;
    private final boolean inbox;

    public OverviewProjector(JdbcClient jdbc, TransactionTemplate tx, JsonMapper json, OrdersProperties props) {
        this.jdbc = jdbc; this.tx = tx; this.json = json; this.inbox = props.overview().inbox();
    }

    @KafkaListener(topics = "orders.events", groupId = CONSUMER)
    public void on(ConsumerRecord<String, String> rec) {
        var ev = json.readTree(rec.value());
        var eventId = UUID.fromString(ev.get("eventId").asString());
        var type = ev.get("type").asString();
        var orderId = UUID.fromString(ev.get("orderId").asString());
        var outcome = tx.execute(s -> {
            if (inbox && jdbc.sql("INSERT INTO processed_messages (consumer, event_id) VALUES (?, ?) ON CONFLICT DO NOTHING")
                    .params(CONSUMER, eventId).update() == 0) {
                return "already applied, skipped";
            }
            switch (type) {
                case "OrderPlaced" -> jdbc.sql("""
                        INSERT INTO order_overview (order_id, customer_id, status, total_amount, currency, placed_at)
                        VALUES (?, ?, 'PLACED', ?, ?, ?) ON CONFLICT (order_id) DO NOTHING""")
                    .params(orderId, UUID.fromString(ev.get("customerId").asString()),
                        new BigDecimal(ev.get("total").get("amount").asString()), ev.get("total").get("currency").asString(),
                        java.sql.Timestamp.from(Instant.parse(ev.get("occurredAt").asString()))).update();
                case "OrderPaid" -> {
                    jdbc.sql("UPDATE order_overview SET status = 'PAID', payment_status = 'AUTHORIZED', updated_at = clock_timestamp() WHERE order_id = ?")
                        .param(orderId).update();
                    jdbc.sql("""
                            INSERT INTO customer_overview (customer_id, paid_orders, paid_amount) VALUES (?, 1, ?)
                            ON CONFLICT (customer_id) DO UPDATE SET paid_orders = customer_overview.paid_orders + 1,
                                                                   paid_amount = customer_overview.paid_amount + EXCLUDED.paid_amount""")
                        .params(UUID.fromString(ev.get("customerId").asString()), new BigDecimal(ev.get("total").get("amount").asString())).update();
                }
                case "OrderCancelled" -> jdbc.sql("UPDATE order_overview SET status = 'CANCELLED', updated_at = clock_timestamp() WHERE order_id = ?")
                    .param(orderId).update();
                default -> { return "ignored"; }
            }
            return "projected";
        });
        log.info("overview p{} o{} {} {} order={} → {}", rec.partition(), rec.offset(), type,
            eventId.toString().substring(0, 8), orderId.toString().substring(0, 8), outcome);
    }
}
