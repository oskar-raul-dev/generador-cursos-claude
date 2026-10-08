package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.port.out.Notifier;
import hex.orders.domain.DomainEvent;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.util.UUID;

// El Notifier de las partes 1–3 "entrega" escribiendo una fila: es lo que /notifications expone.
// Tolera repeticiones: el id de la notificación es el del evento, así que una segunda entrega del
// mismo hecho no crea una segunda fila. El taller 09 lo sustituye por un productor Kafka.
@Component
public class TableNotifier implements Notifier {

    private final NotificationRepository repository;
    private final Clock clock;

    public TableNotifier(NotificationRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public void notify(DomainEvent event, String recipient) {
        if (repository.existsById(event.eventId())) {
            return; // ya entregado: entrega al menos una vez, efecto una sola vez
        }
        var row = new NotificationEntity();
        row.id = event.eventId();
        row.orderId = event.orderId();
        row.type = event.type();
        row.recipient = recipient;
        row.payload = "{\"eventId\":\"" + event.eventId() + "\",\"occurredAt\":\"" + event.occurredAt() + "\"}";
        row.createdAt = clock.instant();
        repository.save(row);
    }
}
