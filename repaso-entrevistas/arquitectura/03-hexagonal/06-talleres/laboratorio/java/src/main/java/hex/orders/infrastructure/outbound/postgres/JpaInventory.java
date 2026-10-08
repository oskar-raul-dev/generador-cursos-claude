package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.error.NotFound;
import hex.orders.application.port.out.Inventory;
import hex.orders.domain.InsufficientInventory;
import hex.orders.domain.OrderLine;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

// Existencias y reservas en PostgreSQL. `reserve` descuenta línea a línea con un UPDATE
// condicional; al primer 0 lanza InsufficientInventory y la unidad de trabajo que rodea al caso
// de uso revierte los descuentos anteriores. La atomicidad no está aquí: está en la transacción.
@Component
public class JpaInventory implements Inventory {

    private final InventoryRepository inventory;
    private final ReservationRepository reservations;
    private final Clock clock;

    public JpaInventory(InventoryRepository inventory, ReservationRepository reservations, Clock clock) {
        this.inventory = inventory;
        this.reservations = reservations;
        this.clock = clock;
    }

    @Override
    public Map<String, Integer> availableFor(Collection<String> skus) {
        if (skus.isEmpty()) {
            return Map.of();
        }
        return inventory.findBySkuIn(skus).stream().collect(Collectors.toMap(i -> i.sku, i -> i.available));
    }

    @Override
    public void initialize(String sku, int quantity) {
        var entity = new InventoryEntity();
        entity.sku = sku;
        entity.available = quantity;
        entity.version = 0;
        entity.updatedAt = clock.instant();
        inventory.save(entity);
    }

    @Override
    public void reserve(UUID orderId, List<OrderLine> lines) {
        for (int i = 0; i < lines.size(); i++) {
            var line = lines.get(i);
            int updated = inventory.reserve(line.sku(), line.quantity());
            if (updated == 0) {
                int available = inventory.findById(line.sku()).map(e -> e.available).orElse(0);
                throw new InsufficientInventory(line.sku(), line.quantity(), available, i);
            }
            var reservation = new ReservationEntity();
            reservation.id = UUID.randomUUID();
            reservation.orderId = orderId;
            reservation.sku = line.sku();
            reservation.quantity = line.quantity();
            reservation.status = "RESERVED";
            reservation.createdAt = clock.instant();
            reservation.updatedAt = clock.instant();
            reservations.save(reservation);
        }
    }

    @Override
    public int adjust(String sku, int delta) {
        var entity = inventory.findById(sku).orElseThrow(() -> NotFound.product(sku));
        if (entity.available + delta < 0) {
            throw new InsufficientInventory(sku, -delta, entity.available, -1);
        }
        entity.available += delta;
        entity.version += 1;
        entity.updatedAt = clock.instant();
        inventory.save(entity);
        return entity.available;
    }

    @Override
    public void release(UUID orderId) {
        for (var reservation : reservations.findByOrderIdAndStatus(orderId, "RESERVED")) {
            inventory.release(reservation.sku, reservation.quantity);
            reservation.status = "RELEASED";
            reservation.updatedAt = clock.instant();
            reservations.save(reservation);
        }
    }
}
