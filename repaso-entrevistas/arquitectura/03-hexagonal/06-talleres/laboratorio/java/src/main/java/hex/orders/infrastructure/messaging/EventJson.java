package hex.orders.infrastructure.messaging;

import hex.orders.domain.DomainEvent;
import hex.orders.domain.Money;

import java.time.Instant;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

// La forma pública de un hecho fuera del proceso: la misma en la outbox (jsonb) y en el tópico.
// Lectura por patrón y no por ObjectMapper: jsonb normaliza el texto y el mensaje no tiene un DTO
// por tipo; el contrato del evento son estas seis claves.
public final class EventJson {

    private EventJson() {}

    public static String payload(DomainEvent event) {
        Money total = switch (event) {
            case DomainEvent.OrderCancelled e -> e.total();
            case DomainEvent.OrderCreated e -> e.total();
        };
        return "{\"orderId\":\"" + event.orderId() + "\",\"customerId\":\"" + event.customerId()
            + "\",\"amount\":\"" + total.amountAsText() + "\",\"currency\":\"" + total.currency() + "\"}";
    }

    // El registro completo que viaja por el tópico: sobre (tipo, id, fecha) + carga.
    public static String record(DomainEvent event) {
        return "{\"eventId\":\"" + event.eventId() + "\",\"type\":\"" + event.type() + "\",\"occurredAt\":\"" + event.occurredAt()
            + "\",\"payload\":" + payload(event) + "}";
    }

    public static DomainEvent fromOutbox(UUID eventId, String type, UUID orderId, String payload, Instant occurredAt) {
        return build(eventId, type, orderId, payload, occurredAt);
    }

    public static DomainEvent fromRecord(String json) {
        return build(UUID.fromString(field(json, "eventId")), field(json, "type"), UUID.fromString(field(json, "orderId")),
            json, Instant.parse(field(json, "occurredAt")));
    }

    private static DomainEvent build(UUID eventId, String type, UUID orderId, String payload, Instant occurredAt) {
        UUID customerId = UUID.fromString(field(payload, "customerId"));
        Money total = Money.of(field(payload, "amount"), field(payload, "currency"));
        return switch (type) {
            case "ORDER_CANCELLED" -> new DomainEvent.OrderCancelled(eventId, orderId, customerId, total, occurredAt);
            case "ORDER_CREATED" -> new DomainEvent.OrderCreated(eventId, orderId, customerId, total, occurredAt);
            default -> throw new IllegalArgumentException("unknown event type: " + type);
        };
    }

    private static String field(String json, String name) {
        Matcher m = Pattern.compile("\"" + name + "\"\\s*:\\s*\"([^\"]+)\"").matcher(json);
        if (!m.find()) {
            throw new IllegalArgumentException("event without " + name + ": " + json);
        }
        return m.group(1);
    }
}
