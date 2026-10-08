package hex.orders.application.port.out;

import hex.orders.domain.DomainEvent;

import java.util.List;
import java.util.UUID;

// La outbox como capacidad: "registra que hay que publicar esto" dentro de la misma transacción que
// el cambio de estado, y "dame lo pendiente / márcalo publicado" para el dispatcher.
public interface PendingPublications {

    void add(DomainEvent event);

    List<DomainEvent> nextBatch(int size);

    void markPublished(UUID eventId);
}
