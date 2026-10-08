package dev.ms.monolith.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "ms")
public record MsProperties(Jwt jwt, Psp psp, Inventory inventory, Payments payments) {
    public record Jwt(String secret, long ttlSeconds) {}
    public record Psp(String baseUrl, int connectTimeoutMs, int readTimeoutMs) {}
    public record Inventory(String mode, String baseUrl, int connectTimeoutMs, int readTimeoutMs) {}
    public record Payments(String mode, String baseUrl, int connectTimeoutMs, int readTimeoutMs, boolean propagateKey,
                           RetryProps retry, Breaker breaker) {
        public record RetryProps(int maxAttempts, int baseBackoffMs) {}
        public record Breaker(int window, int minimumCalls, float failureRate, int openSeconds, int halfOpenCalls) {}
    }
}
