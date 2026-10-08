package hex.orders.infrastructure.outbound.postgres;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface OrderRepository extends JpaRepository<OrderEntity, UUID> {

    // Cursor sobre (created_at, id) descendente: estable aunque se creen pedidos entre páginas.
    @Query("SELECT o FROM OrderEntity o WHERE (:customerId IS NULL OR o.customerId = :customerId) "
         + "AND (o.createdAt < :ts OR (o.createdAt = :ts AND o.id < :id)) "
         + "ORDER BY o.createdAt DESC, o.id DESC")
    List<OrderEntity> pageAfter(@Param("customerId") UUID customerId, @Param("ts") Instant ts,
                                @Param("id") UUID id, Pageable pageable);

    @Query("SELECT o FROM OrderEntity o WHERE (:customerId IS NULL OR o.customerId = :customerId) "
         + "ORDER BY o.createdAt DESC, o.id DESC")
    List<OrderEntity> firstPage(@Param("customerId") UUID customerId, Pageable pageable);
}
