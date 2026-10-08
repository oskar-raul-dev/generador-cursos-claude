package dev.ms.monolith.payments;

import dev.ms.monolith.config.MsProperties;
import dev.ms.monolith.service.Errors;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.core.IntervalFunction;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
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
//     no se llama ni se reintenta (CallNotPermittedException no está en la lista de reintentables).
@Component
@ConditionalOnProperty(name = "ms.payments.mode", havingValue = "remote")
public class RemotePayments implements Payments {

    record PaymentBody(String status, String reference) {}

    private static final Logger log = LoggerFactory.getLogger(RemotePayments.class);

    private final RestClient http;
    private final boolean propagateKey;
    private final Retry retry;
    private final CircuitBreaker breaker;

    public RemotePayments(RestClient.Builder builder, MsProperties props) {
        var cfg = props.payments();
        var jdk = HttpClient.newBuilder().connectTimeout(Duration.ofMillis(cfg.connectTimeoutMs())).build();
        var factory = new JdkClientHttpRequestFactory(jdk);
        factory.setReadTimeout(Duration.ofMillis(cfg.readTimeoutMs()));
        this.http = builder.baseUrl(cfg.baseUrl()).requestFactory(factory).build();
        this.propagateKey = cfg.propagateKey();

        this.retry = Retry.of("payments", RetryConfig.custom()
            .maxAttempts(cfg.retry().maxAttempts())
            .intervalFunction(IntervalFunction.ofExponentialRandomBackoff(Duration.ofMillis(cfg.retry().baseBackoffMs()), 2.0, 0.5))
            .retryExceptions(ResourceAccessException.class, HttpServerErrorException.class)
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
            var res = Retry.decorateSupplier(retry, CircuitBreaker.decorateSupplier(breaker, call)).get();
            return new Result(res.status(), res.reference());
        } catch (CallNotPermittedException e) {
            throw new Errors.PaymentsUnavailable("circuit breaker open");    // no se llamó: seguro que no cobró
        } catch (ResourceAccessException e) {
            if (isTimeout(e)) return new Result("PENDING", null);            // pudo cobrar: resultado incierto
            throw new Errors.PaymentsUnavailable(e.getMessage());           // no conectó: no cobró
        } catch (HttpServerErrorException e) {
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
