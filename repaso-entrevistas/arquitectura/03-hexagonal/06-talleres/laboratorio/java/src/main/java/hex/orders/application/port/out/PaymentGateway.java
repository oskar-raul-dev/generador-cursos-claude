package hex.orders.application.port.out;

import hex.orders.domain.Money;
import hex.orders.domain.Payment;

// Capacidad: autorizar un cobro. El proveedor, su protocolo y sus códigos son del adaptador. Un
// resultado incierto vuelve como Payment.Status.PENDING, nunca como REJECTED.
public interface PaymentGateway {

    Payment authorize(String operationId, Money amount);
}
