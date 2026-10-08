package dev.mono.legacy.inventory.internal;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

// Hasta el taller 05 creaba el trigger orders_restore_stock al arrancar. Desde el 06 la devolución del
// stock vive en InventoryService.release, y esto retira el trigger de las bases que lo tenían: si se
// quedara, cada cancelación devolvería el stock dos veces. Con migraciones (taller 09) será un script.
@Component
public class SchemaFixer {
    private final JdbcTemplate jdbc;

    public SchemaFixer(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void fix() throws Exception {
        jdbc.execute(new ClassPathResource("db/drop-legacy-trigger.sql").getContentAsString(StandardCharsets.UTF_8));
    }
}
