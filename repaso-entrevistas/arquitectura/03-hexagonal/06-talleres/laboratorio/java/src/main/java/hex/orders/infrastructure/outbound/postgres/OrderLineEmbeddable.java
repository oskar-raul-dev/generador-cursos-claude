package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.math.BigDecimal;

@Embeddable
public class OrderLineEmbeddable {

    @Column(nullable = false)
    String sku;

    @Column(name = "product_name", nullable = false)
    String productName;

    @Column(nullable = false)
    int quantity;

    @Column(name = "unit_price", nullable = false, precision = 12, scale = 2)
    BigDecimal unitPrice;
}
