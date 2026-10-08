package hex.orders.application.usecase;

import hex.orders.application.port.out.TokenRevocationStore;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;

// Revocar el token presentado hasta que expire por sí solo.
public final class Logout {

    public record Command(String tokenId, Instant expiresAt) {}

    private final TokenRevocationStore revocations;
    private final Clock clock;

    public Logout(TokenRevocationStore revocations, Clock clock) {
        this.revocations = revocations;
        this.clock = clock;
    }

    public void execute(Command command) {
        Duration remaining = Duration.between(clock.instant(), command.expiresAt());
        if (remaining.isNegative() || remaining.isZero()) {
            return; // ya expiró: no hay nada que recordar
        }
        revocations.revoke(command.tokenId(), remaining);
    }
}
