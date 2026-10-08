package dev.ms.monolith.inventory;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;

// La costura del branch by abstraction (taller 02): todo el monolito habla con el inventario a
// través de esta interfaz. Detrás puede estar la tabla de siempre (LocalInventory) o el servicio
// extraído (RemoteInventory); quién es lo decide ms.inventory.mode, no el código que la usa.
public interface Inventory {

    record Line(String sku, int quantity) {}

    /** Unidades disponibles por SKU. Los SKU desconocidos no aparecen en el mapa. */
    Map<String, Integer> stockOf(Collection<String> skus);

    /** Reserva todas las líneas o ninguna; lanza Errors.InsufficientInventory con el índice de la línea. */
    void reserve(UUID orderId, List<Line> lines);

    /** Devuelve al stock lo reservado para el pedido. Idempotente. */
    void release(UUID orderId);

    /** Marca lo reservado como vendido (pedido pagado). Idempotente. */
    void consume(UUID orderId);
}
