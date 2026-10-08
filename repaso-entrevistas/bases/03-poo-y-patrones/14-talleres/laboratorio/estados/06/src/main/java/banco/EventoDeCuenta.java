package banco;

// Lo que le pasó a una cuenta, dicho en pasado. Lleva lo que un suscriptor necesita, sin volver a la base.
public sealed interface EventoDeCuenta {

    String numero();

    record CuentaAbierta(String numero, String email) implements EventoDeCuenta { }

    record DepositoRecibido(String numero, String email, Dinero importe) implements EventoDeCuenta { }

    record RetiroHecho(String numero, String email, Dinero importe) implements EventoDeCuenta { }

    record TransferenciaRecibida(String numero, String email, Dinero importe, String titularOrigen)
            implements EventoDeCuenta { }

    record CuentaBloqueada(String numero, String email, String motivo) implements EventoDeCuenta { }

    record CuentaCerrada(String numero, String email) implements EventoDeCuenta { }
}
