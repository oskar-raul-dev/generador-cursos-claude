package banco;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

// Lo que mueve dinero. Cada operación es una transacción; los eventos se publican después de confirmarla.
public class ServicioMovimientos implements OperacionesCuenta {

    private final RepositorioCuentas cuentas;
    private final RepositorioMovimientos movimientos;
    private final PublicadorDeEventos publicador;
    private final Map<String, List<Movimiento>> cacheExtractos = new ConcurrentHashMap<>();   // por número
    private final Set<ClaveDeposito> recientes = ConcurrentHashMap.newKeySet();   // depósitos ya aplicados
    private final Regla reglasDeRetiro = Regla.cadena(
            Reglas.montoPositivo(), Reglas.origenPuedeRetirar(), Reglas.topeDeMenores("retirar"));
    private final Regla reglasDeTransferencia = Regla.cadena(
            Reglas.cuentasDistintas(), Reglas.montoPositivo(), Reglas.origenPuedeRetirar(),
            Reglas.destinoPuedeRecibir(), Reglas.mismaMoneda(), Reglas.topeDeMenores("transferir"));

    public ServicioMovimientos(RepositorioCuentas cuentas, RepositorioMovimientos movimientos,
                               PublicadorDeEventos publicador) {
        this.cuentas = cuentas;
        this.movimientos = movimientos;
        this.publicador = publicador;
    }

    @Override
    public boolean depositar(String numero, double monto, String referencia) {
        List<EventoDeCuenta> eventos = BaseDatos.enTransaccion(con -> {
            Cuenta c = cuentas.buscar(con, numero);
            if (monto <= 0) {
                throw new IllegalArgumentException("el monto debe ser positivo");
            }
            Dinero importe = Dinero.de(monto, c.getMoneda());
            c.depositar(importe);                               // la cuenta cerrada lanza aquí
            if (referencia != null && recientes.contains(new ClaveDeposito(numero, importe, referencia))) {
                return null;   // ya se aplicó: la pasarela reintentó
            }
            cuentas.guardar(con, c);
            movimientos.registrar(con, new Movimiento(numero, "DEPOSITO", importe, Dinero.cero(c.getMoneda()),
                    referencia, LocalDateTime.now()));
            if (referencia != null) {
                recientes.add(new ClaveDeposito(numero, importe, referencia));
            }
            return c.eventosNuevos();
        });
        if (eventos == null) {
            return false;
        }
        cacheExtractos.remove(numero);
        publicador.publicar(eventos);
        return true;
    }

    @Override
    public Movimiento retirar(String numero, double monto) {
        List<EventoDeCuenta> eventos = new ArrayList<>();
        Movimiento m = BaseDatos.enTransaccion(con -> {
            Cuenta c = cuentas.buscar(con, numero);
            Dinero importe = Dinero.de(monto, c.getMoneda());
            reglasDeRetiro.verificar(Solicitud.deRetiro(c, importe));
            Dinero comision = c.comisionDeRetiro(importe);
            c.retirar(importe, comision);
            cuentas.guardar(con, c);
            Movimiento retiro = new Movimiento(numero, "RETIRO", importe, comision, null, LocalDateTime.now());
            movimientos.registrar(con, retiro);
            eventos.addAll(c.eventosNuevos());
            return retiro;
        });
        cacheExtractos.remove(numero);
        publicador.publicar(eventos);
        return m;
    }

    @Override
    public Movimiento transferir(String numeroOrigen, String numeroDestino, double monto) {
        List<EventoDeCuenta> eventos = new ArrayList<>();
        Movimiento m = BaseDatos.enTransaccion(con -> {
            Cuenta origen = cuentas.buscar(con, numeroOrigen);
            Cuenta destino = cuentas.buscar(con, numeroDestino);
            Dinero importe = Dinero.de(monto, origen.getMoneda());
            reglasDeTransferencia.verificar(new Solicitud(origen, destino, importe));
            Dinero comision = origen.comisionDeTransferencia(importe);
            origen.debitar(importe, comision);
            destino.recibirTransferencia(importe, origen.getTitular());
            cuentas.guardar(con, origen);
            cuentas.guardar(con, destino);
            LocalDateTime ahora = LocalDateTime.now();
            Movimiento enviada = new Movimiento(numeroOrigen, "TRANSF_ENVIADA", importe, comision, numeroDestino, ahora);
            movimientos.registrar(con, enviada);
            movimientos.registrar(con, new Movimiento(numeroDestino, "TRANSF_RECIBIDA", importe,
                    Dinero.cero(destino.getMoneda()), numeroOrigen, ahora));
            eventos.addAll(origen.eventosNuevos());
            eventos.addAll(destino.eventosNuevos());
            return enviada;
        });
        cacheExtractos.remove(numeroOrigen);
        cacheExtractos.remove(numeroDestino);
        publicador.publicar(eventos);
        return m;
    }

    @Override
    public List<Movimiento> extracto(String numero) {
        return cacheExtractos.computeIfAbsent(numero, n -> BaseDatos.enTransaccion(con -> {
            Cuenta c = cuentas.buscar(con, n);
            return movimientos.deCuenta(con, n, c.getMoneda());
        }));
    }
}
