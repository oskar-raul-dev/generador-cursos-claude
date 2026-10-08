package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.error.IdempotencyKeyReused;
import hex.orders.application.error.NotFound;
import hex.orders.application.port.out.IdempotencyStore;
import hex.orders.application.port.out.Orders;
import hex.orders.application.port.out.PaymentGateway;
import hex.orders.application.port.out.Payments;
import hex.orders.application.port.out.UnitOfWork;
import hex.orders.domain.Order;
import hex.orders.domain.OrderNotPayable;
import hex.orders.domain.Payment;

import java.util.UUID;

// Autorizar el pago de un pedido. La llamada al proveedor queda FUERA de la transacción: una
// transacción abierta durante una llamada remota bloquea filas mientras espera a un tercero
// (02/05). Se comprueba y se aplica en dos unidades de trabajo distintas.
public final class AuthorizePayment {

    public record Command(Actor actor, UUID orderId, String idempotencyKey) {}

    public record Result(Order order, Payment payment, boolean replayed) {}

    private final Orders orders;
    private final Payments payments;
    private final PaymentGateway gateway;
    private final IdempotencyStore idempotency;
    private final UnitOfWork unitOfWork;

    public AuthorizePayment(Orders orders, Payments payments, PaymentGateway gateway,
                            IdempotencyStore idempotency, UnitOfWork unitOfWork) {
        this.orders = orders;
        this.payments = payments;
        this.gateway = gateway;
        this.idempotency = idempotency;
        this.unitOfWork = unitOfWork;
    }

    public Result execute(Command command) {
        String requestHash = "payment:" + command.orderId();

        // 1. Comprobar: repetición, existencia, visibilidad y estado pagable.
        Order order = unitOfWork.run(() -> {
            var stored = idempotency.find(command.actor().id(), command.idempotencyKey());
            if (stored.isPresent()) {
                if (!stored.get().requestHash().equals(requestHash)) {
                    throw new IdempotencyKeyReused();
                }
                return null; // señal de repetición; se resuelve abajo
            }
            var found = load(command);
            if (!found.isPayable()) {
                throw new OrderNotPayable(found.status());
            }
            return found;
        });
        if (order == null) {
            var previous = load(command);
            return new Result(previous, previous.payment(), true);
        }

        // 2. Llamar al proveedor sin transacción abierta. La clave del intento es la del cliente y
        //    no se regenera: un reintento con la misma clave es el mismo cobro.
        Payment payment = gateway.authorize(command.idempotencyKey(), order.total());

        // 3. Aplicar el resultado y guardar la clave con el efecto.
        return unitOfWork.run(() -> {
            var current = load(command);
            current.applyPayment(payment);
            orders.save(current);
            payments.record(current.id(), payment, current.total());
            idempotency.save(command.actor().id(), command.idempotencyKey(), requestHash, 200, current.id().toString());
            return new Result(current, payment, false);
        });
    }

    private Order load(Command command) {
        return orders.find(command.orderId())
            .filter(command.actor()::canSee)
            .orElseThrow(() -> NotFound.order(command.orderId().toString()));
    }
}
