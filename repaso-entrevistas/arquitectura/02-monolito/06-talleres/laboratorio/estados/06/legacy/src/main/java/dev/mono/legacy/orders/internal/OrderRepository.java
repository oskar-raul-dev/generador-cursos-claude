package dev.mono.legacy.orders.internal;

import org.springframework.data.jpa.repository.JpaRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface OrderRepository extends JpaRepository<Order, UUID> {
    List<Order> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);

    List<Order> findAllByOrderByCreatedAtDesc();

    List<Order> findByCreatedAtAfter(Instant since);
}
