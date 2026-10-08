package banco;

import java.util.List;

// Facade: la misma API de siempre, para los que ya la llaman. Por dentro, delega.
public class GestorCuentas {

    private final ServicioCuentas servicioCuentas;
    private final ServicioMovimientos servicioMovimientos;

    // el único sitio donde se crean las piezas
    public GestorCuentas() {
        this(new RepositorioCuentas(), new RepositorioMovimientos(), new Auditoria(), new Notificador());
    }

    public GestorCuentas(RepositorioCuentas cuentas, RepositorioMovimientos movimientos, Auditoria auditoria,
                         Notificador notificador) {
        this.servicioCuentas = new ServicioCuentas(cuentas, auditoria, notificador);
        this.servicioMovimientos = new ServicioMovimientos(cuentas, movimientos, auditoria, notificador);
    }

    public void abrirCuenta(String numero, String titular, String email, String tipo, String moneda,
                            double saldoInicial, boolean esMenor) {
        servicioCuentas.abrir(numero, titular, email, tipo, moneda, saldoInicial, esMenor);
    }

    public double consultarSaldo(String numero) { return saldo(numero).monto().doubleValue(); }

    public Dinero saldo(String numero) { return servicioCuentas.consultar(numero).getSaldo(); }

    public Cuenta consultarCuenta(String numero) { return servicioCuentas.consultar(numero); }

    public void depositar(String numero, double monto, String referencia) {
        servicioMovimientos.depositar(numero, monto, referencia);
    }

    public void retirar(String numero, double monto) { servicioMovimientos.retirar(numero, monto); }

    public void transferir(String numeroOrigen, String numeroDestino, double monto) {
        servicioMovimientos.transferir(numeroOrigen, numeroDestino, monto);
    }

    public void bloquear(String numero, String motivo) { servicioCuentas.bloquear(numero, motivo); }

    public void desbloquear(String numero) { servicioCuentas.desbloquear(numero); }

    public void cerrar(String numero) { servicioCuentas.cerrar(numero); }

    public List<Movimiento> extracto(String numero) { return servicioMovimientos.extracto(numero); }
}
