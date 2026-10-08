package banco;

// La cuenta, con las reglas que solo dependen de ella misma.
public class Cuenta {

    private final String numero;
    private final String titular;
    private final String email;
    private final String tipo;        // "AHORROS", "CORRIENTE" o "NOMINA"
    private final Moneda moneda;
    private final boolean esMenor;
    private Dinero saldo;
    private boolean bloqueada;
    private boolean cerrada;

    public Cuenta(String numero, String titular, String email, String tipo, Moneda moneda, Dinero saldo,
                  boolean bloqueada, boolean cerrada, boolean esMenor) {
        this.numero = numero;
        this.titular = titular;
        this.email = email;
        this.tipo = tipo;
        this.moneda = moneda;
        this.saldo = saldo;
        this.bloqueada = bloqueada;
        this.cerrada = cerrada;
        this.esMenor = esMenor;
    }

    public void depositar(Dinero importe) {
        if (cerrada) {
            throw new IllegalStateException("la cuenta " + numero + " está cerrada");
        }
        saldo = saldo.mas(importe);
    }

    // DEFECTO CONGELADO hasta 14/04: a diferencia de depositar, no mira si la cuenta está cerrada
    public void recibirTransferencia(Dinero importe) {
        saldo = saldo.mas(importe);
    }

    public void debitar(Dinero importe, Dinero comision) {
        if (saldo.esMenorQue(importe.mas(comision))) {
            throw new IllegalStateException("saldo insuficiente en " + numero);
        }
        saldo = saldo.menos(importe).menos(comision);
    }

    public void bloquear() { bloqueada = true; }

    public void desbloquear() { bloqueada = false; }

    public void cerrar() {
        if (bloqueada) {
            throw new IllegalStateException("una cuenta bloqueada no se puede cerrar");
        } else if (!saldo.esCero()) {
            throw new IllegalStateException("para cerrar, el saldo debe ser cero");
        }
        cerrada = true;
    }

    public String getNumero() { return numero; }
    public String getTitular() { return titular; }
    public String getEmail() { return email; }
    public String getTipo() { return tipo; }
    public Moneda getMoneda() { return moneda; }
    public Dinero getSaldo() { return saldo; }
    public boolean isBloqueada() { return bloqueada; }
    public boolean isCerrada() { return cerrada; }
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
