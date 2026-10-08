package hex.orders.infrastructure.outbound.postgres;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;

// Cursores opacos: el cliente los devuelve tal cual; solo el adaptador sabe qué llevan dentro.
// Un cursor ilegible se trata como "primera página", no como error.
final class Cursors {

    private Cursors() {}

    static String encode(String raw) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    static Optional<String> decode(String cursor) {
        if (cursor == null || cursor.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8));
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }

    record TimeCursor(Instant ts, UUID id) {
        static String encode(Instant ts, UUID id) {
            return Cursors.encode(ts.toString() + "|" + id);
        }

        static Optional<TimeCursor> decode(String cursor) {
            return Cursors.decode(cursor).flatMap(raw -> {
                int sep = raw.indexOf('|');
                if (sep < 0) return Optional.empty();
                try {
                    return Optional.of(new TimeCursor(Instant.parse(raw.substring(0, sep)), UUID.fromString(raw.substring(sep + 1))));
                } catch (RuntimeException e) {
                    return Optional.empty();
                }
            });
        }
    }
}
