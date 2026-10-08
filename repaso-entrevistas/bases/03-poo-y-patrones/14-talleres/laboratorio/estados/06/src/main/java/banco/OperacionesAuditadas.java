package banco;

import java.util.List;

// Decorator: audita lo que hace otro OperacionesCuenta, sin que este sepa que existe la auditoría.
public final class OperacionesAuditadas implements OperacionesCuenta {

    private final OperacionesCuenta envuelto;
    private final Auditoria auditoria;

    public OperacionesAuditadas(OperacionesCuenta envuelto, Auditoria auditoria) {
        this.envuelto = envuelto;
        this.auditoria = auditoria;
    }

    @Override
    public boolean depositar(String numero, double monto, String referencia) {
        boolean aplicado = envuelto.depositar(numero, monto, referencia);
        if (aplicado) {
            auditoria.registrar("DEPOSITO", numero + " " + monto + " ref " + referencia);
        }
        return aplicado;
    }

    @Override
    public Movimiento retirar(String numero, double monto) {
        Movimiento m = envuelto.retirar(numero, monto);   // si lanza, no se audita: igual que antes
        auditoria.registrar("RETIRO", numero + " " + m.monto() + " comisión " + m.comision());
        return m;
    }

    @Override
    public Movimiento transferir(String numeroOrigen, String numeroDestino, double monto) {
        Movimiento m = envuelto.transferir(numeroOrigen, numeroDestino, monto);
        auditoria.registrar("TRANSFERENCIA", numeroOrigen + " -> " + numeroDestino + " " + m.monto()
                + " comisión " + m.comision());
        return m;
    }

    @Override
    public List<Movimiento> extracto(String numero) {
        return envuelto.extracto(numero);                  // las consultas no se auditan
    }
}
