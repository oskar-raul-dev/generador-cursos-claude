package dev.ms.monolith;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

// ms-monolith: catálogo, clientes, inventario, pedidos, pagos y notificaciones en un solo proceso y
// una sola base. Escrito como se escribe un monolito típico —por capas técnicas, con JOIN entre
// módulos y una transacción que lo abarca todo—, porque ese es el material del bloque 06.
@SpringBootApplication
@ConfigurationPropertiesScan
public class MonolithApplication {
    public static void main(String[] args) {
        SpringApplication.run(MonolithApplication.class, args);
    }
}
