package co.coodrosan.contingencia.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

// El préstamo entre vecinas: una reposición cuyo origen es otra droguería.
// Las filas las crea el procedimiento register_loan, nunca este código.
@Entity
@Table(name = "replenishment_order")
public class ReplenishmentOrder {
    @Id
    private Long id;
    private String sku;
    @Column(name = "origin_store_id")
    private String originStoreId;
    @Column(name = "destination_store_id")
    private String destinationStoreId;
    private int quantity;
    private String status;
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public String getSku() { return sku; }
    public String getOriginStoreId() { return originStoreId; }
    public String getDestinationStoreId() { return destinationStoreId; }
    public int getQuantity() { return quantity; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setStatus(String status) { this.status = status; }
}
