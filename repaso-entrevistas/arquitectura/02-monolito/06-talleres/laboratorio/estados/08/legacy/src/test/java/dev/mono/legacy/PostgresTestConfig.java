package dev.mono.legacy;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.postgresql.PostgreSQLContainer;

// Taller 05: la base de las pruebas es la misma que la de ejecución, con la imagen exacta del compose
@TestConfiguration(proxyBeanMethods = false)
public class PostgresTestConfig {
    @Bean
    @ServiceConnection
    PostgreSQLContainer postgres() {
        return new PostgreSQLContainer("postgres:17.11-alpine");
    }
}
