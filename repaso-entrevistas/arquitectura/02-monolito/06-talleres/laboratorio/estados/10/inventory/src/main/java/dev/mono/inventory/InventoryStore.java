package dev.mono.inventory;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

// El stock, en la tabla inventory de la base compartida. Cada operación es una transacción local de
// ESTE proceso: si mono-legacy deshace la suya después, esta ya está confirmada.
@Component
public class InventoryStore {
    public enum Outcome { RESERVED, NOT_FOUND, INSUFFICIENT, ALREADY_RELEASED }

    public record Result(Outcome outcome, int available) {}

    private final JdbcTemplate jdbc;
    private final String column;

    public InventoryStore(JdbcTemplate jdbc, @Value("${mono.inventory.stock-column}") String column) {
        this.jdbc = jdbc;
        this.column = column;
    }

    @Transactional
    public Result reserve(UUID reservationId, String sku, int quantity) {
        if (reservationId != null) {
            var status = jdbc.queryForList("SELECT status FROM inventory_reservations WHERE id = ?", String.class, reservationId);
            if (!status.isEmpty()) {                     // la misma reserva otra vez: su resultado de entonces
                return new Result("RESERVED".equals(status.getFirst()) ? Outcome.RESERVED : Outcome.ALREADY_RELEASED, -1);
            }
        }
        var rows = jdbc.queryForList("SELECT " + column + " FROM inventory WHERE sku = ? FOR NO KEY UPDATE", Integer.class, sku);
        if (rows.isEmpty()) {
            return new Result(Outcome.NOT_FOUND, 0);
        }
        int available = rows.getFirst();
        if (available < quantity) {
            return new Result(Outcome.INSUFFICIENT, available);
        }
        jdbc.update("UPDATE inventory SET " + column + " = " + column + " - ? WHERE sku = ?", quantity, sku);
        if (reservationId != null) {
            jdbc.update("INSERT INTO inventory_reservations (id, sku, quantity, status) VALUES (?, ?, ?, 'RESERVED')",
                reservationId, sku, quantity);
        }
        return new Result(Outcome.RESERVED, available - quantity);
    }

    // Sin id: suma sin más (la API ingenua). Con id: libera solo si esa reserva existe y sigue viva; si
    // no existe, deja una lápida RELEASED para que una reserva que llegue tarde no se aplique.
    @Transactional
    public void release(UUID reservationId, String sku, int quantity) {
        if (reservationId == null) {
            jdbc.update("UPDATE inventory SET " + column + " = " + column + " + ? WHERE sku = ?", quantity, sku);
            return;
        }
        int tombstone = jdbc.update("""
            INSERT INTO inventory_reservations (id, sku, quantity, status) VALUES (?, ?, ?, 'RELEASED')
            ON CONFLICT (id) DO NOTHING""", reservationId, sku, quantity);
        if (tombstone == 1) {
            return;                                     // nunca se reservó: nada que devolver
        }
        int released = jdbc.update("UPDATE inventory_reservations SET status = 'RELEASED' WHERE id = ? AND status = 'RESERVED'",
            reservationId);
        if (released == 1) {
            jdbc.update("UPDATE inventory SET " + column + " = " + column + " + ? WHERE sku = ?", quantity, sku);
        }
    }

    @Transactional
    public void create(String sku, int stock) {
        jdbc.update("INSERT INTO inventory (sku, " + column + ") VALUES (?, ?)", sku, stock);
    }

    public Map<String, Integer> stock(List<String> skus) {
        Map<String, Integer> out = new LinkedHashMap<>();
        for (String sku : skus) {
            var rows = jdbc.queryForList("SELECT " + column + " FROM inventory WHERE sku = ?", Integer.class, sku);
            if (!rows.isEmpty()) {
                out.put(sku, rows.getFirst());
            }
        }
        return out;
    }
}
