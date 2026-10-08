package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.port.out.AppliedEvents;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class JpaAppliedEvents implements AppliedEvents {

    private final AppliedEventRepository repository;

    public JpaAppliedEvents(AppliedEventRepository repository) {
        this.repository = repository;
    }

    @Override
    public boolean markApplied(String projection, UUID eventId) {
        return repository.insertIfAbsent(projection, eventId) == 1;
    }
}
