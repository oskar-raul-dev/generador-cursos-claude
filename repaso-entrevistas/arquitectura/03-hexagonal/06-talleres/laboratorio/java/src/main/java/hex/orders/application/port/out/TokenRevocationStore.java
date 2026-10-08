package hex.orders.application.port.out;

import java.time.Duration;

// Logout real: el token queda revocado hasta que expire por sí solo. El TTL es el tiempo de vida
// restante; después no hace falta recordarlo.
public interface TokenRevocationStore {

    void revoke(String tokenId, Duration timeToLive);

    boolean isRevoked(String tokenId);
}
