package hex.orders.infrastructure.config;

import hex.orders.application.port.out.TokenRevocationStore;
import hex.orders.infrastructure.inbound.http.security.RevocationValidator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

// La clave y los codecs JWT, separados de la cadena de filtros HTTP (taller 11): emitir y verificar
// tokens es una capacidad del sistema (Login la usa) y existe aunque el proceso arranque sin servidor
// web, como CLI de lotes. El filtro que exige el token en cada petición sí es solo del borde HTTP.
@Configuration
public class TokenConfiguration {

    @Bean
    SecretKey jwtKey(HexProperties properties) {
        return new SecretKeySpec(properties.jwt().secret().getBytes(), "HmacSHA256");
    }

    // El mismo secreto emite (TokenIssuer) y verifica (resource server). HS256 basta para un
    // laboratorio; en producción sería un par de claves y un JWKS.
    @Bean
    JwtEncoder jwtEncoder(SecretKey key) {
        return new NimbusJwtEncoder(new com.nimbusds.jose.jwk.source.ImmutableSecret<>(key));
    }

    @Bean
    JwtDecoder jwtDecoder(SecretKey key, TokenRevocationStore revocations) {
        var decoder = NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();
        // firma y expiración (por defecto) + revocación por jti (nuestro validador)
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
            JwtValidators.createDefault(), new RevocationValidator(revocations)));
        return decoder;
    }
}
