package co.coodrosan.lab.inventory;

import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.core.IntervalFunction;
import io.github.resilience4j.micrometer.tagged.TaggedCircuitBreakerMetrics;
import io.github.resilience4j.micrometer.tagged.TaggedRetryMetrics;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.retry.RetryRegistry;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Duration;
import java.util.function.Supplier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClientException;

// G9 (Fase 22): lo que inventory hace cuando un vecino falla o tarda. Para cada vecino que se lee (catalog y
// pricing): reintentos con espera creciente y al azar, y un circuit breaker que deja de llamarlo cuando falla
// demasiado. Los timeouts están en el cliente HTTP (SalesController). Todo se ajusta con lab.resilience.*, para
// que la Fase 22 pueda medir también la versión ingenua.
@Component
public class Guard {

    private final RetryRegistry retries;
    private final CircuitBreakerRegistry breakers;
    private final boolean breakerEnabled;

    Guard(MeterRegistry meters,
          @Value("${lab.resilience.retry.max-attempts:3}") int maxAttempts,
          @Value("${lab.resilience.retry.backoff-ms:100}") long backoffMs,
          @Value("${lab.resilience.breaker.enabled:true}") boolean breakerEnabled,
          @Value("${lab.resilience.breaker.failure-rate:50}") float failureRate,
          @Value("${lab.resilience.breaker.window:20}") int window,
          @Value("${lab.resilience.breaker.open-ms:10000}") long openMs) {
        // Reintentar solo lo que puede salir bien la próxima vez: un vecino que no contesta o falla (5xx, I/O).
        // Un 4xx es una respuesta: reintentarla da lo mismo. Y un circuito abierto no se reintenta.
        RetryConfig retry = RetryConfig.custom()
                .maxAttempts(maxAttempts)
                .intervalFunction(backoffMs > 0
                        ? IntervalFunction.ofExponentialRandomBackoff(Duration.ofMillis(backoffMs), 2.0, 0.5)
                        : IntervalFunction.of(Duration.ofMillis(1)))
                .retryOnException(Guard::isTransient)
                .ignoreExceptions(CallNotPermittedException.class)
                .build();
        // El circuito: con la mitad de las últimas veinte llamadas fallando (y al menos diez), se abre por diez
        // segundos; después deja pasar tres de prueba, y según cómo les vaya, se cierra o se vuelve a abrir.
        CircuitBreakerConfig breaker = CircuitBreakerConfig.custom()
                .failureRateThreshold(failureRate)
                .slidingWindowSize(window)
                .minimumNumberOfCalls(Math.min(10, window))
                .waitDurationInOpenState(Duration.ofMillis(openMs))
                .permittedNumberOfCallsInHalfOpenState(3)
                .recordException(Guard::isTransient)
                .build();
        this.retries = RetryRegistry.of(retry);
        this.breakers = CircuitBreakerRegistry.of(breaker);
        this.breakerEnabled = breakerEnabled;
        // En /metrics: resilience4j_circuitbreaker_state y resilience4j_retry_calls_total, por vecino.
        TaggedRetryMetrics.ofRetryRegistry(retries).bindTo(meters);
        TaggedCircuitBreakerMetrics.ofCircuitBreakerRegistry(breakers).bindTo(meters);
    }

    /** Lo que vale reintentar y contar como falla: un vecino que no contesta o falla, por HTTP (5xx, I/O) o por gRPC
     *  (G10: UNAVAILABLE o DEADLINE_EXCEEDED). Un 4xx o un NOT_FOUND son respuestas. */
    private static boolean isTransient(Throwable e) {
        if (e instanceof StatusRuntimeException grpc) {
            Status.Code code = grpc.getStatus().getCode();
            return code == Status.Code.UNAVAILABLE || code == Status.Code.DEADLINE_EXCEEDED;
        }
        return e instanceof RestClientException && !(e instanceof HttpClientErrorException);
    }

    /** La llamada a un vecino, con sus reintentos y, si está encendido, su circuito. */
    public <T> T call(String neighbor, Supplier<T> call) {
        Supplier<T> guarded = breakerEnabled
                ? CircuitBreaker.decorateSupplier(breakers.circuitBreaker(neighbor), call)
                : call;
        return Retry.decorateSupplier(retries.retry(neighbor), guarded).get();
    }
}
