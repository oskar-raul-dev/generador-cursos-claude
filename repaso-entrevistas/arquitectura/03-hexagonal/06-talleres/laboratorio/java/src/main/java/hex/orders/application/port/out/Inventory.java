package hex.orders.application.port.out;

import hex.orders.domain.InsufficientInventory;
import hex.orders.domain.OrderLine;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;

// Existencias y reservas. `reserve` descuenta todas las líneas o lanza InsufficientInventory; la
// atomicidad la da la unidad de trabajo que rodea al caso de uso, que revierte lo ya descontado.
public interface Inventory {

    Map<String, Integer> availableFor(Collection<String> skus);

    void initialize(String sku, int quantity);

    void reserve(UUID orderId, List<OrderLine> lines) throws InsufficientInventory;

    void release(UUID orderId);

    // Taller 11. Ajusta las existencias en delta (positivo o negativo) y devuelve el nuevo disponible.
    // Lanza InsufficientInventory si el resultado sería negativo y NotFound si el SKU no existe.
    int adjust(String sku, int delta);
}
