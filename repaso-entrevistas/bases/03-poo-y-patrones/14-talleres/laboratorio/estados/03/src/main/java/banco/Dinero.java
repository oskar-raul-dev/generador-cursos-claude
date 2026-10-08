package banco;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Objects;

// Un monto con su moneda. Inmutable, y siempre con dos decimales: 10.0 y 10.00 son el mismo Dinero.
public record Dinero(BigDecimal monto, Moneda moneda) {

    public Dinero {
        Objects.requireNonNull(monto, "monto");
        Objects.requireNonNull(moneda, "moneda");
        monto = monto.setScale(2, RoundingMode.HALF_EVEN);
    }

    public static Dinero de(String monto, Moneda moneda) {
        return new Dinero(new BigDecimal(monto), moneda);
    }

    // la frontera con el código que todavía habla double: valueOf usa la representación decimal corta
    public static Dinero de(double monto, Moneda moneda) {
        return new Dinero(BigDecimal.valueOf(monto), moneda);
    }

    public static Dinero cero(Moneda moneda) {
        return new Dinero(BigDecimal.ZERO, moneda);
    }

    public Dinero mas(Dinero otro) {
        return new Dinero(monto.add(mismaMoneda(otro).monto), moneda);
    }

    public Dinero menos(Dinero otro) {
        return new Dinero(monto.subtract(mismaMoneda(otro).monto), moneda);
    }

    // multiplica y redondea al centavo, a la par (HALF_EVEN)
    public Dinero por(String factor) {
        return new Dinero(monto.multiply(new BigDecimal(factor)), moneda);
    }

    public boolean esMenorQue(Dinero otro) {
        return monto.compareTo(mismaMoneda(otro).monto) < 0;
    }

    public boolean esMayorQue(Dinero otro) {
        return monto.compareTo(mismaMoneda(otro).monto) > 0;
    }

    public boolean esCero() {
        return monto.signum() == 0;
    }

    private Dinero mismaMoneda(Dinero otro) {
        if (otro.moneda != moneda) {
            throw new IllegalArgumentException("no se operan " + moneda + " con " + otro.moneda);
        }
        return otro;
    }

    @Override
    public String toString() {
        return monto.toPlainString() + " " + moneda;
    }
}
