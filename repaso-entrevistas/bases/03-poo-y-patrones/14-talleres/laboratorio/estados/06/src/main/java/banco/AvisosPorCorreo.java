package banco;

import java.util.function.Consumer;

// El suscriptor que decide qué evento merece un correo, y con qué texto.
public class AvisosPorCorreo implements Consumer<EventoDeCuenta> {

    private static final Dinero RETIRO_QUE_SE_AVISA = Dinero.de("1000000", Moneda.COP);

    private final Notificador notificador;

    public AvisosPorCorreo(Notificador notificador) {
        this.notificador = notificador;
    }

    @Override
    public void accept(EventoDeCuenta evento) {
        switch (evento) {
            case EventoDeCuenta.CuentaAbierta e ->
                    notificador.enviar(e.email(), "Tu cuenta " + e.numero() + " está abierta");
            case EventoDeCuenta.DepositoRecibido e ->
                    notificador.enviar(e.email(), "Recibiste un depósito de " + e.importe());
            case EventoDeCuenta.RetiroHecho e -> {
                Dinero umbral = new Dinero(RETIRO_QUE_SE_AVISA.monto(), e.importe().moneda());
                if (!e.importe().esMenorQue(umbral)) {
                    notificador.enviar(e.email(), "Retiraste " + e.importe());
                }
            }
            case EventoDeCuenta.TransferenciaRecibida e ->
                    notificador.enviar(e.email(), "Recibiste " + e.importe() + " de " + e.titularOrigen());
            case EventoDeCuenta.CuentaBloqueada e ->
                    notificador.enviar(e.email(), "Tu cuenta " + e.numero() + " fue bloqueada: " + e.motivo());
            case EventoDeCuenta.CuentaCerrada e ->
                    notificador.enviar(e.email(), "Tu cuenta " + e.numero() + " quedó cerrada");
        }
    }
}
