package dev.ms.orders.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "ms")
public record OrdersProperties(Catalog catalog, InventoryProps inventory, Payments payments, Events events) {
    public record Events(String topic, String mode, String chaos, long pollMs) {}
    public record Catalog(String baseUrl, int readTimeoutMs) {}
    public record InventoryProps(long deadlineMs) {}
    public record Payments(String baseUrl, int connectTimeoutMs, int readTimeoutMs, boolean propagateKey,
                           RetryProps retry, BulkheadProps bulkhead, Breaker breaker) {
        public record BulkheadProps(int maxConcurrent) {}
        public record RetryProps(int maxAttempts, int baseBackoffMs) {}
        public record Breaker(int window, int minimumCalls, float failureRate, int openSeconds, int halfOpenCalls) {}
    }
}
