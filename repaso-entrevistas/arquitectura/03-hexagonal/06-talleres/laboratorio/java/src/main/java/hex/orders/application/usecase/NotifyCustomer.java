package hex.orders.application.usecase;

import hex.orders.application.port.out.Notifier;
import hex.orders.application.port.out.Users;
import hex.orders.domain.DomainEvent;

// La política de notificación, separada del transporte: qué hechos se comunican al cliente y a quién.
// La usan el dispatcher de tabla (taller 03) y el consumidor de Kafka (taller 09); ninguno decide.
public final class NotifyCustomer {

    private final Users users;
    private final Notifier notifier;

    public NotifyCustomer(Users users, Notifier notifier) {
        this.users = users;
        this.notifier = notifier;
    }

    // Devuelve true si el hecho se entregó (o ya estaba entregado); false si no era de los que se comunican.
    public boolean execute(DomainEvent event) {
        return switch (event) {
            case DomainEvent.OrderCancelled e -> {
                String recipient = users.findById(e.customerId()).map(Users.User::email).orElse("unknown");
                notifier.notify(e, recipient);
                yield true;
            }
            case DomainEvent.OrderCreated e -> false;   // el cliente acaba de crearlo: no se le avisa
        };
    }
}
