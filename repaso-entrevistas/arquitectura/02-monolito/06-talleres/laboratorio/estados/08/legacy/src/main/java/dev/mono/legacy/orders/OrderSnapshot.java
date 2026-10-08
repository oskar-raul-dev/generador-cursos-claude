package dev.mono.legacy.orders;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

// Lo que otros módulos pueden leer de un pedido. La entidad Order es interna.
public record OrderSnapshot(UUID id, UUID customerId, String status, BigDecimal total, String currency,
                            Instant createdAt) {}
