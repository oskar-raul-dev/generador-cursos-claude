package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

// Registro JPA del pedido. Es lo que Hibernate conoce; Order (dominio) es otra cosa y el
// adaptador traduce entre ambos. Las líneas se cargan siempre (EAGER): un pedido sin líneas no es
// un agregado válido, y no hay sesión abierta fuera del caso de uso para cargarlas después.
// El pago no está aquí: el adaptador lo reconstruye desde la tabla payments (el último intento).
@Entity
@Table(name = "orders")
public class OrderEntity {

    @Id
    UUID id;

    @Column(name = "customer_id", nullable = false)
    UUID customerId;

    @Column(nullable = false)
    String status;

    @Column(name = "total_amount", nullable = false, precision = 12, scale = 2)
    BigDecimal totalAmount;

    @Column(nullable = false, length = 3)
    String currency;

    @Column(nullable = false)
    long version;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "order_lines", joinColumns = @JoinColumn(name = "order_id"))
    @OrderColumn(name = "line_no")
    List<OrderLineEmbeddable> lines = new ArrayList<>();
}
