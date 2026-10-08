package dev.ms.orders.web;

import dev.ms.orders.config.OrdersProperties;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

// Taller 08: v1 sigue funcionando, y lo dice en cada respuesta. Deprecation (RFC 9745) lleva la fecha
// en que se declaró obsoleto como fecha de Structured Fields (@segundos); Sunset (RFC 8594), la fecha
// en que dejará de responder, como HTTP-date; Link apunta a la versión que lo sustituye.
@Component
public class V1Deprecation extends OncePerRequestFilter {

    private final String deprecation;
    private final String sunset;

    public V1Deprecation(OrdersProperties props) {
        this.deprecation = "@" + props.v1().deprecatedAt().getEpochSecond();
        this.sunset = DateTimeFormatter.RFC_1123_DATE_TIME.format(props.v1().sunsetAt().atOffset(ZoneOffset.UTC));
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/v1/orders");   // solo lo que tiene sustituto en v2
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        response.setHeader("Deprecation", deprecation);
        response.setHeader("Sunset", sunset);
        response.setHeader("Link", "</api/v2/orders>; rel=\"successor-version\"");
        chain.doFilter(request, response);
    }
}
