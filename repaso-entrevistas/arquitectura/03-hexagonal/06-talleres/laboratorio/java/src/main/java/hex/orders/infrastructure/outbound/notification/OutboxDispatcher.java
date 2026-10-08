package hex.orders.infrastructure.outbound.notification;

import hex.orders.application.usecase.DeliverPendingPublications;
import hex.orders.application.usecase.PublishPendingEvents;
import hex.orders.infrastructure.config.HexProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

// El disparador de la outbox: cada medio segundo pide a aplicación que despache lo pendiente.
// Es infraestructura pura: no sabe qué es un evento ni a quién se entrega. Desde el taller 09 elige
// la política según hex.events.transport: entregar al Notifier (tabla) o publicar en el tópico.
@Component
public class OutboxDispatcher {

    private static final Logger log = LoggerFactory.getLogger(OutboxDispatcher.class);

    private final DeliverPendingPublications deliver;
    private final PublishPendingEvents publish;
    private final boolean kafka;

    public OutboxDispatcher(DeliverPendingPublications deliver, PublishPendingEvents publish, HexProperties properties) {
        this.deliver = deliver;
        this.publish = publish;
        this.kafka = "kafka".equals(properties.events().transport());
    }

    @Scheduled(fixedDelayString = "${hex.outbox.poll-ms}")
    public void poll() {
        try {
            int delivered = kafka ? publish.execute(50) : deliver.execute(50);
            if (delivered > 0) {
                log.info("outbox: delivered {} event(s)", delivered);
            }
        } catch (RuntimeException e) {
            // la siguiente ronda lo reintenta; una fila envenenada no debe matar el scheduler
            log.warn("outbox: delivery round failed", e);
        }
    }
}
