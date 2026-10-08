package dev.ms.monolith.service;

import dev.ms.monolith.config.MsProperties;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.net.http.HttpClient;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;

// Cliente del proveedor de pago externo. Tiene timeouts —alguien los puso—, pero se le llama desde
// dentro de una transacción de base de datos (PaymentService), y eso es otro problema (taller 01).
@Component
public class PspClient {

    public record PspResult(String status, String reference) {}

    /** El proveedor no respondió a tiempo o no se le pudo alcanzar: no sabemos si cobró. */
    public static final class PspUnavailable extends RuntimeException {
        PspUnavailable(Throwable cause) { super(cause.getMessage(), cause); }
    }

    private final RestClient http;

    public PspClient(RestClient.Builder builder, MsProperties props) {
        var jdk = HttpClient.newBuilder().connectTimeout(Duration.ofMillis(props.psp().connectTimeoutMs())).build();
        var factory = new JdkClientHttpRequestFactory(jdk);
        factory.setReadTimeout(Duration.ofMillis(props.psp().readTimeoutMs()));
        this.http = builder.baseUrl(props.psp().baseUrl()).requestFactory(factory).build();
    }

    public PspResult authorize(UUID orderId, BigDecimal amount, String operationId) {
        try {
            return http.post().uri("/payments")
                .header("Idempotency-Key", operationId)          // la clave del cliente viaja al proveedor
                .body(Map.of("orderId", orderId.toString(), "amount", amount.toPlainString(), "currency", "USD"))
                .retrieve()
                .body(PspResult.class);
        } catch (ResourceAccessException e) {                   // timeout de lectura, conexión rechazada…
            throw new PspUnavailable(e);
        }
    }
}
