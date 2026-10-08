package dev.ms.orders;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableScheduling;

// orders: pedidos, pagos y notificaciones, fuera del monolito desde el taller 04. Habla con
// inventory por gRPC, con payments y con el catálogo (monolito) por HTTP, y confía en la identidad
// que le pasa el gateway.
@SpringBootApplication
@ConfigurationPropertiesScan
@EnableScheduling
public class OrdersApplication {
    public static void main(String[] args) {
        SpringApplication.run(OrdersApplication.class, args);
    }
}
