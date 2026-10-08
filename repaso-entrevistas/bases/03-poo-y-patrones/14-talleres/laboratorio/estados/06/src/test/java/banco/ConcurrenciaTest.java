package banco;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;

// Cien depósitos de 1 000 sobre la misma cuenta, desde diez hilos a la vez.
class ConcurrenciaTest {

    static final class NotificadorMudo extends Notificador {
        @Override public void enviar(String email, String mensaje) { }
    }

    @Test
    void cienDepositosConcurrentesSumanCienMil() throws Exception {
        BaseDatos.crearEsquema();
        GestorCuentas gestor = new GestorCuentas(new RepositorioCuentas(), new RepositorioMovimientos(), new Auditoria(),
                new NotificadorMudo());
        gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 0, false);
        ExecutorService hilos = Executors.newFixedThreadPool(10);
        List<Future<?>> tareas = new ArrayList<>();
        for (int i = 0; i < 100; i++) {
            tareas.add(hilos.submit(() -> gestor.depositar("CTA-0001", 1_000, null)));
        }
        for (Future<?> t : tareas) t.get();
        hilos.shutdown();
        assertEquals(Dinero.de("100000", Moneda.COP), gestor.saldo("CTA-0001"));
    }
}
