package banco;

import java.util.List;

// La interfaz que comparten el servicio y sus decoradores.
public interface OperacionesCuenta {

    boolean depositar(String numero, double monto, String referencia);   // false si era un reintento

    Movimiento retirar(String numero, double monto);

    Movimiento transferir(String numeroOrigen, String numeroDestino, double monto);

    List<Movimiento> extracto(String numero);
}
