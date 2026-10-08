package dev.mono.legacy.payments.internal;

import dev.mono.legacy.orders.PaymentLookup;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

// payments implementa el puerto que orders declara: la dependencia apunta de payments a orders
@Component
class PaymentLookupAdapter implements PaymentLookup {
    private final PaymentRepository payments;

    PaymentLookupAdapter(PaymentRepository payments) {
        this.payments = payments;
    }

    @Override
    public Optional<PaymentSummary> latestFor(UUID orderId) {
        return payments.findFirstByOrderIdOrderByCreatedAtDesc(orderId)
            .map(p -> new PaymentSummary(p.getStatus(), p.getOperationId(), p.getReference()));
    }
}
