package banco;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

// Los eslabones y el decorador, probados sin base de datos.
class CadenaYDecoradorTest {

    private static Cuenta cuenta(String numero, boolean esMenor) {
        return new Cuenta(numero, "Luis Rojas Paz", "ana.rojas@example.com", TipoCuenta.AHORROS, Moneda.COP,
                Dinero.de("1000000", Moneda.COP), EstadoCuenta.ABIERTA, esMenor);
    }

    @Test
    void laCadenaCortaEnElPrimerEslabonQueFalla() {
        List<String> visitados = new ArrayList<>();
        Regla anota = new Regla() {
            @Override protected void comprobar(Solicitud s) { visitados.add("después del tope"); }
        };
        Regla cadena = Regla.cadena(Reglas.montoPositivo(), Reglas.topeDeMenores("retirar"), anota);
        Solicitud grande = Solicitud.deRetiro(cuenta("CTA-0003", true), Dinero.de("250000", Moneda.COP));
        assertThrows(IllegalStateException.class, () -> cadena.verificar(grande));
        assertEquals(List.of(), visitados);
        cadena.verificar(Solicitud.deRetiro(cuenta("CTA-0003", true), Dinero.de("150000", Moneda.COP)));
        assertEquals(List.of("después del tope"), visitados);
    }

    static final class AuditoriaEnMemoria extends Auditoria {
        final List<String> acciones = new ArrayList<>();
        @Override public void registrar(String accion, String detalle) { acciones.add(accion); }
    }

    static final class OperacionesQueFallan implements OperacionesCuenta {
        public boolean depositar(String n, double m, String r) { return false; }   // un reintento
        public Movimiento retirar(String n, double m) { throw new IllegalStateException("saldo insuficiente en " + n); }
        public Movimiento transferir(String o, String d, double m) { throw new UnsupportedOperationException(); }
        public List<Movimiento> extracto(String n) { return List.of(); }
    }

    @Test
    void elDecoradorNoAuditaLoQueNoPaso() {
        AuditoriaEnMemoria auditoria = new AuditoriaEnMemoria();
        OperacionesCuenta auditadas = new OperacionesAuditadas(new OperacionesQueFallan(), auditoria);
        auditadas.depositar("CTA-0001", 80_000, "PSE-7781");
        assertThrows(IllegalStateException.class, () -> auditadas.retirar("CTA-0001", 1));
        auditadas.extracto("CTA-0001");
        assertEquals(List.of(), auditoria.acciones);
    }
}
