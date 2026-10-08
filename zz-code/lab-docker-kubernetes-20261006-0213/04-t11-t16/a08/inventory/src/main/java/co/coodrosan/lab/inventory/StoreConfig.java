package co.coodrosan.lab.inventory;

import com.zaxxer.hikari.HikariDataSource;
import java.net.URI;
import javax.sql.DataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// El almacén de inventory (G3): Postgres si hay DATABASE_URL (postgres://usuario:clave@host:puerto/base,
// el formato del contrato), y si no, el SQLite de DATA_DIR que usaba G1 y sigue usando compose.
@Configuration
public class StoreConfig {

    static boolean postgres() {
        String url = System.getenv("DATABASE_URL");
        return url != null && !url.isBlank();
    }

    @Bean
    public DataSource dataSource() {
        HikariDataSource ds = new HikariDataSource();
        if (postgres()) {
            // JDBC no entiende postgres://…: se arma la URL de JDBC y se separan usuario y clave.
            URI uri = URI.create(System.getenv("DATABASE_URL"));
            String[] userInfo = uri.getUserInfo().split(":", 2);
            ds.setJdbcUrl("jdbc:postgresql://%s:%d%s".formatted(uri.getHost(), uri.getPort() == -1 ? 5432 : uri.getPort(), uri.getPath()));
            ds.setUsername(userInfo[0]);
            ds.setPassword(userInfo.length > 1 ? userInfo[1] : "");
            ds.setMaximumPoolSize(5);
            // Dos segundos para conseguir una conexión, no los 30 de Hikari: con la base caída, la
            // readiness (G4) y cualquier petición fallan rápido en lugar de quedarse colgadas.
            ds.setConnectionTimeout(2000);
        } else {
            String dir = System.getenv().getOrDefault("DATA_DIR", "/var/lib/inventory");
            ds.setJdbcUrl("jdbc:sqlite:" + dir + "/inventory.db");
            // SQLite escribe de a uno: una sola conexión evita los "database is locked".
            ds.setMaximumPoolSize(1);
        }
        return ds;
    }
}
