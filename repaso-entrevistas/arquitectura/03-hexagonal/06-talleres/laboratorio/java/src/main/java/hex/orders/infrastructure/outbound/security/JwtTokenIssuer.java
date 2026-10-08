package hex.orders.infrastructure.outbound.security;

import hex.orders.application.port.out.TokenIssuer;
import hex.orders.application.port.out.Users;
import hex.orders.infrastructure.config.HexProperties;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

// Emite el JWT del contrato: sub, email, role, jti y exp. El jti es lo que /logout revoca.
@Component
public class JwtTokenIssuer implements TokenIssuer {

    private final JwtEncoder encoder;
    private final HexProperties properties;
    private final Clock clock;

    public JwtTokenIssuer(JwtEncoder encoder, HexProperties properties, Clock clock) {
        this.encoder = encoder;
        this.properties = properties;
        this.clock = clock;
    }

    @Override
    public IssuedToken issue(Users.User user) {
        Instant now = clock.instant();
        Instant expiresAt = now.plusSeconds(properties.jwt().ttlSeconds());
        String jti = UUID.randomUUID().toString();
        var claims = JwtClaimsSet.builder()
            .subject(user.id().toString())
            .claim("email", user.email())
            .claim("role", user.role().name())
            .id(jti)
            .issuedAt(now)
            .expiresAt(expiresAt)
            .build();
        var header = JwsHeader.with(MacAlgorithm.HS256).build();
        String value = encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        return new IssuedToken(value, jti, expiresAt, properties.jwt().ttlSeconds());
    }
}
