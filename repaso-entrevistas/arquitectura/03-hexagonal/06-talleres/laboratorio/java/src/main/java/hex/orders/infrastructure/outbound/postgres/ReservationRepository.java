package hex.orders.infrastructure.outbound.postgres;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ReservationRepository extends JpaRepository<ReservationEntity, UUID> {

    List<ReservationEntity> findByOrderIdAndStatus(UUID orderId, String status);
}
