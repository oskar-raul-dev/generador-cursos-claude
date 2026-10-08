package banco;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import java.util.Set;
import org.junit.jupiter.api.Test;

class DineroTest {

    @Test
    void bigDecimalSoloNoAlcanzaParaLaIgualdad() {
        // la trampa que Dinero esconde: equals de BigDecimal compara también la escala
        assertNotEquals(new BigDecimal("10.0"), new BigDecimal("10.00"));
        assertEquals(0, new BigDecimal("10.0").compareTo(new BigDecimal("10.00")));
    }

    @Test
    void diezYDiezConCeroSonElMismoDinero() {
        Dinero a = Dinero.de("10.0", Moneda.COP);
        Dinero b = Dinero.de("10.00", Moneda.COP);
        assertEquals(a, b);
        assertEquals(1, Set.of(a).size());
        assertEquals(a.hashCode(), b.hashCode());
    }

    @Test
    void laMonedaEsParteDeLaIgualdad() {
        assertNotEquals(Dinero.de("2.50", Moneda.COP), Dinero.de("2.50", Moneda.USD));
        assertThrows(IllegalArgumentException.class,
                () -> Dinero.de("2.50", Moneda.COP).mas(Dinero.de("2.50", Moneda.USD)));
    }

    @Test
    void elPorcentajeSeRedondeaAlCentavoALaPar() {
        assertEquals(Dinero.de("10000.00", Moneda.COP), Dinero.de("2500000.10", Moneda.COP).por("0.004"));
        assertEquals(Dinero.de("0.02", Moneda.COP), Dinero.de("0.025", Moneda.COP));   // HALF_EVEN: al par
        assertEquals(Dinero.de("0.04", Moneda.COP), Dinero.de("0.035", Moneda.COP));
    }

    @Test
    void desdeDoubleUsaLaRepresentacionCorta() {
        assertEquals("0.10 COP", Dinero.de(0.1, Moneda.COP).toString());
        assertEquals("0.30 COP", Dinero.de(0.1, Moneda.COP).mas(Dinero.de(0.2, Moneda.COP)).toString());
        assertEquals(0.30000000000000004, 0.1 + 0.2);
    }
}
