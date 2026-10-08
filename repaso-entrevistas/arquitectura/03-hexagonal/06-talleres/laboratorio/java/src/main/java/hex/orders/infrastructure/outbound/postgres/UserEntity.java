package hex.orders.infrastructure.outbound.postgres;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.util.UUID;

// Registro JPA de la tabla users. Es un detalle de persistencia: no sale del adaptador.
@Entity
@Table(name = "users")
public class UserEntity {

    @Id
    UUID id;

    @Column(nullable = false, unique = true)
    String email;

    @Column(name = "password_hash", nullable = false)
    String passwordHash;

    @Column(nullable = false)
    String role;
}
