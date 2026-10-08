package banco;

// La cuenta: datos y nada más. Las reglas viven en GestorCuentas.
public class Cuenta {

    private String numero;
    private String titular;
    private String email;
    private String tipo;        // "AHORROS", "CORRIENTE" o "NOMINA"
    private Moneda moneda;
    private Dinero saldo;
    private boolean bloqueada;
    private boolean cerrada;
    private boolean esMenor;

    public String getNumero() { return numero; }
    public void setNumero(String numero) { this.numero = numero; }
    public String getTitular() { return titular; }
    public void setTitular(String titular) { this.titular = titular; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    public Moneda getMoneda() { return moneda; }
    public void setMoneda(Moneda moneda) { this.moneda = moneda; }
    public Dinero getSaldo() { return saldo; }
    public void setSaldo(Dinero saldo) { this.saldo = saldo; }
    public boolean isBloqueada() { return bloqueada; }
    public void setBloqueada(boolean bloqueada) { this.bloqueada = bloqueada; }
    public boolean isCerrada() { return cerrada; }
    public void setCerrada(boolean cerrada) { this.cerrada = cerrada; }
    public boolean isEsMenor() { return esMenor; }
    public void setEsMenor(boolean esMenor) { this.esMenor = esMenor; }

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
