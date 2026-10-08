package banco;

import java.time.LocalDateTime;
import java.util.Objects;

public class Movimiento {

    private String numeroCuenta;
    private String tipo;          // "DEPOSITO", "RETIRO", "TRANSF_ENVIADA", "TRANSF_RECIBIDA"
    private double monto;
    private double comision;
    private String referencia;    // la del banco o la pasarela que originó el depósito
    private LocalDateTime fecha;

    public Movimiento(String numeroCuenta, String tipo, double monto, double comision, String referencia,
                      LocalDateTime fecha) {
        this.numeroCuenta = numeroCuenta;
        this.tipo = tipo;
        this.monto = monto;
        this.comision = comision;
        this.referencia = referencia;
        this.fecha = fecha;
    }

    public String getNumeroCuenta() { return numeroCuenta; }
    public String getTipo() { return tipo; }
    public double getMonto() { return monto; }
    public double getComision() { return comision; }
    public String getReferencia() { return referencia; }
    public LocalDateTime getFecha() { return fecha; }

    // Dos movimientos son el mismo si tienen la misma cuenta, tipo, monto y referencia.
    @Override
    public boolean equals(Object o) {
        if (!(o instanceof Movimiento m)) return false;
        return Objects.equals(numeroCuenta, m.numeroCuenta) && Objects.equals(tipo, m.tipo)
                && monto == m.monto && Objects.equals(referencia, m.referencia);
    }

    @Override
    public String toString() {
        return tipo + " " + monto + (comision > 0 ? " (comisión " + comision + ")" : "")
                + (referencia != null ? " ref " + referencia : "");
    }
}
