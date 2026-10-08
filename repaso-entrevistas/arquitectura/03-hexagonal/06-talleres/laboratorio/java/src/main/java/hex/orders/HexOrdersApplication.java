package hex.orders;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.scheduling.annotation.EnableScheduling;

// Único punto donde Spring Boot toca el proyecto entero. @EnableScheduling es para el dispatcher
// de la outbox (infrastructure/outbound/notification).
@SpringBootApplication
@EnableScheduling
public class HexOrdersApplication {

    public static void main(String[] args) {
        ConfigurableApplicationContext context = SpringApplication.run(HexOrdersApplication.class, args);
        // Taller 11: arrancado como CLI de lotes (spring.batch.job.enabled=true, sin servidor web) el
        // proceso tiene que terminar cuando el job termina, con el código de salida del job. Sin esto,
        // el scheduler de la outbox (hilos no daemon) mantiene la JVM viva para siempre.
        if (context.getEnvironment().getProperty("spring.batch.job.enabled", Boolean.class, false)) {
            System.exit(SpringApplication.exit(context));
        }
    }
}
