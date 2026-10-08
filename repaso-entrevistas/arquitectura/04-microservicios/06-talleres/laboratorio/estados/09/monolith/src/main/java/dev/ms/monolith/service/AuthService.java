package dev.ms.monolith.service;

import dev.ms.monolith.config.MsProperties;
import dev.ms.monolith.repository.UserRepository;
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
    private final MsProperties props;

    public AuthService(UserRepository users, PasswordEncoder passwords, JwtEncoder encoder, MsProperties props) {
        this.users = users; this.passwords = passwords; this.encoder = encoder; this.props = props;
    }

    public Views.TokenResponse login(String email, String password) {
        var user = users.findByEmail(email)
            .filter(u -> passwords.matches(password, u.getPasswordHash()))
            .orElseThrow(Errors.InvalidCredentials::new);   // mismo error exista o no el correo
        var now = Instant.now();
        var claims = JwtClaimsSet.builder()
            .subject(user.getId().toString())
            .claim("email", user.getEmail())
            .claim("role", user.getRole())
            .id(UUID.randomUUID().toString())
            .issuedAt(now)
            .expiresAt(now.plusSeconds(props.jwt().ttlSeconds()))
            .build();
        var header = JwsHeader.with(MacAlgorithm.HS256).build();
        var token = encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        return new Views.TokenResponse(token, "Bearer", props.jwt().ttlSeconds());
    }
}
