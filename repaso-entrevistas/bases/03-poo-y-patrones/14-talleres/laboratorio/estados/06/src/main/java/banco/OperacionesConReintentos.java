package banco;

import java.util.List;
import java.util.concurrent.ThreadLocalRandom;
import java.util.function.Supplier;

// Decorator: si la operación choca con otra, la repite desde el principio, con una espera corta y al azar.
public final class OperacionesConReintentos implements OperacionesCuenta {

    private final OperacionesCuenta envuelto;
    private final int intentos;

    public OperacionesConReintentos(OperacionesCuenta envuelto, int intentos) {
        this.envuelto = envuelto;
        this.intentos = intentos;
    }

    private <T> T conReintentos(Supplier<T> operacion) {
        for (int i = 1; ; i++) {
            try {
                return operacion.get();
            } catch (ConflictoDeConcurrencia e) {
                if (i == intentos) throw e;
                try {
                    Thread.sleep(ThreadLocalRandom.current().nextInt(1, 5 * i));
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    throw e;
                }
            }
        }
    }

    @Override
    public boolean depositar(String numero, double monto, String referencia) {
        return conReintentos(() -> envuelto.depositar(numero, monto, referencia));
    }

    @Override
    public Movimiento retirar(String numero, double monto) {
        return conReintentos(() -> envuelto.retirar(numero, monto));
    }

    @Override
    public Movimiento transferir(String numeroOrigen, String numeroDestino, double monto) {
        return conReintentos(() -> envuelto.transferir(numeroOrigen, numeroDestino, monto));
    }

    @Override
    public List<Movimiento> extracto(String numero) {
        return envuelto.extracto(numero);
    }
}
