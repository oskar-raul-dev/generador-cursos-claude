package hex.orders.domain;

// Raíz de los errores de negocio del dominio. Son rechazos esperados, no fallos del sistema: el
// adaptador de entrada los traduce a un código estable del contrato.
public abstract class DomainException extends RuntimeException {

    protected DomainException(String message) {
        super(message);
    }
}
