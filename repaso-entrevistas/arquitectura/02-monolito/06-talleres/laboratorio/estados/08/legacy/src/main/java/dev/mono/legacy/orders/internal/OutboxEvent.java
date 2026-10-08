package dev.mono.legacy.orders.internal;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

// Taller 08: un hecho pendiente de entregar, escrito en la MISMA transacción que lo produjo. Si la
// transacción se deshace, el hecho no existe; si confirma, el despachador lo entregará tarde o temprano.
@Entity
@Table(name = "outbox_events")
public class OutboxEvent {
    @Id
    private UUID id;                    // el eventId: quien lo reciba puede deduplicar por él
    private String type;
    @Column(columnDefinition = "text")
    private String payload;             // el evento en JSON
    @Column(name = "occurred_at")
    private Instant occurredAt;
    @Column(name = "published_at")
    private Instant publishedAt;        // null = pendiente
    private int attempts;
    @Column(name = "last_error", length = 500)
    private String lastError;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getPayload() { return payload; }
    public void setPayload(String payload) { this.payload = payload; }
    public Instant getOccurredAt() { return occurredAt; }
    public void setOccurredAt(Instant occurredAt) { this.occurredAt = occurredAt; }
    public Instant getPublishedAt() { return publishedAt; }
    public void setPublishedAt(Instant publishedAt) { this.publishedAt = publishedAt; }
    public int getAttempts() { return attempts; }
    public String getLastError() { return lastError; }
}
