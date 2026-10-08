package banco;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

// Congela lo que GestorCuentas hace HOY, defectos incluidos. Una prueba en rojo no dice
// "esto está mal": dice "esto cambió". Los defectos llevan el comentario DEFECTO CONGELADO.
class CaracterizacionTest {

    private GestorCuentas gestor;

    @BeforeEach
    void baseLimpia() {
        BaseDatos.crearEsquema();
        Notificador.ENVIADOS.clear();
        gestor = new GestorCuentas();
        gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
        gestor.abrirCuenta("CTA-0002", "Carmen Díaz Ortega", "carmen.diaz@example.com", "CORRIENTE", "USD", 2_300.00, false);
        gestor.abrirCuenta("CTA-0003", "Luis Rojas Paz", "ana.rojas@example.com", "AHORROS", "COP", 0, true);
        Notificador.ENVIADOS.clear();
    }

    // --- apertura -------------------------------------------------------------------------

    @Test
    void abrir_dejaElSaldoInicialYAvisaAlTitular() {
        gestor.abrirCuenta("CTA-0004", "Ana Rojas Medina", "ana.rojas@example.com", "NOMINA", "COP", 5_000_000, false);
        assertEquals(5_000_000.0, gestor.consultarSaldo("CTA-0004"));
        assertEquals(List.of("ana.rojas@example.com: Tu cuenta CTA-0004 está abierta"), Notificador.ENVIADOS);
    }

    @Test
    void abrir_rechazaLosDatosInvalidosConSuMensaje() {
        assertMensaje("email inválido",
                () -> gestor.abrirCuenta("CTA-0009", "Ana", "sin-arroba", "AHORROS", "COP", 0, false));
        assertMensaje("tipo de cuenta desconocido: CDT",
                () -> gestor.abrirCuenta("CTA-0009", "Ana", "a@example.com", "CDT", "COP", 0, false));
        assertMensaje("la cuenta nómina solo existe en COP",
                () -> gestor.abrirCuenta("CTA-0009", "Ana", "a@example.com", "NOMINA", "USD", 0, false));
    }

    // --- depósitos ------------------------------------------------------------------------

    @Test
    void depositar_sumaElMontoYAvisa() {
        gestor.depositar("CTA-0001", 80_000, "PSE-7781");
        assertEquals(1_580_000.0, gestor.consultarSaldo("CTA-0001"));
        assertEquals(List.of("ana.rojas@example.com: Recibiste un depósito de 80000.00 COP"), Notificador.ENVIADOS);
    }

    @Test
    void depositar_enUnaCuentaBloqueadaSeAcepta() {
        gestor.bloquear("CTA-0001", "embargo");
        gestor.depositar("CTA-0001", 80_000, null);
        assertEquals(1_580_000.0, gestor.consultarSaldo("CTA-0001"));
    }

    @Test
    void depositar_elMismoPagoDosVecesLoAplicaUnaVez() {
        // corregido en 14/02: la clave del depósito es un record, con equals y hashCode coherentes
        gestor.depositar("CTA-0001", 80_000, "PSE-7781");
        gestor.depositar("CTA-0001", 80_000, "PSE-7781");
        assertEquals(1_580_000.0, gestor.consultarSaldo("CTA-0001"));
    }

    // --- retiros --------------------------------------------------------------------------

    @Test
    void retirar_cobraLaComisionDelTipoDeCuenta() {
        gestor.retirar("CTA-0001", 100_000);                 // ahorros en COP: sin comisión
        gestor.retirar("CTA-0002", 100);                     // corriente en USD: 2.5
        assertEquals(1_400_000.0, gestor.consultarSaldo("CTA-0001"));
        assertEquals(2_197.5, gestor.consultarSaldo("CTA-0002"));
    }

    @Test
    void retirar_deUnaCorrienteEnPesosCobra1500() {
        gestor.abrirCuenta("CTA-0005", "Carmen Díaz Ortega", "carmen.diaz@example.com", "CORRIENTE", "COP", 100_000, false);
        gestor.retirar("CTA-0005", 10_000);
        assertEquals(88_500.0, gestor.consultarSaldo("CTA-0005"));
    }

    @Test
    void retirar_deNominaGrandeRedondeaLaComisionAlCentavo() {
        // corregido en 14/02: Dinero redondea a dos decimales, a la par
        gestor.abrirCuenta("CTA-0004", "Ana Rojas Medina", "ana.rojas@example.com", "NOMINA", "COP", 5_000_000, false);
        gestor.retirar("CTA-0004", 2_500_000.10);
        assertEquals(Dinero.de("10000.00", Moneda.COP), gestor.extracto("CTA-0004").get(0).comision());
        assertEquals(Dinero.de("2489999.90", Moneda.COP), gestor.saldo("CTA-0004"));
    }

    @Test
    void retirar_rechazaSinSaldoBloqueadaYMenorSobreElTope() {
        assertMensaje("saldo insuficiente en CTA-0002", () -> gestor.retirar("CTA-0002", 2_299));
        assertMensaje("un menor no puede retirar más de 200000", () -> gestor.retirar("CTA-0003", 250_000));
        gestor.bloquear("CTA-0001", "embargo");
        assertMensaje("la cuenta CTA-0001 está bloqueada", () -> gestor.retirar("CTA-0001", 1));
    }

    @Test
    void retirar_soloAvisaDesdeUnMillon() {
        gestor.retirar("CTA-0001", 999_999);
        gestor.retirar("CTA-0001", 500_001);
        assertEquals(List.of(), Notificador.ENVIADOS);
        gestor.depositar("CTA-0001", 1_000_000, null);
        Notificador.ENVIADOS.clear();
        gestor.retirar("CTA-0001", 1_000_000);
        assertEquals(List.of("ana.rojas@example.com: Retiraste 1000000.00 COP"), Notificador.ENVIADOS);
    }

    // --- transferencias -------------------------------------------------------------------

    @Test
    void transferir_elEjemploDelCorpus() {
        gestor.transferir("CTA-0001", "CTA-0003", 250_000);
        assertEquals(1_250_000.0, gestor.consultarSaldo("CTA-0001"));
        assertEquals(250_000.0, gestor.consultarSaldo("CTA-0003"));
        assertEquals(List.of("ana.rojas@example.com: Recibiste 250000.00 COP de Ana Rojas Medina"), Notificador.ENVIADOS);
    }

    @Test
    void transferir_desdeUnaCorrienteEnPesosCobra1000() {
        // no es un defecto conocido: retiro y transferencia cobran distinto; se congela tal cual
        gestor.abrirCuenta("CTA-0005", "Carmen Díaz Ortega", "carmen.diaz@example.com", "CORRIENTE", "COP", 100_000, false);
        gestor.transferir("CTA-0005", "CTA-0001", 10_000);
        assertEquals(89_000.0, gestor.consultarSaldo("CTA-0005"));
    }

    @Test
    void transferir_rechazaLoQueValida() {
        assertMensaje("origen y destino son la misma cuenta", () -> gestor.transferir("CTA-0001", "CTA-0001", 1));
        assertMensaje("las cuentas tienen monedas distintas", () -> gestor.transferir("CTA-0001", "CTA-0002", 1));
        gestor.bloquear("CTA-0003", "revisión");
        assertMensaje("la cuenta destino CTA-0003 está bloqueada", () -> gestor.transferir("CTA-0001", "CTA-0003", 1));
    }

    @Test
    void transferir_aUnaCuentaCerradaSeRechaza() {
        // corregido en 14/04: el estado CERRADA no recibe dinero
        gestor.abrirCuenta("CTA-0005", "Carmen Díaz Ortega", "carmen.diaz@example.com", "AHORROS", "COP", 0, false);
        gestor.cerrar("CTA-0005");
        assertMensaje("la cuenta destino CTA-0005 está cerrada", () -> gestor.transferir("CTA-0001", "CTA-0005", 10_000));
        assertEquals(0.0, gestor.consultarSaldo("CTA-0005"));
    }

    @Test
    void transferir_unMenorNoPasaElTope() {
        // corregido en 14/05: el tope es un eslabón que comparten el retiro y la transferencia
        gestor.transferir("CTA-0001", "CTA-0003", 250_000);
        assertMensaje("un menor no puede transferir más de 200000", () -> gestor.transferir("CTA-0003", "CTA-0001", 250_000));
        assertEquals(250_000.0, gestor.consultarSaldo("CTA-0003"));
    }

    // --- ciclo de vida --------------------------------------------------------------------

    @Test
    void cerrar_exigeSaldoCeroYQueNoEsteBloqueada() {
        assertMensaje("para cerrar, el saldo debe ser cero", () -> gestor.cerrar("CTA-0001"));
        gestor.bloquear("CTA-0003", "revisión");
        assertMensaje("una cuenta bloqueada no se puede cerrar", () -> gestor.cerrar("CTA-0003"));
    }

    @Test
    void bloquear_unaCuentaCerradaSeRechaza() {
        // corregido en 14/04: un solo estado, y CERRADA no pasa a BLOQUEADA
        gestor.cerrar("CTA-0003");
        assertMensaje("una cuenta cerrada no se puede bloquear", () -> gestor.bloquear("CTA-0003", "revisión"));
        assertEquals(EstadoCuenta.CERRADA, gestor.consultarCuenta("CTA-0003").getEstado());
    }

    // --- extracto y auditoría -------------------------------------------------------------

    @Test
    void extracto_listaLosMovimientosEnOrden() {
        gestor.depositar("CTA-0001", 80_000, "PSE-7781");
        gestor.retirar("CTA-0001", 30_000);
        assertEquals("[DEPOSITO 80000.00 COP ref PSE-7781, RETIRO 30000.00 COP]", gestor.extracto("CTA-0001").toString());
    }

    @Test
    void extracto_veLosMovimientosAunqueElSaldoVuelvaAlValorQueTenia() {
        // corregido en 14/02: la caché usa el número de cuenta, que no cambia
        gestor.extracto("CTA-0001");
        gestor.depositar("CTA-0001", 100_000, null);
        gestor.retirar("CTA-0001", 100_000);
        assertEquals(2, gestor.extracto("CTA-0001").size());
    }

    @Test
    void cadaOperacionDejaUnaFilaDeAuditoria() throws SQLException {
        int antes = filas("auditoria");                     // las tres aperturas
        gestor.depositar("CTA-0001", 80_000, null);
        gestor.retirar("CTA-0001", 30_000);
        gestor.transferir("CTA-0001", "CTA-0003", 10_000);
        gestor.bloquear("CTA-0001", "embargo");
        gestor.desbloquear("CTA-0001");
        assertEquals(3, antes);
        assertEquals(8, filas("auditoria"));
    }

    // --- ayudas ---------------------------------------------------------------------------

    private static void assertMensaje(String esperado, Runnable operacion) {
        RuntimeException e = assertThrows(RuntimeException.class, operacion::run);
        assertEquals(esperado, e.getMessage());
    }

    private static int filas(String tabla) throws SQLException {
        try (Connection con = BaseDatos.abrir();
             ResultSet rs = con.createStatement().executeQuery("SELECT COUNT(*) FROM " + tabla)) {
            rs.next();
            return rs.getInt(1);
        }
    }
}
