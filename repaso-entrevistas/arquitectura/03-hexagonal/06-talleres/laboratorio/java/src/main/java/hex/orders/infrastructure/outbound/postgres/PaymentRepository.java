package hex.orders.infrastructure.outbound.postgres;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PaymentRepository extends JpaRepository<PaymentEntity, UUID> {

    // El último intento es el que refleja el pedido
    Optional<PaymentEntity> findFirstByOrderIdOrderByCreatedAtDesc(UUID orderId);
}
