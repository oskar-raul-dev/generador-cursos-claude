package dev.ms.monolith.web;

import dev.ms.monolith.service.Actor;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.UUID;

final class ActorResolver {
    private ActorResolver() {}

    static Actor from(Jwt jwt) {
        return new Actor(UUID.fromString(jwt.getSubject()), jwt.getClaimAsString("email"), jwt.getClaimAsString("role"));
    }
}
