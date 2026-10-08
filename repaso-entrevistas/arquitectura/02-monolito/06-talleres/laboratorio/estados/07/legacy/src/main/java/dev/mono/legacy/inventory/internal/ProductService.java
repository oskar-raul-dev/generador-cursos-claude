package dev.mono.legacy.inventory.internal;

import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProductService {
    private final ProductRepository products;

    public ProductService(ProductRepository products) {
        this.products = products;
    }

    public List<Product> all() {
        return products.findAll(Sort.by("sku"));
    }

    public Product get(String sku) {
        return products.findById(sku).orElse(null);
    }

    // taller 04: dar de alta un SKU que ya existe es un conflicto; hasta el 03 lo pisaba
    public Product create(Product p) {
        if (products.existsById(p.getSku())) {
            throw new LegacyException(ErrorCode.PRODUCT_ALREADY_EXISTS, p.getSku() + " already exists");
        }
        return products.save(p);
    }
}
