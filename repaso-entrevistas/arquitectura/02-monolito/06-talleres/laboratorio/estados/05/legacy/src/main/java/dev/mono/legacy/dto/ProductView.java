package dev.mono.legacy.dto;

import dev.mono.legacy.entity.Product;

public record ProductView(String sku, String name, Money unitPrice, int stock) {
    public static ProductView from(Product p) {
        return new ProductView(p.getSku(), p.getName(), Money.of(p.getPrice(), "USD"), p.getStock());
    }
}
