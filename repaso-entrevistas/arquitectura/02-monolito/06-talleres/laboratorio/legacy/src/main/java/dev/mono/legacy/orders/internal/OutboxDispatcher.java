package dev.mono.legacy.orders.internal;

import dev.mono.legacy.orders.OrderCancelled;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.json.JsonMapper;

import java.time.Instant;

// Taller 08: entrega los eventos de la outbox. Cada evento, en su propia transacción: bloquearlo,
// publicarlo a los oyentes (que escriben en la misma transacción) y marcarlo entregado. Si un oyente
// falla, todo se deshace, el evento sigue pendiente y se reintenta en la siguiente pasada.
@Component
class OutboxDispatcher {
    private static final Logger log = LoggerFactory.getLogger(OutboxDispatcher.class);
    private static final int MAX_PER_TICK = 50;
    private final OutboxRepository outbox;
    private final ApplicationEventPublisher events;
    private final TransactionTemplate tx;
    private final JsonMapper json;

    OutboxDispatcher(OutboxRepository outbox, ApplicationEventPublisher events, TransactionTemplate tx, JsonMapper json) {
        this.outbox = outbox;
        this.events = events;
        this.tx = tx;
        this.json = json;
    }

    @Scheduled(fixedDelayString = "${legacy.outbox.every-ms:500}")
    public void dispatch() {
        for (int i = 0; i < MAX_PER_TICK; i++) {
            if (!dispatchOne()) {
                return;                                  // nada pendiente, o un fallo: hasta la próxima pasada
            }
        }
    }

    private boolean dispatchOne() {
        var failed = new java.util.concurrent.atomic.AtomicReference<OutboxEvent>();
        try {
            return Boolean.TRUE.equals(tx.execute(status -> {
                var next = outbox.lockNextPending();
                if (next.isEmpty()) {
                    return false;
                }
                OutboxEvent e = next.get();
                failed.set(e);
                events.publishEvent(json.readValue(e.getPayload(), OrderCancelled.class));
                e.setPublishedAt(Instant.now());
                log.info("outbox: {} {} entregado", e.getType(), e.getId());
                return true;
            }));
        } catch (RuntimeException ex) {
            OutboxEvent e = failed.get();
            if (e != null) {
                String error = String.valueOf(ex.getMessage());
                tx.executeWithoutResult(s -> outbox.recordFailure(e.getId(), error.substring(0, Math.min(500, error.length()))));
                log.warn("outbox: {} {} sin entregar (intento {}): {}", e.getType(), e.getId(), e.getAttempts() + 1, error);
            }
            return false;
        }
    }
}
