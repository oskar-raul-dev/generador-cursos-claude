package dev.mono.legacy.notifications.web;

import dev.mono.legacy.notifications.internal.Notification;

import java.time.Instant;
import java.util.UUID;

public record NotificationView(UUID id, UUID orderId, String type, String recipient, Instant createdAt) {
    public static NotificationView from(Notification n) {
        return new NotificationView(n.getId(), n.getOrderId(), n.getType(), n.getRecipient(), n.getCreatedAt());
    }
}
