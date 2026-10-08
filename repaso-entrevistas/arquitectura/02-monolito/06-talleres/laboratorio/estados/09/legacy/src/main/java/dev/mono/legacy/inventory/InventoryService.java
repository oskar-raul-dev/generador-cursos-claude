package dev.mono.legacy.inventory;

import dev.mono.legacy.inventory.internal.Product;
import dev.mono.legacy.inventory.internal.ProductRepository;
import dev.mono.legacy.inventory.internal.StockStore;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.springframework.stereotype.Service;

// API de inventory. Desde el taller 09 el stock no está en la entidad Product: lo guarda StockStore,
// que sabe en qué paso de la migración products → inventory está esta versión.
@Service
public class InventoryService {
    private final ProductRepository products;
    private final StockStore stock;

    public InventoryService(ProductRepository products, StockStore stock) {
        this.products = products;
        this.stock = stock;
    }

    // leer, restar, escribir, con las filas de stock bloqueadas desde la lectura (taller 07)
    public ReservedStock reserve(String sku, int quantity) {
        Product p = products.findById(sku).orElse(null);
        Integer available = p == null ? null : stock.lockAndRead(sku);
        if (p == null || available == null) {
            throw new LegacyException(ErrorCode.PRODUCT_NOT_FOUND, sku);
        }
        if (available < quantity) {
            throw new LegacyException(ErrorCode.INSUFFICIENT_INVENTORY,
                sku + ": requested " + quantity + ", available " + available);
        }
        stock.add(sku, -quantity);
        return new ReservedStock(p.getSku(), p.getName(), p.getPrice());
    }

    // taller 06: lo que hacía el trigger orders_restore_stock; un incremento en la base
    public void release(String sku, int quantity) {
        stock.add(sku, quantity);
    }
}
