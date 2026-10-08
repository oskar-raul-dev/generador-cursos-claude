package banco;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

// Acceso a la base: una H2 en memoria que vive mientras viva la JVM.
public class BaseDatos {

    public static final String URL = "jdbc:h2:mem:banco;DB_CLOSE_DELAY=-1";

    public static Connection abrir() {
        try {
            return DriverManager.getConnection(URL, "sa", "");
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    // Borra todo y crea las tablas desde cero.
    public static void crearEsquema() {
        try (Connection con = abrir(); Statement st = con.createStatement()) {
            st.execute("DROP ALL OBJECTS");
            st.execute("""
                    CREATE TABLE cuenta (
                        numero    VARCHAR(10) PRIMARY KEY,
                        titular   VARCHAR(80) NOT NULL,
                        email     VARCHAR(80) NOT NULL,
                        tipo      VARCHAR(10) NOT NULL,
                        moneda    CHAR(3)     NOT NULL,
                        saldo     DECIMAL(19, 2) NOT NULL,
                        bloqueada BOOLEAN     NOT NULL,
                        cerrada   BOOLEAN     NOT NULL,
                        es_menor  BOOLEAN     NOT NULL)""");
            st.execute("""
                    CREATE TABLE movimiento (
                        id         IDENTITY PRIMARY KEY,
                        numero     VARCHAR(10) NOT NULL,
                        tipo       VARCHAR(20) NOT NULL,
                        monto      DECIMAL(19, 2) NOT NULL,
                        comision   DECIMAL(19, 2) NOT NULL,
                        referencia VARCHAR(40),
                        fecha      TIMESTAMP   NOT NULL)""");
            st.execute("""
                    CREATE TABLE auditoria (
                        id      IDENTITY PRIMARY KEY,
                        accion  VARCHAR(40)  NOT NULL,
                        detalle VARCHAR(400) NOT NULL,
                        fecha   TIMESTAMP    NOT NULL)""");
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
