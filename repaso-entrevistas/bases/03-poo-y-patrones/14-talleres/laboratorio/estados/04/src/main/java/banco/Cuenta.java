package banco;

// La cuenta, con las reglas que solo dependen de ella misma. Su ciclo de vida lo decide su EstadoCuenta.
public class Cuenta {

    private final String numero;
    private final String titular;
    private final String email;
    private final TipoCuenta tipo;
    private final Moneda moneda;
    private final boolean esMenor;
    private Dinero saldo;
    private EstadoCuenta estado;

    public Cuenta(String numero, String titular, String email, TipoCuenta tipo, Moneda moneda, Dinero saldo,
                  EstadoCuenta estado, boolean esMenor) {
        this.numero = numero;
        this.titular = titular;
        this.email = email;
        this.tipo = tipo;
        this.moneda = moneda;
        this.saldo = saldo;
        this.estado = estado;
        this.esMenor = esMenor;
    }

    public void depositar(Dinero importe) {
        estado.alDepositar(numero);
        saldo = saldo.mas(importe);
    }

    public void recibirTransferencia(Dinero importe) {
        estado.alRecibir(numero);
        saldo = saldo.mas(importe);
    }

    public void verificarQuePuedeRetirar() {
        estado.alRetirar(numero);
    }

    public void verificarQuePuedeRecibir() {
        estado.alRecibir(numero);
    }

    public void debitar(Dinero importe, Dinero comision) {
        if (saldo.esMenorQue(importe.mas(comision))) {
            throw new IllegalStateException("saldo insuficiente en " + numero);
        }
        saldo = saldo.menos(importe).menos(comision);
    }

    public Dinero comisionDeRetiro(Dinero importe) { return tipo.comision().deRetiro(importe); }

    public Dinero comisionDeTransferencia(Dinero importe) { return tipo.comision().deTransferencia(importe); }

    public void bloquear() { estado = estado.alBloquear(numero); }

    public void desbloquear() { estado = estado.alDesbloquear(numero); }

    public void cerrar() { estado = estado.alCerrar(numero, saldo); }

    public String getNumero() { return numero; }
    public String getTitular() { return titular; }
    public String getEmail() { return email; }
    public TipoCuenta getTipo() { return tipo; }
    public Moneda getMoneda() { return moneda; }
    public Dinero getSaldo() { return saldo; }
    public EstadoCuenta getEstado() { return estado; }
    public boolean isBloqueada() { return estado == EstadoCuenta.BLOQUEADA; }
    public boolean isCerrada() { return estado == EstadoCuenta.CERRADA; }
    public boolean isEsMenor() { return esMenor; }

    // Una cuenta es la misma si tiene el mismo número, cambie lo que cambie su saldo.
    @Override
    public boolean equals(Object o) {
        return o instanceof Cuenta c && numero.equals(c.numero);
    }

    @Override
    public int hashCode() {
        return numero.hashCode();
    }
}
