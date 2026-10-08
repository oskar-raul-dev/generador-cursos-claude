package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "inventory")
public class InventoryEntity {

    @Id
    String sku;

    @Column(nullable = false)
    int available;

    @Column(nullable = false)
    long version;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;
}
