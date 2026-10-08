package hex.orders.application.error;

// "No existe" y "no es tuyo" se expresan igual: el borde responde 404 sin revelar existencia.
public final class NotFound extends ApplicationException {

    public enum Kind { PRODUCT, ORDER }

    private final Kind kind;
    private final String identifier;

    public NotFound(Kind kind, String identifier) {
        super(kind.name().toLowerCase() + " not found: " + identifier);
        this.kind = kind;
        this.identifier = identifier;
    }

    public static NotFound product(String sku) {
        return new NotFound(Kind.PRODUCT, sku);
    }

    public static NotFound order(String id) {
        return new NotFound(Kind.ORDER, id);
    }

    public Kind kind() { return kind; }
    public String identifier() { return identifier; }
}
