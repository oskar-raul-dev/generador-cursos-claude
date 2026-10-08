package co.coodrosan.lab.inventory;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.HandlerMapping;

// G7: una línea JSON por petición, con los mismos campos que los otros tres. El request_id viene en
// X-Request-Id (lo pone la puerta) o se inventa, y va al MDC: así lo lleva cualquier línea que se escriba
// durante la petición, y SalesController lo reenvía a los vecinos.
@Component
public class RequestLogFilter extends OncePerRequestFilter {

    private static final Logger LOG = LoggerFactory.getLogger(RequestLogFilter.class);

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String requestId = request.getHeader("X-Request-Id");
        if (requestId == null || requestId.isBlank()) {
            requestId = UUID.randomUUID().toString();
        }
        MDC.put("request_id", requestId);
        long start = System.nanoTime();
        try {
            chain.doFilter(request, response);
        } finally {
            // El patrón de la ruta lo deja Spring en la petición al elegir el controlador; sin ruta, /**.
            Object pattern = request.getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE);
            LOG.atInfo()
                    .addKeyValue("method", request.getMethod())
                    .addKeyValue("uri", pattern != null ? pattern.toString() : "/**")
                    .addKeyValue("path", request.getRequestURI())
                    .addKeyValue("status", response.getStatus())
                    .addKeyValue("duration_ms", (System.nanoTime() - start) / 1_000_000.0)
                    .log("request");
            MDC.remove("request_id");
        }
    }
}
