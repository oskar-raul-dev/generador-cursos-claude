package hex.orders.infrastructure.inbound.kafka;

import hex.orders.application.usecase.NotifyCustomer;
import hex.orders.application.usecase.ProjectOrdersSummary;
import hex.orders.domain.DomainEvent;
import hex.orders.infrastructure.config.HexProperties;
import hex.orders.infrastructure.messaging.EventJson;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

// Taller 09. Dos consumidores del mismo tópico en grupos distintos: cada grupo recibe TODOS los
// hechos y avanza sus propios offsets. Son adaptadores de entrada: traducen el registro a un hecho
// del dominio y llaman a un caso de uso; el offset se confirma DESPUÉS del efecto (ack manual).
// Solo existen con hex.events.transport=kafka; con `table` el backend ni intenta conectar.
@Component
@ConditionalOnProperty(name = "hex.events.transport", havingValue = "kafka")
public class OrdersEventsConsumers {

    private static final Logger log = LoggerFactory.getLogger(OrdersEventsConsumers.class);

    private final NotifyCustomer notify;
    private final ProjectOrdersSummary project;
    private final String chaos;

    public OrdersEventsConsumers(NotifyCustomer notify, ProjectOrdersSummary project, HexProperties properties) {
        this.notify = notify;
        this.project = project;
        this.chaos = properties.kafka().chaos();
    }

    // Grupo hex-notifications: el Notifier de siempre (la tabla notifications), ahora alimentado por
    // el tópico. TableNotifier deduplica por eventId, así que una re-entrega no crea otra fila.
    @KafkaListener(topics = "${hex.kafka.topic}", groupId = "hex-notifications")
    public void notifications(ConsumerRecord<String, String> record, Acknowledgment ack) {
        DomainEvent event = EventJson.fromRecord(record.value());
        boolean delivered = notify.execute(event);
        log.info("kafka[notifications] p{} o{} {} {} → {}", record.partition(), record.offset(), event.type(), event.orderId(),
            delivered ? "notified" : "ignored");
        ack.acknowledge();                                   // el offset avanza solo si el efecto ya está en la base
    }

    // Grupo hex-orders-summary: la proyección. markApplied + apply van en una transacción; el ack, después.
    @KafkaListener(topics = "${hex.kafka.topic}", groupId = "hex-orders-summary")
    public void summary(ConsumerRecord<String, String> record, Acknowledgment ack) {
        DomainEvent event = EventJson.fromRecord(record.value());
        boolean applied = project.execute(event);
        log.info("kafka[summary] p{} o{} {} {} → {}", record.partition(), record.offset(), event.type(), event.orderId(),
            applied ? "applied" : "already applied, skipped");
        if (applied && "crash-before-offset-commit".equals(chaos)) {
            // Solo laboratorio: el efecto está confirmado en PostgreSQL y el offset NO. Al reiniciar,
            // Kafka vuelve a entregar desde el último offset confirmado y la deduplicación lo absorbe.
            log.error("kafka[summary] CHAOS crash-before-offset-commit — halting the JVM before ack()");
            Runtime.getRuntime().halt(137);
        }
        ack.acknowledge();
    }
}
