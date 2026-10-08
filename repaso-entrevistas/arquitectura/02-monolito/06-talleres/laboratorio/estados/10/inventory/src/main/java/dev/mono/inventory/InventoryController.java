package dev.mono.inventory;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

// API interna de mono-inventory. Sin autenticación: solo la llama mono-legacy, en la misma máquina
// (en un despliegue real, red privada y credenciales de servicio). No forma parte de contrato/openapi.yaml.
@RestController
@RequestMapping("/internal")
public class InventoryController {
    private final InventoryStore store;

    public InventoryController(InventoryStore store) {
        this.store = store;
    }

    public record Reservation(UUID reservationId, String sku, int quantity) {}

    public record Item(String sku, int stock) {}

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");
    }

    @PostMapping("/reservations")
    public ResponseEntity<Map<String, Object>> reserve(@RequestBody Reservation r) {
        var result = store.reserve(r.reservationId(), r.sku(), r.quantity());
        return switch (result.outcome()) {
            case RESERVED -> ResponseEntity.ok(Map.of("sku", r.sku(), "quantity", r.quantity()));
            case NOT_FOUND -> ResponseEntity.status(404).body(Map.of("code", "PRODUCT_NOT_FOUND"));
            case INSUFFICIENT -> ResponseEntity.status(409).body(Map.of("code", "INSUFFICIENT_INVENTORY",
                "available", result.available()));
            case ALREADY_RELEASED -> ResponseEntity.status(409).body(Map.of("code", "RESERVATION_RELEASED"));
        };
    }

    @PostMapping("/releases")
    public ResponseEntity<Void> release(@RequestBody Reservation r) {
        store.release(r.reservationId(), r.sku(), r.quantity());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/items")
    public ResponseEntity<Void> create(@RequestBody Item item) {
        store.create(item.sku(), item.stock());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/stock")
    public Map<String, Integer> stock(@RequestParam List<String> sku) {
        return store.stock(sku);
    }
}
