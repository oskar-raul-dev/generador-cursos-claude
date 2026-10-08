package dev.ms.orders.catalog;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Map;

// El catálogo, que se quedó en el monolito: nombre y precio vigentes de cada SKU.
public interface Catalog {
    record Product(String sku, String name, BigDecimal unitPrice) {}

    /** Los productos pedidos que existen; los desconocidos no aparecen en el mapa. */
    Map<String, Product> find(Collection<String> skus);
}
