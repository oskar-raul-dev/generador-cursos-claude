package dev.mono.legacy.util;

// "errores de negocio": los controladores los convierten en 200 + {"error": "..."}
public class LegacyException extends RuntimeException {
    public LegacyException(String message) {
        super(message);
    }
}
