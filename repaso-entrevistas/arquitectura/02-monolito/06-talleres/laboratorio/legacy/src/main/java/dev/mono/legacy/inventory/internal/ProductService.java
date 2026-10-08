package dev.mono.legacy.inventory.internal;

import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProductService {
    private final ProductRepository products;
    private final StockStore stock;
    private final RemoteInventory remote;
    private final boolean stockByApi;

    public ProductService(ProductRepository products, StockStore stock, RemoteInventory remote,
                          @org.springframework.beans.factory.annotation.Value("${legacy.inventory.mode}") String mode) {
        this.products = products;
        this.stock = stock;
        this.remote = remote;
        // taller 10: solo la salida «propiedad de datos» deja de leer la tabla del otro proceso
        this.stockByApi = "remote".equals(mode);
    }

    public java.util.Map<String, Integer> stockOf(List<Product> list) {
        var skus = list.stream().map(Product::getSku).toList();
        return stockByApi ? remote.stock(skus) : stock.read(skus);
    }

    public List<Product> all() {
        return products.findAll(Sort.by("sku"));
    }

    public Product get(String sku) {
        return products.findById(sku).orElse(null);
    }

    // taller 04: dar de alta un SKU que ya existe es un conflicto; hasta el 03 lo pisaba
    @org.springframework.transaction.annotation.Transactional
    public Product create(Product p, int initialStock) {
        if (products.existsById(p.getSku())) {
            throw new LegacyException(ErrorCode.PRODUCT_ALREADY_EXISTS, p.getSku() + " already exists");
        }
        Product saved = products.saveAndFlush(p);
        if (stockByApi) {
            remote.create(p.getSku(), initialStock);
        } else {
            stock.initialize(p.getSku(), initialStock);
        }
        return saved;
    }
}
