package dev.mono.legacy.service;

import dev.mono.legacy.entity.Product;
import dev.mono.legacy.repository.ProductRepository;
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

    public Product save(Product p) {
        return products.save(p);     // si el SKU ya existe, lo pisa
    }
}
