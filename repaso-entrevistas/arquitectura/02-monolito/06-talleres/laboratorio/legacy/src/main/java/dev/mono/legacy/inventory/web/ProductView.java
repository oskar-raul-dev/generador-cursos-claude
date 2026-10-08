package dev.mono.legacy.inventory.web;

import dev.mono.legacy.inventory.internal.Product;
import dev.mono.legacy.shared.Money;

public record ProductView(String sku, String name, Money unitPrice, int stock) {
    public static ProductView from(Product p, int stock) {
        return new ProductView(p.getSku(), p.getName(), Money.of(p.getPrice(), "USD"), stock);
    }
}
