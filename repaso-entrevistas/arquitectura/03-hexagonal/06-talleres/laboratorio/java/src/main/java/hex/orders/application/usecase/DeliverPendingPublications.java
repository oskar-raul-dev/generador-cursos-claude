package hex.orders.application.usecase;

import hex.orders.application.port.out.PendingPublications;
import hex.orders.application.port.out.UnitOfWork;
import hex.orders.domain.DomainEvent;

// Parte 2. La política de entrega: cada hecho pendiente se entrega a su destinatario y se marca.
// Quién lo dispara (un @Scheduled, un hilo, una CLI) es infraestructura. Entrega al menos una vez:
// si el proceso cae entre notify y markPublished, la siguiente ronda repite la entrega, y el
// Notifier tiene que tolerarlo.
public final class DeliverPendingPublications {

    private final PendingPublications pending;
    private final NotifyCustomer notify;
    private final UnitOfWork unitOfWork;

    public DeliverPendingPublications(PendingPublications pending, NotifyCustomer notify, UnitOfWork unitOfWork) {
        this.pending = pending;
        this.notify = notify;
        this.unitOfWork = unitOfWork;
    }

    // Devuelve cuántos hechos entregó en esta ronda.
    public int execute(int batchSize) {
        return unitOfWork.run(() -> {
            var batch = pending.nextBatch(batchSize);
            for (DomainEvent event : batch) {
                notify.execute(event);
                pending.markPublished(event.eventId());
            }
            return batch.size();
        });
    }
}
