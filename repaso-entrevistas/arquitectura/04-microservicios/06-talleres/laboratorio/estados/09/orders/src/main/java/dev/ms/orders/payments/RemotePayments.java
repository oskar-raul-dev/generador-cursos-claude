package dev.ms.orders.payments;

import dev.ms.orders.config.OrdersProperties;
import dev.ms.orders.service.Errors;
import io.github.resilience4j.bulkhead.Bulkhead;
import io.github.resilience4j.bulkhead.BulkheadConfig;
import io.github.resilience4j.bulkhead.BulkheadFullException;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.core.IntervalFunction;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.net.http.HttpClient;
import java.net.http.HttpTimeoutException;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;

// El cobro a través del servicio payments (Python). Tres decisiones, cada una visible aquí:
//  1. la Idempotency-Key del cliente viaja a payments: el reintento es la MISMA operación;
//  2. se reintenta solo lo que puede no haber ocurrido o ha fallado del otro lado (timeout,
//     conexión, 5xx), con backoff exponencial y jitter; un 4xx no se reintenta: no va a cambiar;
//  3. el circuit breaker va DENTRO del reintento: cada intento cuenta, y con el circuito abierto
//     no se llama ni se reintenta (CallNotPermittedException no está en la lista de reintentables);
//  4. (taller 05) el bulkhead va FUERA de todo: limita cuántos pagos están en curso a la vez,
//     reintentos incluidos, y el que no cabe se rechaza al instante sin llamar.
@Component
public class RemotePayments implements Payments {

    record PaymentBody(String status, String reference) {}

    private static final Logger log = LoggerFactory.getLogger(RemotePayments.class);

    private final RestClient http;
    private final boolean propagateKey;
    private final Retry retry;
    private final CircuitBreaker breaker;
    private final Bulkhead bulkhead;

    public RemotePayments(RestClient.Builder builder, OrdersProperties props) {
        var cfg = props.payments();
        // HTTP/1.1 explícito: por defecto el cliente del JDK intenta subir a HTTP/2 en claro (h2c) en cada
        // petición, y uvicorn lo rechaza con un aviso por petición (06/06 §9)
        var jdk = HttpClient.newBuilder().version(HttpClient.Version.HTTP_1_1)
            .connectTimeout(Duration.ofMillis(cfg.connectTimeoutMs())).build();
        var factory = new JdkClientHttpRequestFactory(jdk);
        factory.setReadTimeout(Duration.ofMillis(cfg.readTimeoutMs()));
        this.http = builder.baseUrl(cfg.baseUrl()).requestFactory(factory).build();
        this.propagateKey = cfg.propagateKey();

        this.retry = Retry.of("payments", RetryConfig.custom()
            .maxAttempts(cfg.retry().maxAttempts())
            .intervalFunction(IntervalFunction.ofExponentialRandomBackoff(Duration.ofMillis(cfg.retry().baseBackoffMs()), 2.0, 0.5))
            // se reintenta lo que puede no haber ocurrido o ha fallado del otro lado… salvo la negativa
            // EXPLÍCITA del breaker de payments (PSP_UNAVAILABLE): repetirla al instante da lo mismo (06/05 §7)
            .retryOnException(e -> e instanceof ResourceAccessException
                || (e instanceof HttpServerErrorException h && !h.getResponseBodyAsString().contains("PSP_UNAVAILABLE")))
            .build());
        this.breaker = CircuitBreaker.of("payments", CircuitBreakerConfig.custom()
            .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.COUNT_BASED)
            .slidingWindowSize(cfg.breaker().window())
            .minimumNumberOfCalls(cfg.breaker().minimumCalls())
            .failureRateThreshold(cfg.breaker().failureRate())
            .waitDurationInOpenState(Duration.ofSeconds(cfg.breaker().openSeconds()))
            .permittedNumberOfCallsInHalfOpenState(cfg.breaker().halfOpenCalls())
            .ignoreExceptions(HttpClientErrorException.class)   // un 4xx es nuestro error, no su caída
            .build());
        this.bulkhead = Bulkhead.of("payments", BulkheadConfig.custom()
            .maxConcurrentCalls(cfg.bulkhead().maxConcurrent())
            .maxWaitDuration(Duration.ZERO)                     // sin cola: el que no cabe, falla ya
            .build());
        retry.getEventPublisher().onRetry(e -> log.warn("payments: retry {} after {} ms ({})",
            e.getNumberOfRetryAttempts(), e.getWaitInterval().toMillis(), e.getLastThrowable().getClass().getSimpleName()));
        breaker.getEventPublisher().onStateTransition(e -> log.warn("payments: circuit breaker {}", e.getStateTransition()));
    }

    @Override
    public Result authorize(UUID orderId, BigDecimal amount, String operationId) {
        var body = Map.of("orderId", orderId.toString(), "amount", amount.toPlainString(), "currency", "USD");
        java.util.function.Supplier<PaymentBody> call = () -> http.post().uri("/payments")
            .headers(h -> { if (propagateKey) h.set("Idempotency-Key", operationId); })
            .body(body).retrieve().body(PaymentBody.class);
        try {
            var res = Bulkhead.decorateSupplier(bulkhead,
                Retry.decorateSupplier(retry, CircuitBreaker.decorateSupplier(breaker, call))).get();
            return new Result(res.status(), res.reference());
        } catch (BulkheadFullException e) {
            throw new Errors.PaymentsUnavailable("bulkhead full");            // no se llamó: seguro que no cobró
        } catch (CallNotPermittedException e) {
            throw new Errors.PaymentsUnavailable("circuit breaker open");    // no se llamó: seguro que no cobró
        } catch (ResourceAccessException e) {
            if (isTimeout(e)) return new Result("PENDING", null);            // pudo cobrar: resultado incierto
            throw new Errors.PaymentsUnavailable(e.getMessage());           // no conectó: no cobró
        } catch (HttpServerErrorException e) {
            // payments dice explícitamente que NO llamó al proveedor (su breaker está abierto): seguro
            if (e.getResponseBodyAsString().contains("PSP_UNAVAILABLE")) throw new Errors.PaymentsUnavailable("psp breaker open in payments");
            return new Result("PENDING", null);                              // falló del otro lado, a mitad: no se sabe
        } catch (HttpClientErrorException.Conflict e) {
            return new Result("PENDING", null);                              // PAYMENT_IN_PROGRESS: otro intento sigue en curso
        }
    }

    private static boolean isTimeout(Throwable e) {
        for (var t = e; t != null; t = t.getCause())
            if (t instanceof HttpTimeoutException || t instanceof java.net.SocketTimeoutException) return true;
        return false;
    }
}
