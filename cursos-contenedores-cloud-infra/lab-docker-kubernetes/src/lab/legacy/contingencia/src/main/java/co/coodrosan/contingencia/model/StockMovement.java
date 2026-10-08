package co.coodrosan.contingencia.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "stock_movement")
public class StockMovement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "store_id")
    private String storeId;
    private String sku;
    private String type;
    private int quantity;
    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    protected StockMovement() { }

    public StockMovement(String storeId, String sku, String type, int quantity) {
        this.storeId = storeId;
        this.sku = sku;
        this.type = type;
        this.quantity = quantity;
    }
}
