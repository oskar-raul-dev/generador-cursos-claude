package banco;

import java.util.List;

// El ciclo de vida de una cuenta: abrir, bloquear, desbloquear, cerrar.
public class ServicioCuentas {

    private final RepositorioCuentas cuentas;
    private final Auditoria auditoria;
    private final PublicadorDeEventos publicador;

    public ServicioCuentas(RepositorioCuentas cuentas, Auditoria auditoria, PublicadorDeEventos publicador) {
        this.cuentas = cuentas;
        this.auditoria = auditoria;
        this.publicador = publicador;
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
        Cuenta c = Cuenta.abrir(numero, titular, email, TipoCuenta.valueOf(tipo), m, saldo, esMenor);
        BaseDatos.enTransaccion(con -> {
            cuentas.insertar(con, c);
            return null;
        });
        auditoria.registrar("ABRIR", numero + " " + tipo + " " + moneda + " saldo " + saldo);
        publicador.publicar(c.eventosNuevos());
    }

    private static boolean esTipoConocido(String tipo) {
        for (TipoCuenta t : TipoCuenta.values()) {
            if (t.name().equals(tipo)) return true;
        }
        return false;
    }

    public Cuenta consultar(String numero) {
        return BaseDatos.enTransaccion(con -> cuentas.buscar(con, numero));
    }

    public void bloquear(String numero, String motivo) {
        List<EventoDeCuenta> eventos = BaseDatos.enTransaccion(con -> {
            Cuenta c = cuentas.buscar(con, numero);
            c.bloquear(motivo);
            cuentas.guardar(con, c);
            return c.eventosNuevos();
        });
        auditoria.registrar("BLOQUEAR", numero + " " + motivo);
        publicador.publicar(eventos);
    }

    public void desbloquear(String numero) {
        BaseDatos.enTransaccion(con -> {
            Cuenta c = cuentas.buscar(con, numero);
            c.desbloquear();
            cuentas.guardar(con, c);
            return null;
        });
        auditoria.registrar("DESBLOQUEAR", numero);
    }

    public void cerrar(String numero) {
        List<EventoDeCuenta> eventos = BaseDatos.enTransaccion(con -> {
            Cuenta c = cuentas.buscar(con, numero);
            c.cerrar();
            cuentas.guardar(con, c);
            return c.eventosNuevos();
        });
        auditoria.registrar("CERRAR", numero);
        publicador.publicar(eventos);
    }
}
