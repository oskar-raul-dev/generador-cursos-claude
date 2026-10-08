package co.aurea;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

public class Regalias {
    /** Regalía en pesos: ventas por tasa, redondeo bancario al peso. */
    public static BigDecimal regalia(BigDecimal ventas, BigDecimal tasa) {
        return ventas.multiply(tasa).setScale(0, RoundingMode.HALF_EVEN);
    }

    /** La misma cuenta en enteros: tasa en puntos básicos (450 = 4,5 %). */
    public static long regaliaPesos(long ventas, int tasaBps) {
        return (ventas * tasaBps + 5_000) / 10_000;
    }

    public static List<String> franquicias() {
        return List.of("Suba", "Zipaquirá");
    }
}
