package dev.ms.monolith.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "ms")
public record MsProperties(Jwt jwt, Psp psp) {
    public record Jwt(String secret, long ttlSeconds) {}
    public record Psp(String baseUrl, int connectTimeoutMs, int readTimeoutMs) {}
}
