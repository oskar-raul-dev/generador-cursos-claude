package hex.orders.infrastructure.outbound.mongo;

import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.application.port.out.Products;
import hex.orders.domain.Money;
import hex.orders.domain.Product;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import java.util.Optional;

// Parte 3: el catálogo en MongoDB detrás del mismo puerto Products. El inventario sigue en
// PostgreSQL; la composición de "producto + stock" ya ocurría en aplicación, así que nada cambia
// fuera de este paquete y de la selección en el composition root.
@Component
public class MongoProducts implements Products {

    private final ProductDocumentRepository repository;

    public MongoProducts(ProductDocumentRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<Product> find(String sku) {
        return repository.findById(sku).map(MongoProducts::toProduct);
    }

    @Override
    public boolean exists(String sku) {
        return repository.existsById(sku);
    }

    @Override
    public Page<Product> list(PageRequest page) {
        Pageable limit = Pageable.ofSize(page.limit() + 1);
        List<ProductDocument> rows = decode(page.cursor())
            .map(after -> repository.findBySkuGreaterThanOrderBySkuAsc(after, limit))
            .orElseGet(() -> repository.findAllByOrderBySkuAsc(limit));
        boolean more = rows.size() > page.limit();
        List<ProductDocument> pageRows = more ? rows.subList(0, page.limit()) : rows;
        String next = more ? encode(pageRows.getLast().sku) : null;
        return new Page<>(pageRows.stream().map(MongoProducts::toProduct).toList(), next);
    }

    @Override
    public void save(Product product) {
        var doc = new ProductDocument();
        doc.id = product.sku();
        doc.sku = product.sku();
        doc.name = product.name();
        doc.unitPrice = new ProductDocument.UnitPrice();
        doc.unitPrice.amount = product.unitPrice().amountAsText();
        doc.unitPrice.currency = product.unitPrice().currency();
        repository.save(doc);
    }

    private static Product toProduct(ProductDocument d) {
        return new Product(d.sku, d.name, Money.of(d.unitPrice.amount, d.unitPrice.currency));
    }

    // El cursor es del adaptador: mismo formato que el de JPA por comodidad, pero podría no serlo.
    private static String encode(String raw) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    private static Optional<String> decode(String cursor) {
        if (cursor == null || cursor.isBlank()) return Optional.empty();
        try {
            return Optional.of(new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8));
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }
}
