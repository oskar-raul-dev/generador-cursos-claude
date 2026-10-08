package banco;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

// Lo que mueve dinero: depósitos, retiros, transferencias y el extracto. Ya no audita: lo hace su decorador.
public class ServicioMovimientos implements OperacionesCuenta {

    private final RepositorioCuentas cuentas;
    private final RepositorioMovimientos movimientos;
    private final Notificador notificador;
    private final Map<String, List<Movimiento>> cacheExtractos = new HashMap<>();   // por número: no cambia
    private final Set<ClaveDeposito> recientes = new HashSet<>();   // para no aplicar dos veces un depósito

    private final Regla reglasDeRetiro = Regla.cadena(
            Reglas.montoPositivo(), Reglas.origenPuedeRetirar(), Reglas.topeDeMenores("retirar"));
    private final Regla reglasDeTransferencia = Regla.cadena(
            Reglas.cuentasDistintas(), Reglas.montoPositivo(), Reglas.origenPuedeRetirar(),
            Reglas.destinoPuedeRecibir(), Reglas.mismaMoneda(), Reglas.topeDeMenores("transferir"));

    public ServicioMovimientos(RepositorioCuentas cuentas, RepositorioMovimientos movimientos, Notificador notificador) {
        this.cuentas = cuentas;
        this.movimientos = movimientos;
        this.notificador = notificador;
    }

    @Override
    public boolean depositar(String numero, double monto, String referencia) {
        Cuenta c = cuentas.buscar(numero);
        if (monto <= 0) {
            throw new IllegalArgumentException("el monto debe ser positivo");
        }
        Dinero importe = Dinero.de(monto, c.getMoneda());
        c.depositar(importe);                                   // la cuenta cerrada lanza aquí
        ClaveDeposito clave = new ClaveDeposito(numero, importe, referencia);
        if (referencia != null && !recientes.add(clave)) {
            return false;   // ya se aplicó: la pasarela reintentó
        }
        cuentas.guardar(c);
        movimientos.registrar(new Movimiento(numero, "DEPOSITO", importe, Dinero.cero(c.getMoneda()), referencia,
                LocalDateTime.now()));
        cacheExtractos.remove(numero);
        notificador.enviar(c.getEmail(), "Recibiste un depósito de " + importe);
        return true;
    }

    @Override
    public Movimiento retirar(String numero, double monto) {
        Cuenta c = cuentas.buscar(numero);
        Dinero importe = Dinero.de(monto, c.getMoneda());
        reglasDeRetiro.verificar(Solicitud.deRetiro(c, importe));
        Dinero comision = c.comisionDeRetiro(importe);
        c.debitar(importe, comision);
        cuentas.guardar(c);
        Movimiento m = new Movimiento(numero, "RETIRO", importe, comision, null, LocalDateTime.now());
        movimientos.registrar(m);
        cacheExtractos.remove(numero);
        if (!importe.esMenorQue(Dinero.de("1000000", c.getMoneda()))) {
            notificador.enviar(c.getEmail(), "Retiraste " + importe);
        }
        return m;
    }

    @Override
    public Movimiento transferir(String numeroOrigen, String numeroDestino, double monto) {
        Cuenta origen = cuentas.buscar(numeroOrigen);
        Cuenta destino = cuentas.buscar(numeroDestino);
        Dinero importe = Dinero.de(monto, origen.getMoneda());
        reglasDeTransferencia.verificar(new Solicitud(origen, destino, importe));
        Dinero comision = origen.comisionDeTransferencia(importe);
        origen.debitar(importe, comision);
        destino.recibirTransferencia(importe);
        cuentas.guardar(origen);
        cuentas.guardar(destino);
        LocalDateTime ahora = LocalDateTime.now();
        Movimiento enviada = new Movimiento(numeroOrigen, "TRANSF_ENVIADA", importe, comision, numeroDestino, ahora);
        movimientos.registrar(enviada);
        movimientos.registrar(new Movimiento(numeroDestino, "TRANSF_RECIBIDA", importe, Dinero.cero(destino.getMoneda()),
                numeroOrigen, ahora));
        cacheExtractos.remove(numeroOrigen);
        cacheExtractos.remove(numeroDestino);
        notificador.enviar(destino.getEmail(), "Recibiste " + importe + " de " + origen.getTitular());
        return enviada;
    }

    @Override
    public List<Movimiento> extracto(String numero) {
        Cuenta c = cuentas.buscar(numero);
        return cacheExtractos.computeIfAbsent(numero, n -> movimientos.deCuenta(n, c.getMoneda()));
    }
}
