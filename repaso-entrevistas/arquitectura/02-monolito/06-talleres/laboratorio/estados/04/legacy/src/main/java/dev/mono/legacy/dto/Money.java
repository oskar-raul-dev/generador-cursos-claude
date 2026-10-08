package dev.mono.legacy.dto;

import java.math.BigDecimal;
import java.math.RoundingMode;

// Taller 04: el dinero sale como texto decimal con dos cifras. Por dentro sigue siendo double hasta
// el taller 05: el contrato esconde el 29.700000000000003, no lo arregla.
public record Money(String amount, String currency) {
    public static Money of(double value, String currency) {
        return new Money(BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP).toPlainString(), currency);
    }
}
