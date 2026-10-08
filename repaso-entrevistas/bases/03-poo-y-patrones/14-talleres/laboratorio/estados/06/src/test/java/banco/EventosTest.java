package banco;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

// Los eventos salen después de confirmar, y solo si se confirmó.
class EventosTest {

    private final List<EventoDeCuenta> recibidos = new ArrayList<>();
    private ServicioMovimientos servicio;

    @BeforeEach
    void preparar() {
        BaseDatos.crearEsquema();
        PublicadorDeEventos publicador = new PublicadorDeEventos();
        publicador.suscribir(recibidos::add);
        RepositorioCuentas cuentas = new RepositorioCuentas();
        new ServicioCuentas(cuentas, new Auditoria(), new PublicadorDeEventos())
                .abrir("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
        new ServicioCuentas(cuentas, new Auditoria(), new PublicadorDeEventos())
                .abrir("CTA-0003", "Luis Rojas Paz", "ana.rojas@example.com", "AHORROS", "COP", 0, true);
        servicio = new ServicioMovimientos(cuentas, new RepositorioMovimientos(), publicador);
    }

    @Test
    void unaTransferenciaPublicaLoQueLeLlegoAlDestino() {
        servicio.transferir("CTA-0001", "CTA-0003", 250_000);
        assertEquals(List.of(new EventoDeCuenta.TransferenciaRecibida("CTA-0003", "ana.rojas@example.com",
                Dinero.de("250000", Moneda.COP), "Ana Rojas Medina")), recibidos);
    }

    @Test
    void loQueNoSeConfirmoNoSePublica() {
        assertThrows(IllegalStateException.class, () -> servicio.retirar("CTA-0003", 1));   // saldo insuficiente
        assertEquals(List.of(), recibidos);
    }
}
