package dev.mono.legacy.inventory.web;

import dev.mono.legacy.inventory.internal.Product;
import dev.mono.legacy.inventory.internal.ProductService;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import dev.mono.legacy.shared.Page;
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
        var all = products.all();
        var stock = products.stockOf(all);                 // taller 09: el stock, de la tabla que toque
        return Page.slice(all, cursor, limit, p -> ProductView.from(p, stock.getOrDefault(p.getSku(), 0)));
    }

    @GetMapping("/{sku}")
    public ProductView get(@PathVariable String sku) {
        Product p = products.get(sku);
        if (p == null) {
            throw new LegacyException(ErrorCode.PRODUCT_NOT_FOUND, sku);
        }
        return ProductView.from(p, products.stockOf(java.util.List.of(p)).getOrDefault(sku, 0));
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
        var created = ProductView.from(products.create(p, body.stock()), body.stock());
        return ResponseEntity.created(URI.create("/api/v1/products/" + created.sku())).body(created);
    }
}
