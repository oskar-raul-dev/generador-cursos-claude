package dev.mono.legacy.auth.internal;

import org.springframework.stereotype.Component;

import java.time.Instant;

// Tokens cerrados con logout. Hasta el taller 07 vivían en un Set en memoria "porque es rápido": con
// dos instancias, un logout en una no existía en la otra. Ahora, en la base.
@Component
public class RevokedTokens {
    private final RevokedTokenRepository revoked;

    public RevokedTokens(RevokedTokenRepository revoked) {
        this.revoked = revoked;
    }

    public void revoke(String jti, Instant expiresAt) {
        revoked.save(new RevokedToken(jti, expiresAt));
    }

    public boolean isRevoked(String jti) {
        return jti != null && revoked.existsById(jti);
    }
}
