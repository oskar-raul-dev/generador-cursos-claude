package dev.mono.legacy.reports.internal;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

// Taller 08: con dos instancias, @Scheduled corre en las dos. Antes de trabajar, cada una intenta
// tomar el lease del job en la base; solo lo consigue si está libre, vencido o ya era suyo. Si la
// instancia que lo tiene muere, el lease vence y la otra lo toma en la siguiente pasada.
@Component
class JobLeases {
    private final JdbcTemplate jdbc;

    JobLeases(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    boolean tryAcquire(String job, String owner, long millis) {
        return jdbc.update("""
            INSERT INTO job_leases (name, owner, lease_until)
            VALUES (?, ?, now() + make_interval(secs => ? / 1000.0))
            ON CONFLICT (name) DO UPDATE SET owner = EXCLUDED.owner, lease_until = EXCLUDED.lease_until
            WHERE job_leases.lease_until < now() OR job_leases.owner = EXCLUDED.owner""",
            job, owner, millis) == 1;
    }
}
