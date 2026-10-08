package dev.ms.monolith.service;

import java.util.UUID;

// Quién hace la petición, ya verificado por el token.
public record Actor(UUID id, String email, String role) {
    public boolean isOperator() { return "operator".equals(role); }
}
