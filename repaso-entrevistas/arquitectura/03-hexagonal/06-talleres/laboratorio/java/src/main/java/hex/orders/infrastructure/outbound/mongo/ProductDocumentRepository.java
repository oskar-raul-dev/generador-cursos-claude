package hex.orders.infrastructure.outbound.mongo;

import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ProductDocumentRepository extends MongoRepository<ProductDocument, String> {

    List<ProductDocument> findBySkuGreaterThanOrderBySkuAsc(String afterSku, Pageable pageable);

    List<ProductDocument> findAllByOrderBySkuAsc(Pageable pageable);
}
