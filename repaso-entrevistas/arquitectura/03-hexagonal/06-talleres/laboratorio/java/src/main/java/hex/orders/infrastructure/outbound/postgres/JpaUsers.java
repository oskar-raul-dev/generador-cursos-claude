package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.Actor;
import hex.orders.application.port.out.Users;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
public class JpaUsers implements Users {

    private final UserRepository repository;

    public JpaUsers(UserRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<User> findByEmail(String email) {
        return repository.findByEmail(email).map(JpaUsers::toUser);
    }

    @Override
    public Optional<User> findById(UUID id) {
        return repository.findById(id).map(JpaUsers::toUser);
    }

    private static User toUser(UserEntity e) {
        return new User(e.id, e.email, e.passwordHash, Actor.Role.valueOf(e.role.toUpperCase()));
    }
}
