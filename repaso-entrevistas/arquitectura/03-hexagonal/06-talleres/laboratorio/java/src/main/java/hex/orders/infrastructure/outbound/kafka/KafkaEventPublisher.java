package hex.orders.infrastructure.outbound.kafka;

import hex.orders.application.port.out.EventPublisher;
import hex.orders.domain.DomainEvent;
import hex.orders.infrastructure.config.HexProperties;
import hex.orders.infrastructure.messaging.EventJson;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.ExecutionException;

// Taller 09. El adaptador del puerto EventPublisher: un registro por hecho en orders.events, con el
// orderId como clave. La clave decide la partición, y la partición decide el orden: todos los hechos
// de un pedido van a la misma y se consumen en el orden en que se publicaron. Sin clave (keyed=false)
// el productor reparte a ciegas y ese orden desaparece: es la provocación del taller.
@Component
public class KafkaEventPublisher implements EventPublisher {

    private final KafkaTemplate<String, String> kafka;
    private final String topic;
    private final boolean keyed;

    public KafkaEventPublisher(KafkaTemplate<String, String> kafka, HexProperties properties) {
        this.kafka = kafka;
        this.topic = properties.kafka().topic();
        this.keyed = properties.kafka().keyed();
    }

    @Override
    public void publish(DomainEvent event) {
        String key = keyed ? event.orderId().toString() : null;
        try {
            // síncrono a propósito: markPublished solo después de que el broker confirmó (acks=all)
            kafka.send(topic, key, EventJson.record(event)).get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("interrupted while publishing " + event.eventId(), e);
        } catch (ExecutionException e) {
            throw new IllegalStateException("could not publish " + event.eventId(), e.getCause());
        }
    }
}
