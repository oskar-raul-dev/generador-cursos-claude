package dev.mono.legacy.controller;

import dev.mono.legacy.dto.CreateProductRequest;
import dev.mono.legacy.dto.Page;
import dev.mono.legacy.dto.ProductView;
import dev.mono.legacy.entity.Product;
import dev.mono.legacy.service.ProductService;
import dev.mono.legacy.util.ErrorCode;
import dev.mono.legacy.util.LegacyException;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.net.URI;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {
    private final ProductService products;

    public ProductController(ProductService products) {
        this.products = products;
    }

    @GetMapping
    public Page<ProductView> list(@RequestParam(required = false) String cursor,
                                  @RequestParam(required = false) Integer limit) {
        return Page.slice(products.all(), cursor, limit, ProductView::from);
    }

    @GetMapping("/{sku}")
    public ProductView get(@PathVariable String sku) {
        Product p = products.get(sku);
        if (p == null) {
            throw new LegacyException(ErrorCode.PRODUCT_NOT_FOUND, sku);
        }
        return ProductView.from(p);
    }

    @PostMapping
    public ResponseEntity<ProductView> create(@AuthenticationPrincipal Jwt jwt,
                                              @Valid @RequestBody CreateProductRequest body) {
        if (!"operator".equals(jwt.getClaimAsString("role"))) {
            throw new LegacyException(ErrorCode.FORBIDDEN, null);
        }
        Product p = new Product();
        p.setSku(body.sku());
        p.setName(body.name());
        p.setPrice(new BigDecimal(body.unitPrice().amount()));
        p.setStock(body.stock());
        var created = ProductView.from(products.create(p));
        return ResponseEntity.created(URI.create("/api/v1/products/" + created.sku())).body(created);
    }
}
