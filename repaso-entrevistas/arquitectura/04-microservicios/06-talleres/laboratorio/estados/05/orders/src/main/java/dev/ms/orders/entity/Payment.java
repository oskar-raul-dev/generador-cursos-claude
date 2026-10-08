package dev.ms.orders.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "payments")
public class Payment {
    @Id
    private UUID id;
    @Column(name = "order_id")
    private UUID orderId;
    @Column(name = "operation_id")
    private String operationId;
    private String status;
    private String reference;
    private BigDecimal amount;
    @Column(name = "created_at")
    private Instant createdAt;

    protected Payment() {}

    public Payment(UUID orderId, String operationId, String status, String reference, BigDecimal amount) {
        this.id = UUID.randomUUID();
        this.orderId = orderId;
        this.operationId = operationId;
        this.status = status;
        this.reference = reference;
        this.amount = amount;
        this.createdAt = Instant.now();
    }

    public String getOperationId() { return operationId; }
    public void resolve(String status, String reference) { this.status = status; this.reference = reference; }
    public String getStatus() { return status; }
    public String getReference() { return reference; }
}
