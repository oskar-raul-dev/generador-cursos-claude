package hex.orders.infrastructure.outbound.postgres;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProductRepository extends JpaRepository<ProductEntity, String> {

    // Paginación por cursor: "los que van después de este sku", ordenados. Sin OFFSET.
    List<ProductEntity> findBySkuGreaterThanOrderBySkuAsc(String afterSku, Pageable pageable);

    List<ProductEntity> findAllByOrderBySkuAsc(Pageable pageable);
}
