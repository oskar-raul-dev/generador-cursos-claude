package hex.orders.infrastructure.inbound.http;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

// Validación de la cabecera y huella del cuerpo. La huella es lo que permite detectar "misma
// clave, otro cuerpo" sin guardar el cuerpo entero.
public final class IdempotencyKeys {

    private IdempotencyKeys() {}

    public static String require(String header) {
        if (header == null || header.isBlank()) {
            throw new MissingIdempotencyKey();
        }
        if (header.length() < 8 || header.length() > 128) {
            throw new IllegalArgumentException("Idempotency-Key must be between 8 and 128 characters");
        }
        return header;
    }

    public static String hash(String canonical) {
        try {
            var digest = MessageDigest.getInstance("SHA-256").digest(canonical.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
