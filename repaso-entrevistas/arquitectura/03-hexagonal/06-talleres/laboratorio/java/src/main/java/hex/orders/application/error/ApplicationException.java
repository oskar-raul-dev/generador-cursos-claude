package hex.orders.application.error;

// Errores de aplicación: existencia, permisos, credenciales e idempotencia. Como los del dominio,
// son rechazos esperados con nombre de negocio; el borde les pone código HTTP.
public abstract class ApplicationException extends RuntimeException {

    protected ApplicationException(String message) {
        super(message);
    }
}
