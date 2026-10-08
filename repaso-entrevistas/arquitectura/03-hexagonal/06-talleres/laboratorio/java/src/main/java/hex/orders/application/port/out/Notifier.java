package hex.orders.application.port.out;

import hex.orders.domain.DomainEvent;

// Entregar un hecho a su destinatario. Correo, tabla, tópico: detalle del adaptador. Se invoca
// después del commit, desde la outbox, y por tanto debe tolerar repeticiones.
public interface Notifier {

    void notify(DomainEvent event, String recipient);
}
