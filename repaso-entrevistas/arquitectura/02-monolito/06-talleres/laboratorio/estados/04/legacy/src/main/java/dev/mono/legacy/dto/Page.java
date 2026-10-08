package dev.mono.legacy.dto;

import dev.mono.legacy.util.ErrorCode;
import dev.mono.legacy.util.LegacyException;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import java.util.function.Function;

// Página con cursor opaco. Por dentro el cursor es un desplazamiento codificado: el cliente no lo
// interpreta, así que el servidor puede cambiar a paginación por clave sin romper el contrato.
public record Page<T>(List<T> items, String nextCursor) {
    public static final int DEFAULT_LIMIT = 20;
    public static final int MAX_LIMIT = 100;

    public static <E, T> Page<T> slice(List<E> all, String cursor, Integer limit, Function<E, T> mapper) {
        int size = limit == null ? DEFAULT_LIMIT : limit;
        if (size < 1) {
            throw new LegacyException(ErrorCode.VALIDATION_FAILED, "limit must be at least 1");
        }
        size = Math.min(size, MAX_LIMIT);
        int from = decode(cursor);
        int to = Math.min(from + size, all.size());
        var items = from >= all.size() ? List.<T>of() : all.subList(from, to).stream().map(mapper).toList();
        return new Page<>(items, to < all.size() ? encode(to) : null);
    }

    private static String encode(int offset) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(("o:" + offset).getBytes(StandardCharsets.UTF_8));
    }

    private static int decode(String cursor) {
        if (cursor == null || cursor.isBlank()) {
            return 0;
        }
        try {
            var raw = new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8);
            if (!raw.startsWith("o:")) {
                throw new IllegalArgumentException(raw);
            }
            return Math.max(0, Integer.parseInt(raw.substring(2)));
        } catch (IllegalArgumentException e) {
            throw new LegacyException(ErrorCode.VALIDATION_FAILED, "invalid cursor");
        }
    }
}
