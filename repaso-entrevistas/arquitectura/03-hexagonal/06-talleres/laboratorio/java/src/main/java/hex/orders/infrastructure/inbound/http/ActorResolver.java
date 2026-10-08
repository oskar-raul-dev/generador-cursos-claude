package hex.orders.infrastructure.inbound.http;

import hex.orders.application.Actor;
import hex.orders.application.usecase.Logout;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

import java.util.UUID;

// Del JWT ya verificado al Actor de aplicación. Solo claims que el emisor puso (sub, email, role);
// nunca algo que venga del cuerpo o de un header público.
@Component
public class ActorResolver {

    public Actor from(Jwt jwt) {
        return new Actor(
            UUID.fromString(jwt.getSubject()),
            jwt.getClaimAsString("email"),
            Actor.Role.valueOf(jwt.getClaimAsString("role")));
    }

    public Logout.Command logoutCommand(Jwt jwt) {
        return new Logout.Command(jwt.getId(), jwt.getExpiresAt());
    }
}
