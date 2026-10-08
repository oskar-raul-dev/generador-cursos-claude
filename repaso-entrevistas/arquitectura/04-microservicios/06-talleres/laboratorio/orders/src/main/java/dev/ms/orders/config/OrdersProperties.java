package dev.ms.orders.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "ms")
public record OrdersProperties(Catalog catalog, InventoryProps inventory, Payments payments, Events events,
                               Saga saga, V1 v1, Overview overview) {
    /** Taller 11: el read model de "mis pedidos"; inbox=false es la provocación del reproceso. */
    public record Overview(boolean inbox, int compositionTimeoutMs) {}
    /**
     * Taller 08: el topic de OrderPlaced (v2) y la provocación del ciclo. Taller 09: el modo
     * (choreography | orchestration), el plazo de cada paso del orquestador (0 = sin plazo) y cada
     * cuánto busca pasos pendientes.
     */
    public record Saga(String placedTopic, boolean retryOnRelease, String mode, int stepDeadlineSeconds, long pollMs) {}
    /** Taller 08: cuándo se declaró obsoleto v1 y cuándo deja de existir (Deprecation, Sunset). */
    public record V1(java.time.Instant deprecatedAt, java.time.Instant sunsetAt) {}
    public record Events(String topic, String mode, String chaos, long pollMs, boolean propagateTrace) {}
    public record Catalog(String baseUrl, int readTimeoutMs) {}
    public record InventoryProps(long deadlineMs) {}
    public record Payments(String baseUrl, int connectTimeoutMs, int readTimeoutMs, boolean propagateKey,
                           RetryProps retry, BulkheadProps bulkhead, Breaker breaker) {
        public record BulkheadProps(int maxConcurrent) {}
        public record RetryProps(int maxAttempts, int baseBackoffMs) {}
        public record Breaker(int window, int minimumCalls, float failureRate, int openSeconds, int halfOpenCalls) {}
    }
}
