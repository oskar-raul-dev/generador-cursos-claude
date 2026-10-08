package dev.mono.legacy.inventory;

import dev.mono.legacy.inventory.internal.Product;
import dev.mono.legacy.inventory.internal.ProductRepository;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.springframework.stereotype.Service;

// API de inventory. Ya no conoce a OrderService: el ciclo de beans del legado venía de un método
// isReserved(orderId) que nadie llamaba.
@Service
public class InventoryService {
    private final ProductRepository products;

    public InventoryService(ProductRepository products) {
        this.products = products;
    }

    // leer, restar, escribir (sin bloqueo ni versión: taller 07)
    public ReservedStock reserve(String sku, int quantity) {
        Product p = products.findById(sku).orElse(null);
        if (p == null) {
            throw new LegacyException(ErrorCode.PRODUCT_NOT_FOUND, sku);
        }
        if (p.getStock() < quantity) {
            throw new LegacyException(ErrorCode.INSUFFICIENT_INVENTORY,
                sku + ": requested " + quantity + ", available " + p.getStock());
        }
        p.setStock(p.getStock() - quantity);
        products.save(p);
        return new ReservedStock(p.getSku(), p.getName(), p.getPrice());
    }

    // taller 06: lo que hacía el trigger orders_restore_stock, ahora en el módulo dueño del stock.
    // Un incremento en la base, no leer-sumar-escribir: no pisa lo que otro haya escrito entretanto.
    public void release(String sku, int quantity) {
        if (products.addStock(sku, quantity) == 0) {
            throw new LegacyException(ErrorCode.PRODUCT_NOT_FOUND, sku);
        }
    }
}
