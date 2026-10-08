package hex.orders.application.error;

// Mismo error exista o no el correo: no se revela quién tiene cuenta.
public final class InvalidCredentials extends ApplicationException {

    public InvalidCredentials() {
        super("invalid credentials");
    }
}
