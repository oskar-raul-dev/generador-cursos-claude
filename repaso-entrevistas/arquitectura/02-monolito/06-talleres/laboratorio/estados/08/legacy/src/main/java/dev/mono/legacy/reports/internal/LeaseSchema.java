package dev.mono.legacy.reports.internal;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

// La tabla del lease no es una entidad: se crea aquí, idempotente, hasta que el taller 09 traiga
// migraciones. Es exactamente el tipo de esquema implícito que ese taller desarma.
@Component
class LeaseSchema {
    private final JdbcTemplate jdbc;

    LeaseSchema(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @EventListener(ApplicationReadyEvent.class)
    void create() {
        jdbc.execute("CREATE TABLE IF NOT EXISTS job_leases (name varchar(100) PRIMARY KEY, "
            + "owner varchar(200) NOT NULL, lease_until timestamptz NOT NULL)");
    }
}
