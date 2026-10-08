package banco;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

// El único sitio que sabe cómo se guarda una cuenta. Trabaja dentro de la transacción que le pasan.
public class RepositorioCuentas {

    private static final String COLUMNAS = "numero, titular, email, tipo, moneda, saldo, estado, es_menor, version";

    public Cuenta buscar(Connection con, String numero) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT " + COLUMNAS + " FROM cuenta WHERE numero = ?")) {
            ps.setString(1, numero);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) throw new IllegalArgumentException("no existe la cuenta " + numero);
            Moneda moneda = Moneda.valueOf(rs.getString("moneda"));
            return new Cuenta(rs.getString("numero"), rs.getString("titular"), rs.getString("email"),
                    TipoCuenta.valueOf(rs.getString("tipo")), moneda, new Dinero(rs.getBigDecimal("saldo"), moneda),
                    EstadoCuenta.valueOf(rs.getString("estado")), rs.getBoolean("es_menor"), rs.getInt("version"));
        }
    }

    public void insertar(Connection con, Cuenta c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO cuenta (" + COLUMNAS + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)")) {
            ps.setString(1, c.getNumero());
            ps.setString(2, c.getTitular());
            ps.setString(3, c.getEmail());
            ps.setString(4, c.getTipo().name());
            ps.setString(5, c.getMoneda().name());
            ps.setBigDecimal(6, c.getSaldo().monto());
            ps.setString(7, c.getEstado().name());
            ps.setBoolean(8, c.isEsMenor());
            ps.executeUpdate();
        }
    }

    // Bloqueo optimista: solo escribe si nadie cambió la fila desde que se leyó.
    public void guardar(Connection con, Cuenta c) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE cuenta SET saldo = ?, estado = ?, version = version + 1 WHERE numero = ? AND version = ?")) {
            ps.setBigDecimal(1, c.getSaldo().monto());
            ps.setString(2, c.getEstado().name());
            ps.setString(3, c.getNumero());
            ps.setInt(4, c.getVersion());
            if (ps.executeUpdate() == 0) {
                throw new ConflictoDeConcurrencia(c.getNumero());
            }
        }
    }
}
