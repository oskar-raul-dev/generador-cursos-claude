package dev.mono.legacy.auth;

import dev.mono.legacy.auth.internal.UserRepository;
import org.springframework.stereotype.Service;

import java.util.UUID;

// API de auth para otros módulos. Sustituye a la relación @ManyToOne Order → User: pedidos ya no
// navega hasta la entidad del usuario, pregunta lo que necesita.
@Service
public class Customers {
    private final UserRepository users;

    public Customers(UserRepository users) {
        this.users = users;
    }

    public String emailOf(UUID customerId) {
        return users.findById(customerId).map(u -> u.getEmail()).orElse(null);
    }
}
