package hex.orders.infrastructure.inbound.http.security;

import hex.orders.application.port.out.TokenRevocationStore;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;

// Un token válido por firma y fecha puede estar revocado por logout. El código de error propio
// ("token_revoked") es lo que permite al entry point responder TOKEN_REVOKED y no UNAUTHENTICATED.
public final class RevocationValidator implements OAuth2TokenValidator<Jwt> {

    public static final String ERROR_CODE = "token_revoked";

    private final TokenRevocationStore revocations;

    public RevocationValidator(TokenRevocationStore revocations) {
        this.revocations = revocations;
    }

    @Override
    public OAuth2TokenValidatorResult validate(Jwt token) {
        String jti = token.getId();
        if (jti != null && revocations.isRevoked(jti)) {
            return OAuth2TokenValidatorResult.failure(new OAuth2Error(ERROR_CODE, "token revoked", null));
        }
        return OAuth2TokenValidatorResult.success();
    }
}
