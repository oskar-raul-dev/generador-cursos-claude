package hex.orders.domain;

import java.time.Instant;
import java.util.UUID;

// Hechos del dominio. Un evento tiene identidad propia (eventId) desde que nace: la outbox y el
// consumidor deduplican con ella, y nunca se regenera por intento.
public sealed interface DomainEvent {

    UUID eventId();

    UUID orderId();

    Instant occurredAt();

    String type();

    UUID customerId();

    // Lleva el total (taller 09): una proyección debe poder reconstruirse SOLO desde el log, sin
    // leer pedidos que quizá ya no existen.
    record OrderCancelled(UUID eventId, UUID orderId, UUID customerId, Money total, Instant occurredAt) implements DomainEvent {
        @Override
        public String type() {
            return "ORDER_CANCELLED";
        }
    }

    // Taller 09: nace con el pedido. Lleva el total para que una proyección no tenga que leer el pedido.
    record OrderCreated(UUID eventId, UUID orderId, UUID customerId, Money total, Instant occurredAt) implements DomainEvent {
        @Override
        public String type() {
            return "ORDER_CREATED";
        }
    }
}
