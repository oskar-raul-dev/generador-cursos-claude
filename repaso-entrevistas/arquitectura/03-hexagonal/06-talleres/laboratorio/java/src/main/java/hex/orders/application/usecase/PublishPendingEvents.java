package hex.orders.application.usecase;

import hex.orders.application.port.out.EventPublisher;
import hex.orders.application.port.out.PendingPublications;
import hex.orders.application.port.out.UnitOfWork;
import hex.orders.domain.DomainEvent;

// Taller 09. La outbox sale a un tópico: cada hecho pendiente se publica y se marca. Al menos una vez:
// si el proceso cae entre publish y markPublished, la siguiente ronda vuelve a publicar el mismo
// eventId y los consumidores deduplican. Quien lo dispara (un @Scheduled) es infraestructura.
public final class PublishPendingEvents {

    private final PendingPublications pending;
    private final EventPublisher publisher;
    private final UnitOfWork unitOfWork;

    public PublishPendingEvents(PendingPublications pending, EventPublisher publisher, UnitOfWork unitOfWork) {
        this.pending = pending;
        this.publisher = publisher;
        this.unitOfWork = unitOfWork;
    }

    public int execute(int batchSize) {
        return unitOfWork.run(() -> {
            var batch = pending.nextBatch(batchSize);
            for (DomainEvent event : batch) {
                publisher.publish(event);
                pending.markPublished(event.eventId());
            }
            return batch.size();
        });
    }
}
