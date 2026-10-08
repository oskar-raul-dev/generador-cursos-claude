package dev.mono.legacy.dto;

import java.math.BigDecimal;
import java.math.RoundingMode;

// Taller 04: el dinero sale como texto decimal con dos cifras. Desde el 05 también es decimal por
// dentro: setScale(2) solo normaliza la escala (un 1499 leído sin decimales sale como 1499.00).
public record Money(String amount, String currency) {
    public static Money of(BigDecimal value, String currency) {
        return new Money(value.setScale(2, RoundingMode.UNNECESSARY).toPlainString(), currency);
    }
}
