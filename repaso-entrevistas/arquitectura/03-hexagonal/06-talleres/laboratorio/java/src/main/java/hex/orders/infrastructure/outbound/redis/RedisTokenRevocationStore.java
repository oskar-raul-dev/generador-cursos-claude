package hex.orders.infrastructure.outbound.redis;

import hex.orders.application.port.out.TokenRevocationStore;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

// Revocación por jti con TTL: Redis olvida la clave cuando el token habría expirado de todos modos.
@Component
public class RedisTokenRevocationStore implements TokenRevocationStore {

    private static final String PREFIX = "hex:revoked:";

    private final StringRedisTemplate redis;

    public RedisTokenRevocationStore(StringRedisTemplate redis) {
        this.redis = redis;
    }

    @Override
    public void revoke(String tokenId, Duration timeToLive) {
        redis.opsForValue().set(PREFIX + tokenId, "1", timeToLive);
    }

    @Override
    public boolean isRevoked(String tokenId) {
        return Boolean.TRUE.equals(redis.hasKey(PREFIX + tokenId));
    }
}
