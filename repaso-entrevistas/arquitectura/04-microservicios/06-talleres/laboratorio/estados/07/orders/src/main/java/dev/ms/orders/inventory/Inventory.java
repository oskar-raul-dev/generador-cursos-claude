package dev.ms.orders.inventory;

import java.util.List;
import java.util.UUID;

// Lo que orders necesita del inventario, en su idioma: reservar, liberar y consumir por pedido.
public interface Inventory {

    record Line(String sku, int quantity) {}

    /** Reserva todas las líneas o ninguna; lanza Errors.InsufficientInventory con el índice de la línea. */
    void reserve(UUID orderId, List<Line> lines);

    /** Devuelve al stock lo reservado para el pedido. Idempotente. */
    void release(UUID orderId);

    /** Marca lo reservado como vendido (pedido pagado). Idempotente. */
    void consume(UUID orderId);
}
