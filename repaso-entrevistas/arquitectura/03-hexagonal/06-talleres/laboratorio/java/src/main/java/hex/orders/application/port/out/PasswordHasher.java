package hex.orders.application.port.out;

// El algoritmo (bcrypt, coste 10) es un detalle del adaptador; aplicación solo pregunta "¿coincide?".
public interface PasswordHasher {

    boolean matches(String rawPassword, String hash);
}
