package dev.mono.legacy.orders;

import java.time.Instant;
import java.util.UUID;

// Taller 08: el hecho que publica orders al cancelar. Quien quiera enterarse (notifications) escucha;
// orders ya no sabe quién escucha.
public record OrderCancelled(UUID eventId, UUID orderId, String recipient, Instant occurredAt) {}
