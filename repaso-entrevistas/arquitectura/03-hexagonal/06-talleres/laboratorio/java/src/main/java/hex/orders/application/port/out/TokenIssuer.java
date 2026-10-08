package hex.orders.application.port.out;

import java.time.Instant;

// Emite la credencial del contrato. Qué formato tiene (JWT HS256, 15 min) es del adaptador; aplicación
// solo necesita el valor, cuánto dura y el identificador con el que después se revoca.
public interface TokenIssuer {

    record IssuedToken(String value, String tokenId, Instant expiresAt, long expiresInSeconds) {}

    IssuedToken issue(Users.User user);
}
