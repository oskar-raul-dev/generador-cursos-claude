package dev.ms.monolith.service;

import dev.ms.monolith.repository.ProductRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class CatalogService {
    private final ProductRepository products;

    public CatalogService(ProductRepository products) { this.products = products; }

    public List<Views.ProductView> list() {
        return products.findAllWithStock().stream().map(CatalogService::view).toList();
    }

    public Views.ProductView get(String sku) {
        return products.findWithStock(sku).map(CatalogService::view).orElseThrow(() -> new Errors.ProductNotFound(sku));
    }

    private static Views.ProductView view(ProductRepository.ProductStock p) {
        return new Views.ProductView(p.getSku(), p.getName(), Views.Money.of(p.getUnitPrice(), p.getCurrency().trim()), p.getAvailable());
    }
}
