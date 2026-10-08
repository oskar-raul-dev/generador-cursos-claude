package dev.ms.monolith.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "inventory_reservations")
public class Reservation {
    @Id
    private UUID id;
    @Column(name = "order_id")
    private UUID orderId;
    private String sku;
    private int quantity;
    private String status;

    protected Reservation() {}

    public Reservation(UUID orderId, String sku, int quantity) {
        this.id = UUID.randomUUID();
        this.orderId = orderId;
        this.sku = sku;
        this.quantity = quantity;
        this.status = "RESERVED";
    }

    public String getSku() { return sku; }
    public int getQuantity() { return quantity; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
