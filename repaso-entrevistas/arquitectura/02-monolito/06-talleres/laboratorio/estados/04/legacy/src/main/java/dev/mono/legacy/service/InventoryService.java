package dev.mono.legacy.service;

import dev.mono.legacy.entity.Order;
import dev.mono.legacy.entity.Product;
import dev.mono.legacy.repository.ProductRepository;
import dev.mono.legacy.util.ErrorCode;
import dev.mono.legacy.util.LegacyException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class InventoryService {
    private final ProductRepository products;

    @Autowired                                // por constructor no arrancaba: "ciclo de beans"
    private OrderService orders;

    public InventoryService(ProductRepository products) {
        this.products = products;
    }

    // leer, restar, escribir
    public Product take(String sku, int quantity) {
        Product p = products.findById(sku).orElse(null);
        if (p == null) {                          // taller 04: antes, NullPointerException y 500 con traza
            throw new LegacyException(ErrorCode.PRODUCT_NOT_FOUND, sku);
        }
        if (p.getStock() < quantity) {
            throw new LegacyException(ErrorCode.INSUFFICIENT_INVENTORY,
                sku + ": requested " + quantity + ", available " + p.getStock());
        }
        p.setStock(p.getStock() - quantity);
        return products.save(p);
    }

    public boolean isReserved(UUID orderId) {
        Order o = orders.findEntity(orderId);
        return o != null && !"CANCELLED".equals(o.getStatus());
    }
}
