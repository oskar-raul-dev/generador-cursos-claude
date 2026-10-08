package hex.orders.application.port.out;

import hex.orders.domain.Money;
import hex.orders.domain.Payment;

import java.util.UUID;

// Registro de cada intento de cobro, con su clave de operación única: la auditoría de "qué se
// intentó cobrar y qué respondió el proveedor".
public interface Payments {

    void record(UUID orderId, Payment payment, Money amount);
}
