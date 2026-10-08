package dev.ms.monolith.inventory;

import dev.ms.monolith.entity.Reservation;
import dev.ms.monolith.repository.InventoryRepository;
import dev.ms.monolith.repository.ReservationRepository;
import dev.ms.monolith.service.Errors;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

// La implementación de siempre, movida detrás de la interfaz sin cambiar su comportamiento:
// las mismas tablas de ms_monolith, con las filas bloqueadas hasta el commit.
@Component
@ConditionalOnProperty(name = "ms.inventory.mode", havingValue = "local", matchIfMissing = true)
public class LocalInventory implements Inventory {

    private final InventoryRepository inventory;
    private final ReservationRepository reservations;

    public LocalInventory(InventoryRepository inventory, ReservationRepository reservations) {
        this.inventory = inventory; this.reservations = reservations;
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, Integer> stockOf(Collection<String> skus) {
        return inventory.findAllById(skus).stream()
            .collect(Collectors.toMap(i -> i.getSku(), i -> i.getAvailable()));
    }

    @Override
    @Transactional
    public void reserve(UUID orderId, List<Line> lines) {
        var items = inventory.lockAll(lines.stream().map(Line::sku).distinct().toList()).stream()
            .collect(Collectors.toMap(i -> i.getSku(), Function.identity()));
        for (int i = 0; i < lines.size(); i++) {
            var line = lines.get(i);
            var item = items.get(line.sku());
            int available = item == null ? 0 : item.getAvailable();
            if (available < line.quantity()) throw new Errors.InsufficientInventory(line.sku(), i, line.quantity(), available);
        }
        for (var line : lines) {
            items.get(line.sku()).take(line.quantity());
            reservations.save(new Reservation(orderId, line.sku(), line.quantity()));
        }
    }

    @Override
    @Transactional
    public void release(UUID orderId) {
        for (var r : reservations.findByOrderIdAndStatus(orderId, "RESERVED")) {
            inventory.findById(r.getSku()).orElseThrow().giveBack(r.getQuantity());
            r.setStatus("RELEASED");
        }
    }

    @Override
    @Transactional
    public void consume(UUID orderId) {
        reservations.findByOrderIdAndStatus(orderId, "RESERVED").forEach(r -> r.setStatus("CONSUMED"));
    }
}
