package hex.orders.infrastructure.inbound.http;

import hex.orders.application.PageRequest;
import hex.orders.application.usecase.CreateProduct;
import hex.orders.application.usecase.GetProduct;
import hex.orders.application.usecase.ListProducts;
import hex.orders.infrastructure.inbound.http.ApiDtos.CreateProductRequest;
import hex.orders.infrastructure.inbound.http.ApiDtos.PageResponse;
import hex.orders.infrastructure.inbound.http.ApiDtos.ProductResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    private final ListProducts listProducts;
    private final GetProduct getProduct;
    private final CreateProduct createProduct;
    private final ActorResolver actors;

    public ProductController(ListProducts listProducts, GetProduct getProduct, CreateProduct createProduct, ActorResolver actors) {
        this.listProducts = listProducts;
        this.getProduct = getProduct;
        this.createProduct = createProduct;
        this.actors = actors;
    }

    @GetMapping
    PageResponse<ProductResponse> list(@RequestParam(required = false) String cursor,
                                       @RequestParam(required = false) Integer limit) {
        return PageResponse.from(listProducts.execute(PageRequest.of(cursor, limit)).map(ProductResponse::from));
    }

    @GetMapping("/{sku}")
    ProductResponse get(@PathVariable String sku) {
        return ProductResponse.from(getProduct.execute(sku));
    }

    @PostMapping
    ResponseEntity<ProductResponse> create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody CreateProductRequest body) {
        var created = createProduct.execute(new CreateProduct.Command(
            actors.from(jwt), body.sku(), body.name(), body.unitPrice().toMoney(), body.stock()));
        return ResponseEntity.created(URI.create("/api/v1/products/" + created.product().sku()))
            .body(ProductResponse.from(created));
    }
}
