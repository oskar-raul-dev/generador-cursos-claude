package hex.orders.application.port.out;

import hex.orders.application.Page;
import hex.orders.application.PageRequest;

import java.time.Instant;
import java.util.UUID;

// Lectura de lo que el Notifier entregó. Es lo que el contrato expone en /notifications para observar
// la outbox sin broker; el taller 09 lo sustituye por un tópico.
public interface Notifications {

    record Notification(UUID id, UUID orderId, String type, String recipient, Instant createdAt) {}

    Page<Notification> list(UUID orderId, PageRequest page);
}
