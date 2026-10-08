package dev.mono.legacy.orders.internal;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

// Taller 07: sin Open Session in View, lo que el controlador va a pintar se carga aquí, dentro de la
// transacción de lectura (EntityGraph = las líneas en la misma consulta).
public interface OrderRepository extends JpaRepository<Order, UUID> {
    @EntityGraph(attributePaths = "lines")
    List<Order> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);

    @EntityGraph(attributePaths = "lines")
    List<Order> findAllByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = "lines")
    Optional<Order> findWithLinesById(UUID id);

    long countByCreatedAtAfter(Instant since);

    // taller 07: la fila del pedido bloqueada hasta el final de la transacción
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from Order o where o.id = :id")
    Optional<Order> findForUpdateById(UUID id);
}
