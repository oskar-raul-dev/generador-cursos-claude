package dev.ms.orders.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "notifications")
public class Notification {
    @Id
    private UUID id;
    @Column(name = "order_id")
    private UUID orderId;
    private String type;
    private String recipient;
    @Column(name = "created_at")
    private Instant createdAt;

    protected Notification() {}

    public Notification(UUID orderId, String type, String recipient) {
        this.id = UUID.randomUUID();
        this.orderId = orderId;
        this.type = type;
        this.recipient = recipient;
        this.createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getOrderId() { return orderId; }
    public String getType() { return type; }
    public String getRecipient() { return recipient; }
    public Instant getCreatedAt() { return createdAt; }
}
