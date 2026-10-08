package banco;

import java.util.ArrayList;
import java.util.List;

// La cuenta, con las reglas que solo dependen de ella misma. Anota lo que le pasa; publicarlo no es asunto suyo.
public class Cuenta {

    private final String numero;
    private final String titular;
    private final String email;
    private final TipoCuenta tipo;
    private final Moneda moneda;
    private final boolean esMenor;
    private final int version;          // la que se leyó; guardar comprueba que no haya cambiado
    private Dinero saldo;
    private EstadoCuenta estado;
    private final List<EventoDeCuenta> eventos = new ArrayList<>();

    public Cuenta(String numero, String titular, String email, TipoCuenta tipo, Moneda moneda, Dinero saldo,
                  EstadoCuenta estado, boolean esMenor, int version) {
        this.numero = numero;
        this.titular = titular;
        this.email = email;
        this.tipo = tipo;
        this.moneda = moneda;
        this.saldo = saldo;
        this.estado = estado;
        this.esMenor = esMenor;
        this.version = version;
    }

    public static Cuenta abrir(String numero, String titular, String email, TipoCuenta tipo, Moneda moneda,
                               Dinero saldo, boolean esMenor) {
        Cuenta c = new Cuenta(numero, titular, email, tipo, moneda, saldo, EstadoCuenta.ABIERTA, esMenor, 0);
        c.eventos.add(new EventoDeCuenta.CuentaAbierta(numero, email));
        return c;
    }

    public void depositar(Dinero importe) {
        estado.alDepositar(numero);
        saldo = saldo.mas(importe);
        eventos.add(new EventoDeCuenta.DepositoRecibido(numero, email, importe));
    }

    public void recibirTransferencia(Dinero importe, String titularOrigen) {
        estado.alRecibir(numero);
        saldo = saldo.mas(importe);
        eventos.add(new EventoDeCuenta.TransferenciaRecibida(numero, email, importe, titularOrigen));
    }

    public void verificarQuePuedeRetirar() {
        estado.alRetirar(numero);
    }

    public void verificarQuePuedeRecibir() {
        estado.alRecibir(numero);
    }

    public void retirar(Dinero importe, Dinero comision) {
        debitar(importe, comision);
        eventos.add(new EventoDeCuenta.RetiroHecho(numero, email, importe));
    }

    public void debitar(Dinero importe, Dinero comision) {
        if (saldo.esMenorQue(importe.mas(comision))) {
            throw new IllegalStateException("saldo insuficiente en " + numero);
        }
        saldo = saldo.menos(importe).menos(comision);
    }

    public Dinero comisionDeRetiro(Dinero importe) { return tipo.comision().deRetiro(importe); }

    public Dinero comisionDeTransferencia(Dinero importe) { return tipo.comision().deTransferencia(importe); }

    public void bloquear(String motivo) {
        estado = estado.alBloquear(numero);
        eventos.add(new EventoDeCuenta.CuentaBloqueada(numero, email, motivo));
    }

    public void desbloquear() { estado = estado.alDesbloquear(numero); }

    public void cerrar() {
        estado = estado.alCerrar(numero, saldo);
        eventos.add(new EventoDeCuenta.CuentaCerrada(numero, email));
    }

    // entrega los eventos anotados y deja la lista vacía
    public List<EventoDeCuenta> eventosNuevos() {
        List<EventoDeCuenta> nuevos = List.copyOf(eventos);
        eventos.clear();
        return nuevos;
    }

    public String getNumero() { return numero; }
    public String getTitular() { return titular; }
    public String getEmail() { return email; }
    public TipoCuenta getTipo() { return tipo; }
    public Moneda getMoneda() { return moneda; }
    public Dinero getSaldo() { return saldo; }
    public EstadoCuenta getEstado() { return estado; }
    public int getVersion() { return version; }
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
