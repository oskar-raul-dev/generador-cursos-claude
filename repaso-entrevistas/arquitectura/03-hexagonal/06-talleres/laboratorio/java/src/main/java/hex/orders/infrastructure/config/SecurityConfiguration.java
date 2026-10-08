package hex.orders.infrastructure.config;

import hex.orders.infrastructure.inbound.http.security.ProblemAccessDeniedHandler;
import hex.orders.infrastructure.inbound.http.security.ProblemAuthenticationEntryPoint;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

// Seguridad del borde HTTP: verificar credenciales y construir una identidad confiable. La
// autorización contextual (dueño u operador) NO está aquí: vive en los casos de uso.
// Solo con servidor web: el mismo jar arranca como CLI de lotes (taller 11) sin HTTP, y ahí no
// hay HttpSecurity que configurar.
@Configuration
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
public class SecurityConfiguration {

    @Bean
    SecurityFilterChain api(HttpSecurity http, JwtDecoder decoder, HexProperties properties) throws Exception {
        CorsConfigurationSource cors = corsConfigurationSource(properties);
        http
            .csrf(csrf -> csrf.disable())                       // API sin sesión ni cookies
            .cors(c -> c.configurationSource(cors))
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/health").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/v1/auth/login").permitAll()
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .anyRequest().authenticated())
            .oauth2ResourceServer(rs -> rs
                .jwt(jwt -> jwt.decoder(decoder))
                .authenticationEntryPoint(new ProblemAuthenticationEntryPoint())
                .accessDeniedHandler(new ProblemAccessDeniedHandler()))
            .exceptionHandling(e -> e
                .authenticationEntryPoint(new ProblemAuthenticationEntryPoint())
                .accessDeniedHandler(new ProblemAccessDeniedHandler()));
        return http.build();
    }

    // El frontend del taller 02 vive en otro origen: se permiten sus cabeceras y se exponen las que lee.
    // No es un @Bean: Spring MVC ya registra un CorsConfigurationSource (mvcHandlerMappingIntrospector)
    // y dos beans del mismo tipo dejan la inyección ambigua. Se construye y se pasa a mano.
    private static CorsConfigurationSource corsConfigurationSource(HexProperties properties) {
        var config = new CorsConfiguration();
        config.setAllowedOrigins(List.of(properties.cors().allowedOrigin()));
        config.setAllowedMethods(List.of("GET", "POST", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "Idempotency-Key", "Accept"));
        config.setExposedHeaders(List.of("Location", "Idempotent-Replay"));
        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
