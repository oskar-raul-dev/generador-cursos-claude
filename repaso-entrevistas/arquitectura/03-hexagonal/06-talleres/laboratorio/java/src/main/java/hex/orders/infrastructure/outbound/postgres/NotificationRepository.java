package hex.orders.infrastructure.outbound.postgres;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<NotificationEntity, UUID> {

    @Query("SELECT n FROM NotificationEntity n WHERE (:orderId IS NULL OR n.orderId = :orderId) "
         + "ORDER BY n.createdAt DESC, n.id DESC")
    List<NotificationEntity> firstPage(@Param("orderId") UUID orderId, Pageable pageable);

    @Query("SELECT n FROM NotificationEntity n WHERE (:orderId IS NULL OR n.orderId = :orderId) "
         + "AND (n.createdAt < :ts OR (n.createdAt = :ts AND n.id < :id)) "
         + "ORDER BY n.createdAt DESC, n.id DESC")
    List<NotificationEntity> pageAfter(@Param("orderId") UUID orderId, @Param("ts") Instant ts,
                                       @Param("id") UUID id, Pageable pageable);
}
