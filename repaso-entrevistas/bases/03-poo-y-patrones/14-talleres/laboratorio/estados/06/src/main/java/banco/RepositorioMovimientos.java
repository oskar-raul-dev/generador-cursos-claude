package banco;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class RepositorioMovimientos {

    public void registrar(Connection con, Movimiento m) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO movimiento (numero, tipo, monto, comision, referencia, fecha) VALUES (?, ?, ?, ?, ?, ?)")) {
            ps.setString(1, m.numeroCuenta());
            ps.setString(2, m.tipo());
            ps.setBigDecimal(3, m.monto().monto());
            ps.setBigDecimal(4, m.comision().monto());
            ps.setString(5, m.referencia());
            ps.setTimestamp(6, Timestamp.valueOf(m.fecha()));
            ps.executeUpdate();
        }
    }

    public List<Movimiento> deCuenta(Connection con, String numero, Moneda moneda) throws SQLException {
        List<Movimiento> movimientos = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT numero, tipo, monto, comision, referencia, fecha FROM movimiento WHERE numero = ? ORDER BY id")) {
            ps.setString(1, numero);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                movimientos.add(new Movimiento(rs.getString("numero"), rs.getString("tipo"),
                        new Dinero(rs.getBigDecimal("monto"), moneda), new Dinero(rs.getBigDecimal("comision"), moneda),
                        rs.getString("referencia"), rs.getTimestamp("fecha").toLocalDateTime()));
            }
        }
        return movimientos;
    }
}
