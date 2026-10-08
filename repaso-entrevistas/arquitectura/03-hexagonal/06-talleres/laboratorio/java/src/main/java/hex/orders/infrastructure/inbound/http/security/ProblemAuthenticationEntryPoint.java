package hex.orders.infrastructure.inbound.http.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.jwt.JwtValidationException;
import org.springframework.security.web.AuthenticationEntryPoint;

import java.io.IOException;

// 401 en problem+json. Distingue "sin token válido" de "token revocado" buscando el código del
// validador en la causa: el proveedor JWT de Spring envuelve todo fallo en un
// InvalidBearerTokenException con código genérico "invalid_token", y solo la JwtValidationException
// original conserva el "token_revoked" que dejó RevocationValidator.
public final class ProblemAuthenticationEntryPoint implements AuthenticationEntryPoint {

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException exception)
        throws IOException {
        boolean revoked = isRevoked(exception);
        String code = revoked ? "TOKEN_REVOKED" : "UNAUTHENTICATED";
        String title = revoked ? "Token revoked" : "Unauthenticated";
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/problem+json");
        response.setHeader("WWW-Authenticate", "Bearer");
        response.getWriter().write("""
            {"type":"about:blank","title":"%s","status":401,"code":"%s","instance":"%s"}"""
            .formatted(title, code, request.getRequestURI()));
    }

    private static boolean isRevoked(Throwable exception) {
        for (Throwable t = exception; t != null; t = t.getCause()) {
            if (t instanceof JwtValidationException validation) {
                return validation.getErrors().stream().map(OAuth2Error::getErrorCode)
                    .anyMatch(RevocationValidator.ERROR_CODE::equals);
            }
        }
        return false;
    }
}
