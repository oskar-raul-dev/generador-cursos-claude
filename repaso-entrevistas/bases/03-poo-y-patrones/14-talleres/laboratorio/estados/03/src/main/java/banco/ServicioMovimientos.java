package banco;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

// Lo que mueve dinero: depósitos, retiros, transferencias y el extracto.
public class ServicioMovimientos {

    private final RepositorioCuentas cuentas;
    private final RepositorioMovimientos movimientos;
    private final Auditoria auditoria;
    private final Notificador notificador;
    private final Map<String, List<Movimiento>> cacheExtractos = new HashMap<>();   // por número: no cambia
    private final Set<ClaveDeposito> recientes = new HashSet<>();   // para no aplicar dos veces un depósito

    public ServicioMovimientos(RepositorioCuentas cuentas, RepositorioMovimientos movimientos, Auditoria auditoria,
                               Notificador notificador) {
        this.cuentas = cuentas;
        this.movimientos = movimientos;
        this.auditoria = auditoria;
        this.notificador = notificador;
    }

    public void depositar(String numero, double monto, String referencia) {
        Cuenta c = cuentas.buscar(numero);
        if (monto <= 0) {
            throw new IllegalArgumentException("el monto debe ser positivo");
        }
        Dinero importe = Dinero.de(monto, c.getMoneda());
        c.depositar(importe);                                   // la cuenta cerrada lanza aquí
        ClaveDeposito clave = new ClaveDeposito(numero, importe, referencia);
        if (referencia != null && !recientes.add(clave)) {
            return;   // ya se aplicó: la pasarela reintentó
        }
        cuentas.guardar(c);
        movimientos.registrar(new Movimiento(numero, "DEPOSITO", importe, Dinero.cero(c.getMoneda()), referencia,
                LocalDateTime.now()));
        cacheExtractos.remove(numero);
        auditoria.registrar("DEPOSITO", numero + " " + importe + " ref " + referencia);
        notificador.enviar(c.getEmail(), "Recibiste un depósito de " + importe);
    }

    public void retirar(String numero, double monto) {
        Cuenta c = cuentas.buscar(numero);
        if (monto <= 0) {
            throw new IllegalArgumentException("el monto debe ser positivo");
        } else if (c.isBloqueada()) {
            throw new IllegalStateException("la cuenta " + numero + " está bloqueada");
        } else if (c.isCerrada()) {
            throw new IllegalStateException("la cuenta " + numero + " está cerrada");
        }
        Dinero importe = Dinero.de(monto, c.getMoneda());
        if (c.isEsMenor() && importe.esMayorQue(Dinero.de("200000", c.getMoneda()))) {
            throw new IllegalStateException("un menor no puede retirar más de 200000");
        }
        Dinero comision = comisionDeRetiro(c, importe);
        c.debitar(importe, comision);
        cuentas.guardar(c);
        movimientos.registrar(new Movimiento(numero, "RETIRO", importe, comision, null, LocalDateTime.now()));
        cacheExtractos.remove(numero);
        auditoria.registrar("RETIRO", numero + " " + importe + " comisión " + comision);
        if (!importe.esMenorQue(Dinero.de("1000000", c.getMoneda()))) {
            notificador.enviar(c.getEmail(), "Retiraste " + importe);
        }
    }

    public void transferir(String numeroOrigen, String numeroDestino, double monto) {
        Cuenta origen = cuentas.buscar(numeroOrigen);
        Cuenta destino = cuentas.buscar(numeroDestino);
        if (numeroOrigen.equals(numeroDestino)) {
            throw new IllegalArgumentException("origen y destino son la misma cuenta");
        } else if (monto <= 0) {
            throw new IllegalArgumentException("el monto debe ser positivo");
        } else if (origen.isBloqueada()) {
            throw new IllegalStateException("la cuenta " + numeroOrigen + " está bloqueada");
        } else if (origen.isCerrada()) {
            throw new IllegalStateException("la cuenta " + numeroOrigen + " está cerrada");
        } else if (destino.isBloqueada()) {
            throw new IllegalStateException("la cuenta destino " + numeroDestino + " está bloqueada");
        } else if (origen.getMoneda() != destino.getMoneda()) {
            throw new IllegalArgumentException("las cuentas tienen monedas distintas");
        }
        Dinero importe = Dinero.de(monto, origen.getMoneda());
        Dinero comision = comisionDeTransferencia(origen, importe);
        origen.debitar(importe, comision);
        destino.recibirTransferencia(importe);
        cuentas.guardar(origen);
        cuentas.guardar(destino);
        LocalDateTime ahora = LocalDateTime.now();
        movimientos.registrar(new Movimiento(numeroOrigen, "TRANSF_ENVIADA", importe, comision, numeroDestino, ahora));
        movimientos.registrar(new Movimiento(numeroDestino, "TRANSF_RECIBIDA", importe, Dinero.cero(destino.getMoneda()),
                numeroOrigen, ahora));
        cacheExtractos.remove(numeroOrigen);
        cacheExtractos.remove(numeroDestino);
        auditoria.registrar("TRANSFERENCIA", numeroOrigen + " -> " + numeroDestino + " " + importe + " comisión " + comision);
        notificador.enviar(destino.getEmail(), "Recibiste " + importe + " de " + origen.getTitular());
    }

    public List<Movimiento> extracto(String numero) {
        Cuenta c = cuentas.buscar(numero);
        return cacheExtractos.computeIfAbsent(numero, n -> movimientos.deCuenta(n, c.getMoneda()));
    }

    private Dinero comisionDeRetiro(Cuenta c, Dinero importe) {
        switch (c.getTipo()) {
            case "AHORROS":
                return c.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.cero(c.getMoneda());
            case "CORRIENTE":
                return c.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.de("1500", Moneda.COP);
            case "NOMINA":
                return importe.esMayorQue(Dinero.de("2000000", Moneda.COP)) ? importe.por("0.004") : Dinero.cero(Moneda.COP);
            default:
                throw new IllegalStateException("tipo desconocido " + c.getTipo());
        }
    }

    private Dinero comisionDeTransferencia(Cuenta c, Dinero importe) {
        switch (c.getTipo()) {
            case "AHORROS":
                return c.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.cero(c.getMoneda());
            case "CORRIENTE":
                return c.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.de("1000", Moneda.COP);
            case "NOMINA":
                return importe.esMayorQue(Dinero.de("2000000", Moneda.COP)) ? importe.por("0.004") : Dinero.cero(Moneda.COP);
            default:
                throw new IllegalStateException("tipo desconocido " + c.getTipo());
        }
    }
}
