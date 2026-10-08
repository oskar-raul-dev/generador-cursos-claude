package dev.mono.legacy.auth.internal;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtValidationException;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandler;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;

@Configuration
public class SecurityConfig {

    private static final String REVOKED = "token_revoked";

    @Value("${legacy.jwt.secret}")
    private String secret;

    @Bean
    SecretKey jwtKey() {
        return new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey key) {
        return new NimbusJwtEncoder(new com.nimbusds.jose.jwk.source.ImmutableSecret<>(key));
    }

    @Bean
    JwtDecoder jwtDecoder(SecretKey key, RevokedTokens revoked) {
        var decoder = NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(JwtValidators.createDefault(),
            jwt -> revoked.isRevoked(jwt.getId())
                ? OAuth2TokenValidatorResult.failure(new OAuth2Error(REVOKED, "Token revoked", null))
                : OAuth2TokenValidatorResult.success()));
        return decoder;
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    SecurityFilterChain api(HttpSecurity http, JwtDecoder decoder) throws Exception {
        // taller 04: 401 y 403 de verdad, en problem+json. Hasta el 03 era 200 + {"error":"Not logged in"}
        AuthenticationEntryPoint notLogged = (req, res, ex) -> {
            boolean isRevoked = isRevoked(ex);
            res.setStatus(401);
            res.setContentType("application/problem+json");
            res.setCharacterEncoding("UTF-8");            // taller 08: sin esto, ;charset=ISO-8859-1
            res.setHeader("WWW-Authenticate", "Bearer");
            res.getWriter().write(problem(isRevoked ? "Token revoked" : "Unauthenticated", 401,
                isRevoked ? "TOKEN_REVOKED" : "UNAUTHENTICATED", req.getRequestURI()));
        };
        AccessDeniedHandler forbidden = (req, res, ex) -> {
            res.setStatus(403);
            res.setContentType("application/problem+json");
            res.setCharacterEncoding("UTF-8");
            res.getWriter().write(problem("Forbidden", 403, "FORBIDDEN", req.getRequestURI()));
        };
        http
            .csrf(c -> c.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/health", "/error").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/v1/auth/login").permitAll()
                .anyRequest().authenticated())
            .oauth2ResourceServer(rs -> rs.jwt(j -> j.decoder(decoder))
                .authenticationEntryPoint(notLogged).accessDeniedHandler(forbidden))
            .exceptionHandling(e -> e.authenticationEntryPoint(notLogged).accessDeniedHandler(forbidden));
        return http.build();
    }

    // el proveedor JWT envuelve el fallo en un InvalidBearerTokenException genérico; solo la
    // JwtValidationException original conserva el código del validador de revocación
    private static boolean isRevoked(Throwable ex) {
        for (Throwable t = ex; t != null; t = t.getCause()) {
            if (t instanceof JwtValidationException v) {
                return v.getErrors().stream().anyMatch(e -> REVOKED.equals(e.getErrorCode()));
            }
        }
        return false;
    }

    private static String problem(String title, int status, String code, String instance) {
        return """
            {"type":"about:blank","title":"%s","status":%d,"code":"%s","instance":"%s"}"""
            .formatted(title, status, code, instance);
    }
}
