package banco;

import java.util.Objects;

// La cuenta: datos y nada más. Las reglas viven en GestorCuentas.
public class Cuenta {

    private String numero;
    private String titular;
    private String email;
    private String tipo;        // "AHORROS", "CORRIENTE" o "NOMINA"
    private String moneda;      // "COP" o "USD"
    private double saldo;
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
    public String getMoneda() { return moneda; }
    public void setMoneda(String moneda) { this.moneda = moneda; }
    public double getSaldo() { return saldo; }
    public void setSaldo(double saldo) { this.saldo = saldo; }
    public boolean isBloqueada() { return bloqueada; }
    public void setBloqueada(boolean bloqueada) { this.bloqueada = bloqueada; }
    public boolean isCerrada() { return cerrada; }
    public void setCerrada(boolean cerrada) { this.cerrada = cerrada; }
    public boolean isEsMenor() { return esMenor; }
    public void setEsMenor(boolean esMenor) { this.esMenor = esMenor; }

    // Generados por el IDE, con todos los campos.
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Cuenta c = (Cuenta) o;
        return Double.compare(c.saldo, saldo) == 0 && bloqueada == c.bloqueada && cerrada == c.cerrada
                && esMenor == c.esMenor && Objects.equals(numero, c.numero) && Objects.equals(titular, c.titular)
                && Objects.equals(email, c.email) && Objects.equals(tipo, c.tipo) && Objects.equals(moneda, c.moneda);
    }

    @Override
    public int hashCode() {
        return Objects.hash(numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, esMenor);
    }
}
