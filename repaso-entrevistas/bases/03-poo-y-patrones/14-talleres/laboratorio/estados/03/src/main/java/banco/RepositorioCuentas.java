package banco;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

// El único sitio que sabe cómo se guarda una cuenta.
public class RepositorioCuentas {

    private static final String COLUMNAS = "numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, es_menor";

    public Cuenta buscar(String numero) {
        try (Connection con = BaseDatos.abrir();
             PreparedStatement ps = con.prepareStatement("SELECT " + COLUMNAS + " FROM cuenta WHERE numero = ?")) {
            ps.setString(1, numero);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) throw new IllegalArgumentException("no existe la cuenta " + numero);
            Moneda moneda = Moneda.valueOf(rs.getString("moneda"));
            return new Cuenta(rs.getString("numero"), rs.getString("titular"), rs.getString("email"),
                    rs.getString("tipo"), moneda, new Dinero(rs.getBigDecimal("saldo"), moneda),
                    rs.getBoolean("bloqueada"), rs.getBoolean("cerrada"), rs.getBoolean("es_menor"));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public void insertar(Cuenta c) {
        try (Connection con = BaseDatos.abrir();
             PreparedStatement ps = con.prepareStatement(
                     "INSERT INTO cuenta (" + COLUMNAS + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
            ps.setString(1, c.getNumero());
            ps.setString(2, c.getTitular());
            ps.setString(3, c.getEmail());
            ps.setString(4, c.getTipo());
            ps.setString(5, c.getMoneda().name());
            ps.setBigDecimal(6, c.getSaldo().monto());
            ps.setBoolean(7, c.isBloqueada());
            ps.setBoolean(8, c.isCerrada());
            ps.setBoolean(9, c.isEsMenor());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public void guardar(Cuenta c) {
        try (Connection con = BaseDatos.abrir();
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE cuenta SET saldo = ?, bloqueada = ?, cerrada = ? WHERE numero = ?")) {
            ps.setBigDecimal(1, c.getSaldo().monto());
            ps.setBoolean(2, c.isBloqueada());
            ps.setBoolean(3, c.isCerrada());
            ps.setString(4, c.getNumero());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
