package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.application.port.out.Products;
import hex.orders.domain.Money;
import hex.orders.domain.Product;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.util.List;
import java.util.Optional;

// Catálogo en PostgreSQL (partes 1 y 2). No es @Primary ni condicional: el composition root elige
// entre este y MongoProducts según hex.catalog.
@Component
public class JpaProducts implements Products {

    private final ProductRepository repository;
    private final Clock clock;

    public JpaProducts(ProductRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public Optional<Product> find(String sku) {
        return repository.findById(sku).map(JpaProducts::toProduct);
    }

    @Override
    public boolean exists(String sku) {
        return repository.existsById(sku);
    }

    @Override
    public Page<Product> list(PageRequest page) {
        // se pide una fila más que el límite para saber si hay página siguiente sin contar
        Pageable limit = Pageable.ofSize(page.limit() + 1);
        List<ProductEntity> rows = Cursors.decode(page.cursor())
            .map(after -> repository.findBySkuGreaterThanOrderBySkuAsc(after, limit))
            .orElseGet(() -> repository.findAllByOrderBySkuAsc(limit));
        boolean more = rows.size() > page.limit();
        List<ProductEntity> pageRows = more ? rows.subList(0, page.limit()) : rows;
        String next = more ? Cursors.encode(pageRows.getLast().sku) : null;
        return new Page<>(pageRows.stream().map(JpaProducts::toProduct).toList(), next);
    }

    @Override
    public void save(Product product) {
        var entity = repository.findById(product.sku()).orElseGet(() -> {
            var created = new ProductEntity();
            created.sku = product.sku();
            created.createdAt = clock.instant();
            return created;
        });
        entity.name = product.name();
        entity.unitPrice = product.unitPrice().amount();
        entity.currency = product.unitPrice().currency();
        entity.updatedAt = clock.instant();
        repository.save(entity);
    }

    private static Product toProduct(ProductEntity e) {
        return new Product(e.sku, e.name, new Money(e.unitPrice, e.currency));
    }
}
