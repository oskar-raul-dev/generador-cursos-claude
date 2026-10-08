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

    public ProductService(ProductRepository products, StockStore stock) {
        this.products = products;
        this.stock = stock;
    }

    public java.util.Map<String, Integer> stockOf(List<Product> list) {
        return stock.read(list.stream().map(Product::getSku).toList());
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
        stock.initialize(p.getSku(), initialStock);
        return saved;
    }
}
