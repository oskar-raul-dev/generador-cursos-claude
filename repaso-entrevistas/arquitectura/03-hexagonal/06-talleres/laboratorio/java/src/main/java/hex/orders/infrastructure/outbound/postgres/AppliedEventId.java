package hex.orders.infrastructure.outbound.postgres;

import java.io.Serializable;
import java.util.UUID;

public record AppliedEventId(String projection, UUID eventId) implements Serializable {}
