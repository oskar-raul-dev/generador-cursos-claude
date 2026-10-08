package banco;

import java.time.LocalDateTime;

// Inmutable: un record trae equals y hashCode coherentes con todos sus componentes.
public record Movimiento(String numeroCuenta, String tipo, Dinero monto, Dinero comision, String referencia,
                         LocalDateTime fecha) {

    @Override
    public String toString() {
        return tipo + " " + monto + (comision.esCero() ? "" : " (comisión " + comision + ")")
                + (referencia != null ? " ref " + referencia : "");
    }
}
