package dev.mono.legacy.notifications.internal;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

// taller 06: lo que el controlador leía directamente del repositorio (ArchitectureTest)
@Service
public class NotificationQueries {
    private final NotificationRepository notifications;

    public NotificationQueries(NotificationRepository notifications) {
        this.notifications = notifications;
    }

    public List<Notification> latestFirst(UUID orderId) {
        return orderId == null ? notifications.findAllByOrderByCreatedAtDesc()
                               : notifications.findByOrderIdOrderByCreatedAtDesc(orderId);
    }
}
