package dev.mono.legacy.auth.internal;

import dev.mono.legacy.auth.web.TokenResponse;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

@Service
public class AuthService {
    private final UserRepository users;
    private final PasswordEncoder passwords;
    private final JwtEncoder encoder;
    private final RevokedTokens revoked;
    @Value("${legacy.jwt.ttl-seconds}")
    private long ttl;

    public AuthService(UserRepository users, PasswordEncoder passwords, JwtEncoder encoder, RevokedTokens revoked) {
        this.users = users;
        this.passwords = passwords;
        this.encoder = encoder;
        this.revoked = revoked;
    }

    // taller 04: el mismo 401 exista o no el correo (antes: "User not found" frente a "Wrong password")
    public TokenResponse login(String email, String password) {
        User user = users.findByEmail(email).orElse(null);
        if (user == null || !passwords.matches(password, user.getPasswordHash())) {
            throw new LegacyException(ErrorCode.INVALID_CREDENTIALS, null);
        }
        var now = Instant.now();
        var claims = JwtClaimsSet.builder()
            .subject(user.getId().toString())
            .claim("email", user.getEmail())
            .claim("role", user.getRole())
            .id(UUID.randomUUID().toString())
            .issuedAt(now)
            .expiresAt(now.plusSeconds(ttl))
            .build();
        var token = encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
            .getTokenValue();
        return new TokenResponse(token, "Bearer", ttl);
    }

    public void logout(String jti, Instant expiresAt) {
        revoked.revoke(jti, expiresAt);
    }
}
