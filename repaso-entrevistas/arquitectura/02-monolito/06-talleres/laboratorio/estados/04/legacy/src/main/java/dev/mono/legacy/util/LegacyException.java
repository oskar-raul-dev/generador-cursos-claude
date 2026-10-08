package dev.mono.legacy.util;

import java.util.List;
import java.util.Map;

// Errores de negocio. Hasta el taller 03 los controladores los convertían en 200 + {"error": "..."};
// desde el 04 llevan un código del contrato y los traduce UNA vez ApiErrorHandler.
public class LegacyException extends RuntimeException {
    private final ErrorCode code;
    private final List<Map<String, String>> errors;

    public LegacyException(ErrorCode code, String detail) {
        this(code, detail, List.of());
    }

    public LegacyException(ErrorCode code, String detail, List<Map<String, String>> errors) {
        super(detail);
        this.code = code;
        this.errors = errors;
    }

    public ErrorCode code() { return code; }

    public List<Map<String, String>> errors() { return errors; }
}
