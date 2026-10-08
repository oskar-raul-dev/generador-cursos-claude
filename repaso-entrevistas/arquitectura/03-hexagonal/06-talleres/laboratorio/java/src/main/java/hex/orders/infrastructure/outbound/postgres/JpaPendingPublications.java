package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.port.out.PendingPublications;
import hex.orders.domain.DomainEvent;
import hex.orders.infrastructure.messaging.EventJson;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

// La outbox en PostgreSQL. `add` se llama dentro de la transacción del caso de uso; `nextBatch` y
// `markPublished` desde la ronda del dispatcher.
@Component
public class JpaPendingPublications implements PendingPublications {

    private final OutboxRepository repository;
    private final Clock clock;

    public JpaPendingPublications(OutboxRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public void add(DomainEvent event) {
        var row = new OutboxEntity();
        row.id = event.eventId();
        row.aggregateType = "Order";
        row.aggregateId = event.orderId();
        row.eventType = event.type();
        row.payload = EventJson.payload(event);
        row.occurredAt = event.occurredAt();
        row.attempts = 0;
        repository.save(row);
    }

    @Override
    public List<DomainEvent> nextBatch(int size) {
        return repository.findByPublishedAtIsNullOrderByOccurredAtAsc(Pageable.ofSize(size)).stream()
            .map(row -> {
                row.attempts += 1;
                return EventJson.fromOutbox(row.id, row.eventType, row.aggregateId, row.payload, row.occurredAt);
            })
            .toList();
    }

    @Override
    public void markPublished(UUID eventId) {
        repository.findById(eventId).ifPresent(row -> {
            row.publishedAt = Instant.now(clock);
            repository.save(row);
        });
    }
}
