package dev.mono.legacy.notifications;

import dev.mono.legacy.notifications.internal.Notification;
import dev.mono.legacy.notifications.internal.NotificationRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

// API de notifications: NotifyCustomer. Pedidos ya no escribe la tabla de otro módulo; llama aquí.
// Sigue en la misma transacción que la cancelación: eso lo desarma el taller 08.
@Service
public class Notifications {
    private final NotificationRepository notifications;

    public Notifications(NotificationRepository notifications) {
        this.notifications = notifications;
    }

    public void orderCancelled(UUID orderId, String recipient) {
        Notification n = new Notification();
        n.setId(UUID.randomUUID());
        n.setOrderId(orderId);
        n.setType("ORDER_CANCELLED");
        n.setRecipient(recipient);
        n.setCreatedAt(Instant.now());
        notifications.save(n);
    }
}
