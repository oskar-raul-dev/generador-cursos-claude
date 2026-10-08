package hex.orders.application.usecase;

import hex.orders.application.error.InvalidCredentials;
import hex.orders.application.port.out.PasswordHasher;
import hex.orders.application.port.out.TokenIssuer;
import hex.orders.application.port.out.Users;

// Autenticar: usuario + contraseña → token. La comparación y el formato del token son puertos.
public final class Login {

    public record Command(String email, String password) {}

    private final Users users;
    private final PasswordHasher hasher;
    private final TokenIssuer tokens;

    public Login(Users users, PasswordHasher hasher, TokenIssuer tokens) {
        this.users = users;
        this.hasher = hasher;
        this.tokens = tokens;
    }

    public TokenIssuer.IssuedToken execute(Command command) {
        // El mismo error exista o no el correo: no se revela quién tiene cuenta.
        var user = users.findByEmail(command.email()).orElseThrow(InvalidCredentials::new);
        if (!hasher.matches(command.password(), user.passwordHash())) {
            throw new InvalidCredentials();
        }
        return tokens.issue(user);
    }
}
