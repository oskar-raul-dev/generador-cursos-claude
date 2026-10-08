package hex.orders.application.port.out;

import hex.orders.application.Actor;

import java.util.Optional;
import java.util.UUID;

// Lo que aplicación necesita saber de un usuario para autenticarlo y notificarlo. El hash de la
// contraseña cruza el puerto porque la comparación la hace otro puerto (PasswordHasher).
public interface Users {

    record User(UUID id, String email, String passwordHash, Actor.Role role) {}

    Optional<User> findByEmail(String email);

    Optional<User> findById(UUID id);
}
