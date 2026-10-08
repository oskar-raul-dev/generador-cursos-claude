package hex.orders.infrastructure.outbound.payment;

import hex.orders.application.port.out.PaymentGateway;
import hex.orders.domain.Money;
import hex.orders.domain.Payment;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

// El proveedor de pagos de las partes 1–3: una regla determinista (§11 de la guía) que permite
// ejercitar autorizado, rechazado y resultado incierto sin un tercero. El taller 10 lo sustituye
// por un cliente gRPC detrás del mismo puerto.
@Component
@ConditionalOnProperty(name = "hex.payment.provider", havingValue = "deterministic", matchIfMissing = true)
public class DeterministicPaymentGateway implements PaymentGateway {

    @Override
    public Payment authorize(String operationId, Money amount) {
        if (amount.isGreaterThan(Money.usd("1000.00"))) {
            return new Payment(Payment.Status.REJECTED, operationId, null);
        }
        if (amount.hasAmount("666.00")) {
            // el proveedor "no respondió": no sabemos si cobró
            return new Payment(Payment.Status.PENDING, operationId, null);
        }
        return new Payment(Payment.Status.AUTHORIZED, operationId, "gw-" + operationId);
    }
}
