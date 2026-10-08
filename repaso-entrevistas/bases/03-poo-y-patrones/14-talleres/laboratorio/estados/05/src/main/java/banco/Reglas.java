package banco;

// Los eslabones. Cada uno, una regla con su mensaje.
public final class Reglas {

    private Reglas() { }

    public static Regla cuentasDistintas() {
        return new Regla() {
            @Override protected void comprobar(Solicitud s) {
                if (s.origen().equals(s.destino())) {
                    throw new IllegalArgumentException("origen y destino son la misma cuenta");
                }
            }
        };
    }

    public static Regla montoPositivo() {
        return new Regla() {
            @Override protected void comprobar(Solicitud s) {
                if (!s.importe().esMayorQue(Dinero.cero(s.importe().moneda()))) {
                    throw new IllegalArgumentException("el monto debe ser positivo");
                }
            }
        };
    }

    public static Regla origenPuedeRetirar() {
        return new Regla() {
            @Override protected void comprobar(Solicitud s) { s.origen().verificarQuePuedeRetirar(); }
        };
    }

    public static Regla destinoPuedeRecibir() {
        return new Regla() {
            @Override protected void comprobar(Solicitud s) { s.destino().verificarQuePuedeRecibir(); }
        };
    }

    public static Regla mismaMoneda() {
        return new Regla() {
            @Override protected void comprobar(Solicitud s) {
                if (s.origen().getMoneda() != s.destino().getMoneda()) {
                    throw new IllegalArgumentException("las cuentas tienen monedas distintas");
                }
            }
        };
    }

    // el tope de los menores: una sola regla, para todo lo que sale de su cuenta
    public static Regla topeDeMenores(String verbo) {
        return new Regla() {
            @Override protected void comprobar(Solicitud s) {
                Dinero tope = Dinero.de("200000", s.importe().moneda());
                if (s.origen().isEsMenor() && s.importe().esMayorQue(tope)) {
                    throw new IllegalStateException("un menor no puede " + verbo + " más de 200000");
                }
            }
        };
    }
}
