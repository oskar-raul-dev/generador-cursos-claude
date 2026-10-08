package banco;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

// Todo lo que se hace con una cuenta pasa por aquí.
public class GestorCuentas {

    private final Map<String, List<Movimiento>> cacheExtractos = new HashMap<>();   // por número: no cambia
    private final Set<ClaveDeposito> recientes = new HashSet<>();   // para no aplicar dos veces un depósito

    public void abrirCuenta(String numero, String titular, String email, String tipo, String moneda,
                            double saldoInicial, boolean esMenor) {
        if (numero == null || numero.isBlank()) {
            throw new IllegalArgumentException("el número es obligatorio");
        } else if (titular == null || titular.isBlank()) {
            throw new IllegalArgumentException("el titular es obligatorio");
        } else if (email == null || !email.contains("@")) {
            throw new IllegalArgumentException("email inválido");
        } else if (!tipo.equals("AHORROS") && !tipo.equals("CORRIENTE") && !tipo.equals("NOMINA")) {
            throw new IllegalArgumentException("tipo de cuenta desconocido: " + tipo);
        } else if (!moneda.equals("COP") && !moneda.equals("USD")) {
            throw new IllegalArgumentException("moneda no soportada: " + moneda);
        } else if (saldoInicial < 0) {
            throw new IllegalArgumentException("el saldo inicial no puede ser negativo");
        } else if (tipo.equals("NOMINA") && !moneda.equals("COP")) {
            throw new IllegalArgumentException("la cuenta nómina solo existe en COP");
        }
        try (Connection con = BaseDatos.abrir()) {
            PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO cuenta (numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, es_menor) "
                            + "VALUES (?, ?, ?, ?, ?, ?, FALSE, FALSE, ?)");
            ps.setString(1, numero);
            ps.setString(2, titular);
            ps.setString(3, email);
            ps.setString(4, tipo);
            ps.setString(5, moneda);
            ps.setBigDecimal(6, Dinero.de(saldoInicial, Moneda.valueOf(moneda)).monto());
            ps.setBoolean(7, esMenor);
            ps.executeUpdate();
            auditar(con, "ABRIR", numero + " " + tipo + " " + moneda + " saldo " + saldoInicial);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        new Notificador().enviar(email, "Tu cuenta " + numero + " está abierta");
    }

    public double consultarSaldo(String numero) {
        return saldo(numero).monto().doubleValue();
    }

    public Dinero saldo(String numero) {
        return consultarCuenta(numero).getSaldo();
    }

    public Cuenta consultarCuenta(String numero) {
        try (Connection con = BaseDatos.abrir()) {
            PreparedStatement ps = con.prepareStatement(
                    "SELECT numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, es_menor FROM cuenta WHERE numero = ?");
            ps.setString(1, numero);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) throw new IllegalArgumentException("no existe la cuenta " + numero);
            Cuenta c = new Cuenta();
            c.setNumero(rs.getString("numero"));
            c.setTitular(rs.getString("titular"));
            c.setEmail(rs.getString("email"));
            c.setTipo(rs.getString("tipo"));
            c.setMoneda(Moneda.valueOf(rs.getString("moneda")));
            c.setSaldo(new Dinero(rs.getBigDecimal("saldo"), c.getMoneda()));
            c.setBloqueada(rs.getBoolean("bloqueada"));
            c.setCerrada(rs.getBoolean("cerrada"));
            c.setEsMenor(rs.getBoolean("es_menor"));
            return c;
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public void depositar(String numero, double monto, String referencia) {
        try (Connection con = BaseDatos.abrir()) {
            PreparedStatement ps = con.prepareStatement(
                    "SELECT numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, es_menor FROM cuenta WHERE numero = ?");
            ps.setString(1, numero);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) throw new IllegalArgumentException("no existe la cuenta " + numero);
            Cuenta c = new Cuenta();
            c.setNumero(rs.getString("numero"));
            c.setTitular(rs.getString("titular"));
            c.setEmail(rs.getString("email"));
            c.setTipo(rs.getString("tipo"));
            c.setMoneda(Moneda.valueOf(rs.getString("moneda")));
            c.setSaldo(new Dinero(rs.getBigDecimal("saldo"), c.getMoneda()));
            c.setBloqueada(rs.getBoolean("bloqueada"));
            c.setCerrada(rs.getBoolean("cerrada"));
            c.setEsMenor(rs.getBoolean("es_menor"));

            if (monto <= 0) {
                throw new IllegalArgumentException("el monto debe ser positivo");
            } else if (c.isCerrada()) {
                throw new IllegalStateException("la cuenta " + numero + " está cerrada");
            }
            // una cuenta bloqueada sí recibe depósitos

            Dinero importe = Dinero.de(monto, c.getMoneda());
            ClaveDeposito clave = new ClaveDeposito(numero, importe, referencia);
            if (referencia != null && recientes.contains(clave)) {
                return;   // ya se aplicó: la pasarela reintentó
            }
            recientes.add(clave);
            Movimiento m = new Movimiento(numero, "DEPOSITO", importe, Dinero.cero(c.getMoneda()), referencia,
                    LocalDateTime.now());

            c.setSaldo(c.getSaldo().mas(importe));
            PreparedStatement up = con.prepareStatement("UPDATE cuenta SET saldo = ? WHERE numero = ?");
            up.setBigDecimal(1, c.getSaldo().monto());
            up.setString(2, numero);
            up.executeUpdate();
            PreparedStatement ins = con.prepareStatement(
                    "INSERT INTO movimiento (numero, tipo, monto, comision, referencia, fecha) VALUES (?, ?, ?, ?, ?, ?)");
            ins.setString(1, numero);
            ins.setString(2, "DEPOSITO");
            ins.setBigDecimal(3, importe.monto());
            ins.setBigDecimal(4, m.comision().monto());
            ins.setString(5, referencia);
            ins.setTimestamp(6, Timestamp.valueOf(m.fecha()));
            ins.executeUpdate();
            cacheExtractos.remove(numero);
            auditar(con, "DEPOSITO", numero + " " + importe + " ref " + referencia);
            new Notificador().enviar(c.getEmail(), "Recibiste un depósito de " + importe);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public void retirar(String numero, double monto) {
        try (Connection con = BaseDatos.abrir()) {
            PreparedStatement ps = con.prepareStatement(
                    "SELECT numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, es_menor FROM cuenta WHERE numero = ?");
            ps.setString(1, numero);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) throw new IllegalArgumentException("no existe la cuenta " + numero);
            Cuenta c = new Cuenta();
            c.setNumero(rs.getString("numero"));
            c.setTitular(rs.getString("titular"));
            c.setEmail(rs.getString("email"));
            c.setTipo(rs.getString("tipo"));
            c.setMoneda(Moneda.valueOf(rs.getString("moneda")));
            c.setSaldo(new Dinero(rs.getBigDecimal("saldo"), c.getMoneda()));
            c.setBloqueada(rs.getBoolean("bloqueada"));
            c.setCerrada(rs.getBoolean("cerrada"));
            c.setEsMenor(rs.getBoolean("es_menor"));

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

            Dinero comision;
            switch (c.getTipo()) {
                case "AHORROS":
                    comision = c.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.cero(c.getMoneda());
                    break;
                case "CORRIENTE":
                    comision = c.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.de("1500", Moneda.COP);
                    break;
                case "NOMINA":
                    comision = importe.esMayorQue(Dinero.de("2000000", Moneda.COP)) ? importe.por("0.004") : Dinero.cero(Moneda.COP);
                    break;
                default:
                    throw new IllegalStateException("tipo desconocido " + c.getTipo());
            }
            if (c.getSaldo().esMenorQue(importe.mas(comision))) {
                throw new IllegalStateException("saldo insuficiente en " + numero);
            }

            c.setSaldo(c.getSaldo().menos(importe).menos(comision));
            PreparedStatement up = con.prepareStatement("UPDATE cuenta SET saldo = ? WHERE numero = ?");
            up.setBigDecimal(1, c.getSaldo().monto());
            up.setString(2, numero);
            up.executeUpdate();
            PreparedStatement ins = con.prepareStatement(
                    "INSERT INTO movimiento (numero, tipo, monto, comision, referencia, fecha) VALUES (?, ?, ?, ?, ?, ?)");
            ins.setString(1, numero);
            ins.setString(2, "RETIRO");
            ins.setBigDecimal(3, importe.monto());
            ins.setBigDecimal(4, comision.monto());
            ins.setString(5, null);
            ins.setTimestamp(6, Timestamp.valueOf(LocalDateTime.now()));
            ins.executeUpdate();
            cacheExtractos.remove(numero);
            auditar(con, "RETIRO", numero + " " + importe + " comisión " + comision);
            if (!importe.esMenorQue(Dinero.de("1000000", c.getMoneda()))) {
                new Notificador().enviar(c.getEmail(), "Retiraste " + importe);
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public void transferir(String numeroOrigen, String numeroDestino, double monto) {
        try (Connection con = BaseDatos.abrir()) {
            PreparedStatement ps = con.prepareStatement(
                    "SELECT numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, es_menor FROM cuenta WHERE numero = ?");
            ps.setString(1, numeroOrigen);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) throw new IllegalArgumentException("no existe la cuenta " + numeroOrigen);
            Cuenta origen = new Cuenta();
            origen.setNumero(rs.getString("numero"));
            origen.setTitular(rs.getString("titular"));
            origen.setEmail(rs.getString("email"));
            origen.setTipo(rs.getString("tipo"));
            origen.setMoneda(Moneda.valueOf(rs.getString("moneda")));
            origen.setSaldo(new Dinero(rs.getBigDecimal("saldo"), origen.getMoneda()));
            origen.setBloqueada(rs.getBoolean("bloqueada"));
            origen.setCerrada(rs.getBoolean("cerrada"));
            origen.setEsMenor(rs.getBoolean("es_menor"));

            PreparedStatement ps2 = con.prepareStatement(
                    "SELECT numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, es_menor FROM cuenta WHERE numero = ?");
            ps2.setString(1, numeroDestino);
            ResultSet rs2 = ps2.executeQuery();
            if (!rs2.next()) throw new IllegalArgumentException("no existe la cuenta " + numeroDestino);
            Cuenta destino = new Cuenta();
            destino.setNumero(rs2.getString("numero"));
            destino.setTitular(rs2.getString("titular"));
            destino.setEmail(rs2.getString("email"));
            destino.setTipo(rs2.getString("tipo"));
            destino.setMoneda(Moneda.valueOf(rs2.getString("moneda")));
            destino.setSaldo(new Dinero(rs2.getBigDecimal("saldo"), destino.getMoneda()));
            destino.setBloqueada(rs2.getBoolean("bloqueada"));
            destino.setCerrada(rs2.getBoolean("cerrada"));
            destino.setEsMenor(rs2.getBoolean("es_menor"));

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

            Dinero comision;
            switch (origen.getTipo()) {
                case "AHORROS":
                    comision = origen.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.cero(origen.getMoneda());
                    break;
                case "CORRIENTE":
                    comision = origen.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.de("1000", Moneda.COP);
                    break;
                case "NOMINA":
                    comision = importe.esMayorQue(Dinero.de("2000000", Moneda.COP)) ? importe.por("0.004") : Dinero.cero(Moneda.COP);
                    break;
                default:
                    throw new IllegalStateException("tipo desconocido " + origen.getTipo());
            }
            if (origen.getSaldo().esMenorQue(importe.mas(comision))) {
                throw new IllegalStateException("saldo insuficiente en " + numeroOrigen);
            }

            origen.setSaldo(origen.getSaldo().menos(importe).menos(comision));
            destino.setSaldo(destino.getSaldo().mas(importe));
            PreparedStatement up = con.prepareStatement("UPDATE cuenta SET saldo = ? WHERE numero = ?");
            up.setBigDecimal(1, origen.getSaldo().monto());
            up.setString(2, numeroOrigen);
            up.executeUpdate();
            up.setBigDecimal(1, destino.getSaldo().monto());
            up.setString(2, numeroDestino);
            up.executeUpdate();
            PreparedStatement ins = con.prepareStatement(
                    "INSERT INTO movimiento (numero, tipo, monto, comision, referencia, fecha) VALUES (?, ?, ?, ?, ?, ?)");
            ins.setString(1, numeroOrigen);
            ins.setString(2, "TRANSF_ENVIADA");
            ins.setBigDecimal(3, importe.monto());
            ins.setBigDecimal(4, comision.monto());
            ins.setString(5, numeroDestino);
            ins.setTimestamp(6, Timestamp.valueOf(LocalDateTime.now()));
            ins.executeUpdate();
            ins.setString(1, numeroDestino);
            ins.setString(2, "TRANSF_RECIBIDA");
            ins.setBigDecimal(3, importe.monto());
            ins.setBigDecimal(4, Dinero.cero(destino.getMoneda()).monto());
            ins.setString(5, numeroOrigen);
            ins.setTimestamp(6, Timestamp.valueOf(LocalDateTime.now()));
            ins.executeUpdate();
            cacheExtractos.remove(numeroOrigen);
            cacheExtractos.remove(numeroDestino);
            auditar(con, "TRANSFERENCIA", numeroOrigen + " -> " + numeroDestino + " " + importe + " comisión " + comision);
            new Notificador().enviar(destino.getEmail(), "Recibiste " + importe + " de " + origen.getTitular());
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public void bloquear(String numero, String motivo) {
        Cuenta c = consultarCuenta(numero);
        c.setBloqueada(true);
        guardarFlags(c);
        try (Connection con = BaseDatos.abrir()) {
            auditar(con, "BLOQUEAR", numero + " " + motivo);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        new Notificador().enviar(c.getEmail(), "Tu cuenta " + numero + " fue bloqueada: " + motivo);
    }

    public void desbloquear(String numero) {
        Cuenta c = consultarCuenta(numero);
        c.setBloqueada(false);
        guardarFlags(c);
        try (Connection con = BaseDatos.abrir()) {
            auditar(con, "DESBLOQUEAR", numero);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public void cerrar(String numero) {
        Cuenta c = consultarCuenta(numero);
        if (c.isBloqueada()) {
            throw new IllegalStateException("una cuenta bloqueada no se puede cerrar");
        } else if (!c.getSaldo().esCero()) {
            throw new IllegalStateException("para cerrar, el saldo debe ser cero");
        }
        c.setCerrada(true);
        guardarFlags(c);
        try (Connection con = BaseDatos.abrir()) {
            auditar(con, "CERRAR", numero);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        new Notificador().enviar(c.getEmail(), "Tu cuenta " + numero + " quedó cerrada");
    }

    public List<Movimiento> extracto(String numero) {
        Cuenta c = consultarCuenta(numero);
        List<Movimiento> enCache = cacheExtractos.get(numero);
        if (enCache != null) {
            return enCache;
        }
        List<Movimiento> movimientos = new ArrayList<>();
        try (Connection con = BaseDatos.abrir()) {
            PreparedStatement ps = con.prepareStatement(
                    "SELECT numero, tipo, monto, comision, referencia, fecha FROM movimiento WHERE numero = ? ORDER BY id");
            ps.setString(1, numero);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                movimientos.add(new Movimiento(rs.getString("numero"), rs.getString("tipo"),
                        new Dinero(rs.getBigDecimal("monto"), c.getMoneda()),
                        new Dinero(rs.getBigDecimal("comision"), c.getMoneda()), rs.getString("referencia"),
                        rs.getTimestamp("fecha").toLocalDateTime()));
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        cacheExtractos.put(numero, movimientos);
        return movimientos;
    }

    private void guardarFlags(Cuenta c) {
        try (Connection con = BaseDatos.abrir()) {
            PreparedStatement up = con.prepareStatement("UPDATE cuenta SET bloqueada = ?, cerrada = ? WHERE numero = ?");
            up.setBoolean(1, c.isBloqueada());
            up.setBoolean(2, c.isCerrada());
            up.setString(3, c.getNumero());
            up.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    private void auditar(Connection con, String accion, String detalle) throws SQLException {
        PreparedStatement ps = con.prepareStatement("INSERT INTO auditoria (accion, detalle, fecha) VALUES (?, ?, ?)");
        ps.setString(1, accion);
        ps.setString(2, detalle);
        ps.setTimestamp(3, Timestamp.valueOf(LocalDateTime.now()));
        ps.executeUpdate();
        System.out.println("[AUDITORIA] " + accion + " " + detalle);
    }
}
