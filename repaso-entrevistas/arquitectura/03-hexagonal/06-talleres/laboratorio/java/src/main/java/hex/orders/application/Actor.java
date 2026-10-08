package hex.orders.application;

import hex.orders.application.error.AccessDenied;
import hex.orders.domain.Order;

import java.util.Objects;
import java.util.UUID;

// Quién ejecuta el caso de uso, ya verificado por el borde. No lleva el JWT, ni claims sin
// verificar, ni nada de Spring Security: el adaptador HTTP lo construye después de autenticar.
public record Actor(UUID id, String email, Role role) {

    public enum Role { CUSTOMER, OPERATOR }

    public Actor {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(email, "email");
        Objects.requireNonNull(role, "role");
    }

    public boolean isOperator() {
        return role == Role.OPERATOR;
    }

    // Autorización contextual: dueño u operador. Vive aquí y no en el filtro HTTP porque un job o
    // un consumidor que use el mismo caso de uso tiene que cumplirla igual.
    public boolean canSee(Order order) {
        return isOperator() || order.customerId().equals(id);
    }

    public void requireOperator() {
        if (!isOperator()) {
            throw new AccessDenied();
        }
    }
}
