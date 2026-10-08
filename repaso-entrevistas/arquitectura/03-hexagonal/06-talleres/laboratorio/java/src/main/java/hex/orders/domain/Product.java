package hex.orders.domain;

import java.util.Objects;

// Catálogo: qué se vende y a qué precio. El stock NO está aquí: vive en el inventario, que es otra
// unidad de consistencia (y en la parte 3, otra base de datos).
public record Product(String sku, String name, Money unitPrice) {

    public Product {
        Objects.requireNonNull(sku, "sku");
        Objects.requireNonNull(name, "name");
        Objects.requireNonNull(unitPrice, "unitPrice");
        if (!sku.matches("^SKU-[0-9]{3,}$")) {
            throw new IllegalArgumentException("invalid sku: " + sku);
        }
    }
}
