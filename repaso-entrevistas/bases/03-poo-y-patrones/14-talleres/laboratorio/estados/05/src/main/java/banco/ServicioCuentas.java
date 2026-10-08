package banco;

// El ciclo de vida de una cuenta: abrir, bloquear, desbloquear, cerrar.
public class ServicioCuentas {

    private final RepositorioCuentas cuentas;
    private final Auditoria auditoria;
    private final Notificador notificador;

    public ServicioCuentas(RepositorioCuentas cuentas, Auditoria auditoria, Notificador notificador) {
        this.cuentas = cuentas;
        this.auditoria = auditoria;
        this.notificador = notificador;
    }

    public void abrir(String numero, String titular, String email, String tipo, String moneda,
                      double saldoInicial, boolean esMenor) {
        if (numero == null || numero.isBlank()) {
            throw new IllegalArgumentException("el número es obligatorio");
        } else if (titular == null || titular.isBlank()) {
            throw new IllegalArgumentException("el titular es obligatorio");
        } else if (email == null || !email.contains("@")) {
            throw new IllegalArgumentException("email inválido");
        } else if (!esTipoConocido(tipo)) {
            throw new IllegalArgumentException("tipo de cuenta desconocido: " + tipo);
        } else if (!moneda.equals("COP") && !moneda.equals("USD")) {
            throw new IllegalArgumentException("moneda no soportada: " + moneda);
        } else if (saldoInicial < 0) {
            throw new IllegalArgumentException("el saldo inicial no puede ser negativo");
        } else if (tipo.equals("NOMINA") && !moneda.equals("COP")) {
            throw new IllegalArgumentException("la cuenta nómina solo existe en COP");
        }
        Moneda m = Moneda.valueOf(moneda);
        Dinero saldo = Dinero.de(saldoInicial, m);
        cuentas.insertar(new Cuenta(numero, titular, email, TipoCuenta.valueOf(tipo), m, saldo, EstadoCuenta.ABIERTA, esMenor));
        auditoria.registrar("ABRIR", numero + " " + tipo + " " + moneda + " saldo " + saldo);
        notificador.enviar(email, "Tu cuenta " + numero + " está abierta");
    }

    private static boolean esTipoConocido(String tipo) {
        for (TipoCuenta t : TipoCuenta.values()) {
            if (t.name().equals(tipo)) return true;
        }
        return false;
    }

    public Cuenta consultar(String numero) {
        return cuentas.buscar(numero);
    }

    public void bloquear(String numero, String motivo) {
        Cuenta c = cuentas.buscar(numero);
        c.bloquear();
        cuentas.guardar(c);
        auditoria.registrar("BLOQUEAR", numero + " " + motivo);
        notificador.enviar(c.getEmail(), "Tu cuenta " + numero + " fue bloqueada: " + motivo);
    }

    public void desbloquear(String numero) {
        Cuenta c = cuentas.buscar(numero);
        c.desbloquear();
        cuentas.guardar(c);
        auditoria.registrar("DESBLOQUEAR", numero);
    }

    public void cerrar(String numero) {
        Cuenta c = cuentas.buscar(numero);
        c.cerrar();
        cuentas.guardar(c);
        auditoria.registrar("CERRAR", numero);
        notificador.enviar(c.getEmail(), "Tu cuenta " + numero + " quedó cerrada");
    }
}
