package hex.orders.application.port.out;

import hex.orders.domain.DomainEvent;

// Taller 09. Publicar un hecho hacia fuera del sistema. Tópico, cola, webhook: detalle del adaptador.
// Se invoca desde la outbox, después del commit, y por tanto puede repetirse: el consumidor deduplica.
public interface EventPublisher {

    void publish(DomainEvent event);
}
