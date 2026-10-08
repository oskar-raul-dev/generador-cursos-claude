package banco;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

// Las transiciones, probadas sin base de datos: el State se prueba solo.
class EstadoCuentaTest {

    private static final Dinero CERO = Dinero.cero(Moneda.COP);

    @Test
    void lasTransicionesPermitidas() {
        assertEquals(EstadoCuenta.BLOQUEADA, EstadoCuenta.ABIERTA.alBloquear("CTA-0001"));
        assertEquals(EstadoCuenta.ABIERTA, EstadoCuenta.BLOQUEADA.alDesbloquear("CTA-0001"));
        assertEquals(EstadoCuenta.CERRADA, EstadoCuenta.ABIERTA.alCerrar("CTA-0001", CERO));
        assertEquals(EstadoCuenta.BLOQUEADA, EstadoCuenta.BLOQUEADA.alBloquear("CTA-0001"));
    }

    @Test
    void lasTransicionesQueNoExisten() {
        assertThrows(IllegalStateException.class, () -> EstadoCuenta.CERRADA.alBloquear("CTA-0001"));
        assertThrows(IllegalStateException.class, () -> EstadoCuenta.CERRADA.alDesbloquear("CTA-0001"));
        assertThrows(IllegalStateException.class, () -> EstadoCuenta.BLOQUEADA.alCerrar("CTA-0001", CERO));
        assertThrows(IllegalStateException.class,
                () -> EstadoCuenta.ABIERTA.alCerrar("CTA-0001", Dinero.de("1", Moneda.COP)));
    }

    @Test
    void cadaPoliticaCobraLoSuyo() {
        Dinero cienMil = Dinero.de("100000", Moneda.COP);
        assertEquals(Dinero.de("1500", Moneda.COP), TipoCuenta.CORRIENTE.comision().deRetiro(cienMil));
        assertEquals(Dinero.de("1000", Moneda.COP), TipoCuenta.CORRIENTE.comision().deTransferencia(cienMil));
        assertEquals(Dinero.de("2.50", Moneda.USD), TipoCuenta.AHORROS.comision().deRetiro(Dinero.de("100", Moneda.USD)));
        assertEquals(Dinero.de("8000.00", Moneda.COP),
                TipoCuenta.NOMINA.comision().deRetiro(Dinero.de("2000001", Moneda.COP)));
    }
}
