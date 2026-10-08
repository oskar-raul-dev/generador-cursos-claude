package co.coodrosan.lab.inventory;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

// G1: las existencias en su propio almacén. La existencia solo cambia por movimientos (D33).
@RestController
public class StockController {

    record StockLevel(String store, String sku, int quantity, int reorderThreshold) { }

    record MovementRequest(String type, Integer quantity, String reasonCode, String reference) { }

    record StockMovement(String id, String store, String sku, String type, int quantity,
                         String reasonCode, String reference, String createdAt) { }

    record ReasonCode(String code, String description, List<String> appliesTo, boolean active) { }

    // G5: lo que devuelve record(): el identificador y la hora del movimiento.
    record Recorded(String id, String createdAt) { }

    private static final Set<String> TYPES = Set.of("RESTOCK", "ADJUSTMENT", "COUNT");

    private final JdbcTemplate jdbc;

    StockController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private static ResponseEntity<Object> error(HttpStatus status, String code, String message) {
        return ResponseEntity.status(status).body(Map.of("error", code, "message", message));
    }

    StockLevel find(String store, String sku) {
        return query(store, sku, "");
    }

    // G5: la fila de la existencia, bloqueada hasta el final de la transacción. Con Postgres, FOR UPDATE:
    // dos movimientos a la vez sobre el mismo producto esperan su turno en lugar de pisarse (la carrera
    // de la Fase 12). SQLite no lo entiende, y no le hace falta: su pool tiene una sola conexión.
    StockLevel findForUpdate(String store, String sku) {
        return query(store, sku, StoreConfig.postgres() ? " FOR UPDATE" : "");
    }

    private StockLevel query(String store, String sku, String lock) {
        List<StockLevel> rows = jdbc.query(
                "SELECT store, sku, quantity, reorder_threshold FROM stock_levels WHERE store = ? AND sku = ?" + lock,
                (rs, i) -> new StockLevel(rs.getString(1), rs.getString(2), rs.getInt(3), rs.getInt(4)),
                store, sku);
        return rows.isEmpty() ? null : rows.getFirst();
    }

    // Una respuesta de error dentro de una transacción: que no se guarde nada de lo que se alcanzó a escribir.
    private static ResponseEntity<Object> rollback(HttpStatus status, String code, String message) {
        TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
        return error(status, code, message);
    }

    // G5: registra un movimiento con la fila ya bloqueada. Lo usan los movimientos y la venta.
    Recorded record(String storeId, String sku, String type, int delta, String reasonCode, String reference) {
        String createdAt = Instant.now().toString();
        GeneratedKeyHolder key = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            var statement = connection.prepareStatement(
                    "INSERT INTO stock_movements (store, sku, type, quantity, reason_code, reference, created_at) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?)", new String[] {"id"});
            statement.setString(1, storeId);
            statement.setString(2, sku);
            statement.setString(3, type);
            statement.setInt(4, delta);
            statement.setString(5, reasonCode);
            statement.setString(6, reference);
            statement.setString(7, createdAt);
            return statement;
        }, key);
        return new Recorded("MOV-%06d".formatted(key.getKey().longValue()), createdAt);
    }

    @GetMapping("/stock/{storeId}/{sku}")
    public ResponseEntity<Object> stock(@PathVariable String storeId, @PathVariable String sku) {
        StockLevel level = find(storeId, sku);
        return level == null
                ? error(HttpStatus.NOT_FOUND, "not_found", "sin existencias registradas de " + sku + " en " + storeId)
                : ResponseEntity.ok(level);
    }

    // El umbral se edita; la cantidad no se parcha, se mueve: cualquier otro campo es 422.
    @PatchMapping(path = "/stock/{storeId}/{sku}", consumes = {"application/merge-patch+json", "application/json"})
    public ResponseEntity<Object> patch(@PathVariable String storeId, @PathVariable String sku,
                                        @RequestBody Map<String, Object> body) {
        StockLevel level = find(storeId, sku);
        if (level == null) {
            return error(HttpStatus.NOT_FOUND, "not_found", "sin existencias registradas de " + sku + " en " + storeId);
        }
        if (!body.keySet().equals(Set.of("reorderThreshold"))
                || !(body.get("reorderThreshold") instanceof Integer threshold) || threshold < 0) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable",
                    "solo se cambia reorderThreshold, entero no negativo; la cantidad cambia con movimientos");
        }
        jdbc.update("UPDATE stock_levels SET reorder_threshold = ? WHERE store = ? AND sku = ?", threshold, storeId, sku);
        return ResponseEntity.ok(find(storeId, sku));
    }

    @PostMapping("/stock/{storeId}/{sku}/movements")
    @Transactional
    public ResponseEntity<Object> move(@PathVariable String storeId, @PathVariable String sku,
                                       @RequestBody MovementRequest request) {
        if (request.type() == null || !TYPES.contains(request.type()) || request.quantity() == null) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", "type (RESTOCK, ADJUSTMENT o COUNT) y quantity");
        }
        String type = request.type();
        int quantity = request.quantity();
        if (type.equals("RESTOCK") && quantity <= 0 || type.equals("COUNT") && quantity < 0) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", "cantidad inválida para " + type);
        }
        if (type.equals("ADJUSTMENT") && request.reasonCode() == null) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", "un ajuste exige reasonCode");
        }
        if (request.reasonCode() != null) {
            List<String> appliesTo = jdbc.query("SELECT applies_to FROM reason_codes WHERE code = ? AND active = 1",
                    (rs, i) -> rs.getString(1), request.reasonCode());
            if (appliesTo.isEmpty() || !List.of(appliesTo.getFirst().split(",")).contains(type)) {
                return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable",
                        "el código " + request.reasonCode() + " no existe, está inactivo o no aplica a " + type);
            }
        }
        // G5: el primer movimiento crea la existencia en 0 (umbral 0), y la fila se bloquea antes de leerla.
        // Si después el movimiento no procede, rollback() deshace también esta fila.
        jdbc.update("INSERT INTO stock_levels (store, sku, quantity, reorder_threshold) VALUES (?, ?, 0, 0) "
                + "ON CONFLICT (store, sku) DO NOTHING", storeId, sku);
        StockLevel level = findForUpdate(storeId, sku);
        int current = level.quantity();
        // En COUNT, lo que llega es lo contado; lo que se guarda es la diferencia, para que la suma cuadre.
        int delta = type.equals("COUNT") ? quantity - current : quantity;
        int next = current + delta;
        if (next < 0) {
            return rollback(HttpStatus.CONFLICT, "conflict", "el ajuste dejaría la existencia en " + next);
        }
        jdbc.update("UPDATE stock_levels SET quantity = ? WHERE store = ? AND sku = ?", next, storeId, sku);
        Recorded movement = record(storeId, sku, type, delta, request.reasonCode(), request.reference());
        return ResponseEntity.status(HttpStatus.CREATED).body(
                new StockMovement(movement.id(), storeId, sku, type, delta, request.reasonCode(), request.reference(), movement.createdAt()));
    }

    @GetMapping("/reason-codes")
    public List<ReasonCode> reasonCodes() {
        return jdbc.query("SELECT code, description, applies_to, active FROM reason_codes ORDER BY code",
                (rs, i) -> new ReasonCode(rs.getString(1), rs.getString(2),
                        List.of(rs.getString(3).split(",")), rs.getInt(4) == 1));
    }
}
