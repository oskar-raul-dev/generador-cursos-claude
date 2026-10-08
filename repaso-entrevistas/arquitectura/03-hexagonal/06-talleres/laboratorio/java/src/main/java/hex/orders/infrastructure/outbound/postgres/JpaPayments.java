package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.port.out.Payments;
import hex.orders.domain.Money;
import hex.orders.domain.Payment;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.util.UUID;

@Component
public class JpaPayments implements Payments {

    private final PaymentRepository repository;
    private final Clock clock;

    public JpaPayments(PaymentRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public void record(UUID orderId, Payment payment, Money amount) {
        var entity = new PaymentEntity();
        entity.id = UUID.randomUUID();
        entity.orderId = orderId;
        entity.operationId = payment.operationId();
        entity.status = payment.status().name();
        entity.reference = payment.reference();
        entity.amount = amount.amount();
        entity.currency = amount.currency();
        entity.createdAt = clock.instant();
        repository.save(entity);
    }
}
