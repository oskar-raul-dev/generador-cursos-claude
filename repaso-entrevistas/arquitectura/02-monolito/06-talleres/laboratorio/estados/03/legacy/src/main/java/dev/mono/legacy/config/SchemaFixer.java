package dev.mono.legacy.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

// Hibernate crea las tablas (ddl-auto: update); lo que Hibernate no sabe crear se lanza aquí al arrancar
@Component
public class SchemaFixer {
    private final JdbcTemplate jdbc;
    private final String url;

    public SchemaFixer(JdbcTemplate jdbc, @Value("${spring.datasource.url}") String url) {
        this.jdbc = jdbc;
        this.url = url;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void fix() throws Exception {
        if (!url.contains("postgresql")) {
            return;   // en las pruebas (SQLite) no hay trigger
        }
        var sql = new ClassPathResource("db/triggers.sql").getContentAsString(StandardCharsets.UTF_8);
        jdbc.execute(sql);
    }
}
