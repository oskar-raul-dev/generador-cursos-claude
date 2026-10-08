package banco;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;

public class Auditoria {

    public void registrar(String accion, String detalle) {
        try (Connection con = BaseDatos.abrir();
             PreparedStatement ps = con.prepareStatement("INSERT INTO auditoria (accion, detalle, fecha) VALUES (?, ?, ?)")) {
            ps.setString(1, accion);
            ps.setString(2, detalle);
            ps.setTimestamp(3, Timestamp.valueOf(LocalDateTime.now()));
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        System.out.println("[AUDITORIA] " + accion + " " + detalle);
    }
}
