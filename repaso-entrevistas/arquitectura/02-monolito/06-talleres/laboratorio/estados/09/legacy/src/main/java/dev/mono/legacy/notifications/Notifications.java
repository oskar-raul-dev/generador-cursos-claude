package dev.mono.legacy.notifications;

import dev.mono.legacy.notifications.internal.Notification;
import dev.mono.legacy.notifications.internal.NotificationRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

// API de notifications: NotifyCustomer. Desde el taller 08 la llama el oyente de OrderCancelled, en la
// transacción del despachador de la outbox, no en la de la cancelación.
@Service
public class Notifications {
    private final NotificationRepository notifications;

    public Notifications(NotificationRepository notifications) {
        this.notifications = notifications;
    }

    public void orderCancelled(UUID eventId, UUID orderId, String recipient) {
        if (notifications.existsById(eventId)) {
            return;                                     // el mismo evento entregado otra vez: ya notificado
        }
        Notification n = new Notification();
        n.setId(eventId);
        n.setOrderId(orderId);
        n.setType("ORDER_CANCELLED");
        n.setRecipient(recipient);
        n.setCreatedAt(Instant.now());
        notifications.save(n);
    }
}
