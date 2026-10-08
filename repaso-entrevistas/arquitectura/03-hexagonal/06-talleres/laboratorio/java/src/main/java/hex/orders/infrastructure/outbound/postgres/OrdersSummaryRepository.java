package hex.orders.infrastructure.outbound.postgres;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface OrdersSummaryRepository extends JpaRepository<OrdersSummaryEntity, UUID> {

    List<OrdersSummaryEntity> findAllByOrderByCustomerIdAsc();
}
