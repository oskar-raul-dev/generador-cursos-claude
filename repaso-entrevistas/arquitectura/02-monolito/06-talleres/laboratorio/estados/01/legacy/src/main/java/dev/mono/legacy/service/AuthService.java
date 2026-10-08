package dev.mono.legacy.service;

import dev.mono.legacy.entity.User;
import dev.mono.legacy.repository.UserRepository;
import dev.mono.legacy.util.LegacyException;
import dev.mono.legacy.util.RevokedTokens;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
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

    public Map<String, Object> login(String email, String password) {
        User user = users.findByEmail(email).orElseThrow(() -> new LegacyException("User not found"));
        if (!passwords.matches(password, user.getPasswordHash())) {
            throw new LegacyException("Wrong password");
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
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("accessToken", token);
        out.put("tokenType", "Bearer");
        out.put("expiresIn", ttl);
        out.put("user", user);          // "para que el front no tenga que pedirlo otra vez"
        return out;
    }

    public void logout(String jti) {
        revoked.revoke(jti);
    }
}
