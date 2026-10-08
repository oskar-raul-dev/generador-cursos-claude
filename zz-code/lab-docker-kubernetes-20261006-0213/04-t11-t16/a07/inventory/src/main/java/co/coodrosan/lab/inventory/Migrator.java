package co.coodrosan.lab.inventory;

import javax.sql.DataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.stereotype.Component;

// Las migraciones de inventory (G3): el esquema del motor y la siembra de los códigos de razón. Son
// idempotentes, así que correrlas dos veces no rompe nada; correrlas a la vez es otra historia (Fase 12).
@Component
public class Migrator {

    private static final Logger log = LoggerFactory.getLogger(Migrator.class);
    private final DataSource dataSource;

    public Migrator(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public void migrate() {
        String schema = StoreConfig.postgres() ? "schema-postgresql.sql" : "schema-sqlite.sql";
        new ResourceDatabasePopulator(new ClassPathResource(schema), new ClassPathResource("data.sql")).execute(dataSource);
        if (!StoreConfig.postgres()) {
            // G13: las columnas nuevas en una base SQLite de antes; si ya existen, el ALTER falla y se sigue.
            ResourceDatabasePopulator columns = new ResourceDatabasePopulator(new ClassPathResource("migrations-sqlite.sql"));
            columns.setContinueOnError(true);
            columns.execute(dataSource);
        }
        log.info("migraciones aplicadas en {}: {} y data.sql", StoreConfig.postgres() ? "postgres" : "sqlite", schema);
    }
}
