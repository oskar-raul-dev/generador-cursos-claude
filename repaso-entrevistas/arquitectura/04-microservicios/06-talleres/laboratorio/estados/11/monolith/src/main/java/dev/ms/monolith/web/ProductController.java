package dev.ms.monolith.web;

import dev.ms.monolith.service.CatalogService;
import dev.ms.monolith.service.Views;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ProductController {
    private final CatalogService catalog;

    public ProductController(CatalogService catalog) { this.catalog = catalog; }

    @GetMapping("/api/v1/products")
    Views.Items<Views.ProductView> list() { return new Views.Items<>(catalog.list()); }

    @GetMapping("/api/v1/products/{sku}")
    Views.ProductView get(@PathVariable String sku) { return catalog.get(sku); }
}
