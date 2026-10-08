package dev.mono.legacy.controller;

import dev.mono.legacy.entity.Product;
import dev.mono.legacy.service.ProductService;
import dev.mono.legacy.util.Json;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {
    private final ProductService products;

    public ProductController(ProductService products) {
        this.products = products;
    }

    @GetMapping
    public Object list() {
        return products.all();
    }

    @GetMapping("/{sku}")
    public Object get(@PathVariable String sku) {
        Product p = products.get(sku);
        if (p == null) {
            return Json.error("Product " + sku + " does not exist");
        }
        return p;
    }

    @PostMapping
    public Object create(@AuthenticationPrincipal Jwt jwt, @RequestBody Product product) {
        if (!"operator".equals(jwt.getClaimAsString("role"))) {
            return Json.error("Only operators can do this");
        }
        return products.save(product);
    }
}
