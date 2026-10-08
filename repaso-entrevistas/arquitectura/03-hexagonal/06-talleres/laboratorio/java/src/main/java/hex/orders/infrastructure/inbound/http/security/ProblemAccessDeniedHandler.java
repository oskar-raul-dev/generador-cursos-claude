package hex.orders.infrastructure.inbound.http.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;

import java.io.IOException;

// 403 del filtro de seguridad. En este sistema casi nunca se llega aquí: la capacidad de operator
// la comprueba el caso de uso (AccessDenied → ProblemHandler). Queda por completitud.
public final class ProblemAccessDeniedHandler implements AccessDeniedHandler {

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, AccessDeniedException exception)
        throws IOException {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/problem+json");
        response.getWriter().write("""
            {"type":"about:blank","title":"Forbidden","status":403,"code":"FORBIDDEN","instance":"%s"}"""
            .formatted(request.getRequestURI()));
    }
}
