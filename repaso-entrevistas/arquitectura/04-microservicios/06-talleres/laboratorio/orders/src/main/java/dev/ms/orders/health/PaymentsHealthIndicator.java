package dev.ms.orders.health;

import dev.ms.orders.config.OrdersProperties;
import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.HealthIndicator;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Duration;

// ¿Responde payments? Útil en /actuator/health para quien diagnostica. Lo que NO debe hacer es
// decidir si orders recibe tráfico: por eso no está en el grupo readiness (application.yaml). Si lo
// estuviera, la caída de payments sacaría a orders del balanceo entero, también para lo que no paga.
@Component("payments")
public class PaymentsHealthIndicator implements HealthIndicator {

    private final RestClient http;

    public PaymentsHealthIndicator(RestClient.Builder builder, OrdersProperties props) {
        var factory = new JdkClientHttpRequestFactory(java.net.http.HttpClient.newBuilder()
            .version(java.net.http.HttpClient.Version.HTTP_1_1).build());
        factory.setReadTimeout(Duration.ofMillis(500));
        this.http = builder.baseUrl(props.payments().baseUrl()).requestFactory(factory).build();
    }

    @Override
    public Health health() {
        try {
            http.get().uri("/health").retrieve().toBodilessEntity();
            return Health.up().build();
        } catch (RuntimeException e) {
            return Health.down().withDetail("error", e.getClass().getSimpleName()).build();
        }
    }
}
