package dev.mono.legacy.inventory.internal;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

// Taller 09: el stock pasa de products.stock a la tabla inventory con expand/contract. Cada versión
// de la aplicación es un paso (legacy.inventory.step), y cada paso convive con el anterior:
//   expand    lee products.stock, escribe en las dos     (convive con la versión del estado 08)
//   switch    lee inventory,      escribe en las dos     (convive con expand)
//   contract  lee inventory,      escribe solo inventory (convive con switch; después, V5 borra la columna)
@Component
public class StockStore {
    public enum Step { EXPAND, SWITCH, CONTRACT }

    private final JdbcTemplate jdbc;
    private final Step step;

    public StockStore(JdbcTemplate jdbc, @Value("${legacy.inventory.step}") String step) {
        this.jdbc = jdbc;
        this.step = Step.valueOf(step.toUpperCase());
    }

    public Step step() { return step; }

    private boolean readsLegacyColumn() { return step == Step.EXPAND; }

    private boolean writesLegacyColumn() { return step != Step.CONTRACT; }

    // Bloquea el stock del SKU hasta el final de la transacción y lo devuelve (null si no hay fila).
    // Mientras se escriben las dos tablas, se bloquean las dos y siempre en el mismo orden: una versión
    // que bloqueara solo products y otra solo inventory no se excluirían entre sí (sección 🩺).
    public Integer lockAndRead(String sku) {
        Integer legacy = writesLegacyColumn()
            ? single("SELECT stock FROM products WHERE sku = ? FOR NO KEY UPDATE", sku) : null;
        Integer current = single("SELECT stock FROM inventory WHERE sku = ? FOR NO KEY UPDATE", sku);
        return readsLegacyColumn() ? legacy : current;
    }

    public void add(String sku, int delta) {
        if (writesLegacyColumn()) {
            jdbc.update("UPDATE products SET stock = stock + ? WHERE sku = ?", delta, sku);
        }
        jdbc.update("UPDATE inventory SET stock = stock + ? WHERE sku = ?", delta, sku);
    }

    // el alta de un producto: la fila de products ya existe (la escribió JPA sin stock)
    public void initialize(String sku, int stock) {
        if (writesLegacyColumn()) {
            jdbc.update("UPDATE products SET stock = ? WHERE sku = ?", stock, sku);
        }
        jdbc.update("INSERT INTO inventory (sku, stock) VALUES (?, ?)", sku, stock);
    }

    public Map<String, Integer> read(List<String> skus) {
        Map<String, Integer> out = new HashMap<>();
        if (skus.isEmpty()) {
            return out;
        }
        String table = readsLegacyColumn() ? "products" : "inventory";
        String marks = String.join(",", skus.stream().map(s -> "?").toList());
        jdbc.query("SELECT sku, stock FROM " + table + " WHERE sku IN (" + marks + ")",
            rs -> { out.put(rs.getString("sku"), rs.getInt("stock")); }, skus.toArray());
        return out;
    }

    private Integer single(String sql, String sku) {
        var rows = jdbc.queryForList(sql, Integer.class, sku);
        return rows.isEmpty() ? null : rows.getFirst();
    }
}
