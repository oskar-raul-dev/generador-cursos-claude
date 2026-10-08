package hex.orders.application.port.out;

import java.util.UUID;

// Taller 09. Memoria durable de qué eventos aplicó cada proyección. `markApplied` devuelve false si
// ya estaba: es la deduplicación que convierte "al menos una vez" en "efecto una sola vez".
public interface AppliedEvents {

    boolean markApplied(String projection, UUID eventId);
}
