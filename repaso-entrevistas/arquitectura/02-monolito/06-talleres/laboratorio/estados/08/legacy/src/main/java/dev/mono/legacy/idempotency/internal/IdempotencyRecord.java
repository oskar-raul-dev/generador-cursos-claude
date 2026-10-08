package dev.mono.legacy.idempotency.internal;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

// Una clave por actor. response_status vacío = el comando está en curso (o murió a medias).
@Entity
@Table(name = "idempotency_keys")
public class IdempotencyRecord {
    @Id
    private String id;                  // actor:clave
    @Column(name = "actor_id")
    private UUID actorId;
    @Column(name = "idem_key", length = 128)
    private String key;
    @Column(length = 512)
    private String fingerprint;         // método, ruta y cuerpo: "la misma petición"
    @Column(name = "response_status")
    private Integer responseStatus;
    @Column(name = "response_body", columnDefinition = "text")
    private String responseBody;
    @Column(name = "created_at")
    private Instant createdAt;

    public String getId() { return id; }
    public UUID getActorId() { return actorId; }
    public String getKey() { return key; }
    public String getFingerprint() { return fingerprint; }
    public Integer getResponseStatus() { return responseStatus; }
    public void setResponseStatus(Integer responseStatus) { this.responseStatus = responseStatus; }
    public String getResponseBody() { return responseBody; }
    public void setResponseBody(String responseBody) { this.responseBody = responseBody; }
    public Instant getCreatedAt() { return createdAt; }
}
