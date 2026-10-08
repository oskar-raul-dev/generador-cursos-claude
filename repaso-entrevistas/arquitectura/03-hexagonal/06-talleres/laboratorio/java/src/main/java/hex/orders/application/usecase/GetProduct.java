package hex.orders.application.usecase;

import hex.orders.application.error.NotFound;
import hex.orders.application.port.out.Inventory;
import hex.orders.application.port.out.Products;

import java.util.List;

public final class GetProduct {

    private final Products products;
    private final Inventory inventory;

    public GetProduct(Products products, Inventory inventory) {
        this.products = products;
        this.inventory = inventory;
    }

    public ListProducts.ProductWithStock execute(String sku) {
        var product = products.find(sku).orElseThrow(() -> NotFound.product(sku));
        int stock = inventory.availableFor(List.of(sku)).getOrDefault(sku, 0);
        return new ListProducts.ProductWithStock(product, stock);
    }
}
