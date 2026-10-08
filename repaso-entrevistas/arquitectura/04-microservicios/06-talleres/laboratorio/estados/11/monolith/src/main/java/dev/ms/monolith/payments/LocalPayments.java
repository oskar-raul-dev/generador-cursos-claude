package dev.ms.monolith.payments;

import dev.ms.monolith.service.PspClient;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.UUID;

// El cobro de siempre: el monolito habla directamente con el proveedor.
@Component
@ConditionalOnProperty(name = "ms.payments.mode", havingValue = "local", matchIfMissing = true)
public class LocalPayments implements Payments {
    private final PspClient psp;

    public LocalPayments(PspClient psp) { this.psp = psp; }

    @Override
    public Result authorize(UUID orderId, BigDecimal amount, String operationId) {
        try {
            var r = psp.authorize(orderId, amount, operationId);
            return new Result(r.status(), r.reference());
        } catch (PspClient.PspUnavailable e) {
            return new Result("PENDING", null);        // no sabemos si cobró
        }
    }
}
