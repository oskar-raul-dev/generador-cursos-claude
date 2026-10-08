package dev.mono.legacy.auth.internal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

// Taller 08: un token cerrado con logout, visible para todas las instancias
@Entity
@Table(name = "revoked_tokens")
public class RevokedToken {
    @Id
    private String jti;
    @Column(name = "expires_at")
    private Instant expiresAt;          // pasado este momento el token ya no vale: la fila se puede borrar

    protected RevokedToken() {}

    RevokedToken(String jti, Instant expiresAt) {
        this.jti = jti;
        this.expiresAt = expiresAt;
    }

    public String getJti() { return jti; }
    public Instant getExpiresAt() { return expiresAt; }
}
