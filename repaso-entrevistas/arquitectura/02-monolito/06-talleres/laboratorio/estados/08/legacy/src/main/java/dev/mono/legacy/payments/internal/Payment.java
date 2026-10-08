package dev.mono.legacy.payments.internal;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "payments")
public class Payment {
    @Id
    private UUID id;

    // taller 06: el id del pedido, no la entidad Order de otro módulo (misma columna)
    @Column(name = "order_id")
    private UUID orderId;

    private String status;          // AUTHORIZED, REJECTED, PENDING
    private String reference;
    @Column(name = "operation_id")
    private String operationId;         // taller 07: la Idempotency-Key, que también viaja al proveedor
    @Column(precision = 12, scale = 2)          // taller 05: decimal con dos cifras, nunca double
    private BigDecimal amount;
    @Column(name = "created_at")
    private Instant createdAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getOrderId() { return orderId; }
    public void setOrderId(UUID orderId) { this.orderId = orderId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getOperationId() { return operationId; }
    public void setOperationId(String operationId) { this.operationId = operationId; }
    public String getReference() { return reference; }
    public void setReference(String reference) { this.reference = reference; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
