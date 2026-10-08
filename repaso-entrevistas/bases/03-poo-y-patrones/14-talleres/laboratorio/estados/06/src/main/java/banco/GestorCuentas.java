package banco;

import java.util.List;

// Facade: la misma API de siempre, para los que ya la llaman. Por dentro, delega.
public class GestorCuentas {

    private final ServicioCuentas servicioCuentas;
    private final OperacionesCuenta operaciones;

    // el único sitio donde se crean las piezas
    public GestorCuentas() {
        this(new RepositorioCuentas(), new RepositorioMovimientos(), new Auditoria(), new Notificador());
    }

    public GestorCuentas(RepositorioCuentas cuentas, RepositorioMovimientos movimientos, Auditoria auditoria,
                         Notificador notificador) {
        PublicadorDeEventos publicador = new PublicadorDeEventos();
        publicador.suscribir(new AvisosPorCorreo(notificador));
        this.servicioCuentas = new ServicioCuentas(cuentas, auditoria, publicador);
        this.operaciones = new OperacionesConReintentos(
                new OperacionesAuditadas(new ServicioMovimientos(cuentas, movimientos, publicador), auditoria), 20);
    }

    public void abrirCuenta(String numero, String titular, String email, String tipo, String moneda,
                            double saldoInicial, boolean esMenor) {
        servicioCuentas.abrir(numero, titular, email, tipo, moneda, saldoInicial, esMenor);
    }

    public double consultarSaldo(String numero) { return saldo(numero).monto().doubleValue(); }

    public Dinero saldo(String numero) { return servicioCuentas.consultar(numero).getSaldo(); }

    public Cuenta consultarCuenta(String numero) { return servicioCuentas.consultar(numero); }

    public void depositar(String numero, double monto, String referencia) {
        operaciones.depositar(numero, monto, referencia);
    }

    public void retirar(String numero, double monto) { operaciones.retirar(numero, monto); }

    public void transferir(String numeroOrigen, String numeroDestino, double monto) {
        operaciones.transferir(numeroOrigen, numeroDestino, monto);
    }

    public void bloquear(String numero, String motivo) { servicioCuentas.bloquear(numero, motivo); }

    public void desbloquear(String numero) { servicioCuentas.desbloquear(numero); }

    public void cerrar(String numero) { servicioCuentas.cerrar(numero); }

    public List<Movimiento> extracto(String numero) { return operaciones.extracto(numero); }
}
