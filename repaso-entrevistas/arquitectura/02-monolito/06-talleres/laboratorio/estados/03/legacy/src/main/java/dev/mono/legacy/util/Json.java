package dev.mono.legacy.util;

import java.util.Map;

public final class Json {
    private Json() {}

    // la "API de errores" del sistema: un mapa con una clave
    public static Map<String, Object> error(String message) {
        return Map.of("error", message == null ? "Unknown error" : message);
    }
}
