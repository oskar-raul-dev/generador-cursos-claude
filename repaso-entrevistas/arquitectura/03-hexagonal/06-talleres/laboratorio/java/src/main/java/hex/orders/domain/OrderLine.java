package hex.orders.domain;

import java.util.Objects;

// Foto del catálogo en el momento de la venta: nombre y precio se copian, no se referencian.
public record OrderLine(String sku, String name, int quantity, Money unitPrice) {

    public OrderLine {
        Objects.requireNonNull(sku, "sku");
        Objects.requireNonNull(name, "name");
        Objects.requireNonNull(unitPrice, "unitPrice");
        if (quantity < 1) {
            throw new IllegalArgumentException("quantity must be positive");
        }
    }

    public Money lineTotal() {
        return unitPrice.times(quantity);
    }
}
