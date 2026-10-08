package hex.orders.application.usecase;

import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.application.port.out.Inventory;
import hex.orders.application.port.out.Products;
import hex.orders.domain.Product;

import java.util.Map;

// El catálogo con su stock. Son dos puertos porque son dos unidades de consistencia (y, desde la
// parte 3, dos bases): la composición ocurre aquí, en aplicación, no con un JOIN.
public final class ListProducts {

    public record ProductWithStock(Product product, int stock) {}

    private final Products products;
    private final Inventory inventory;

    public ListProducts(Products products, Inventory inventory) {
        this.products = products;
        this.inventory = inventory;
    }

    public Page<ProductWithStock> execute(PageRequest page) {
        Page<Product> catalog = products.list(page);
        Map<String, Integer> stock = inventory.availableFor(catalog.items().stream().map(Product::sku).toList());
        return catalog.map(p -> new ProductWithStock(p, stock.getOrDefault(p.sku(), 0)));
    }
}
