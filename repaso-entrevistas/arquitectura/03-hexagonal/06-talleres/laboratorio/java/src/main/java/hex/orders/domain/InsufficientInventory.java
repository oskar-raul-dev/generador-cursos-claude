package hex.orders.domain;

// La regla "no puedes reservar lo que no hay". La lanza el adaptador de inventario cuando el
// descuento atómico no encuentra unidades, y el caso de uso la deja pasar: la transacción revierte
// las líneas ya reservadas.
public final class InsufficientInventory extends DomainException {

    private final String sku;
    private final int requested;
    private final int available;
    private final int lineIndex;

    public InsufficientInventory(String sku, int requested, int available, int lineIndex) {
        super(sku + ": requested " + requested + ", available " + available);
        this.sku = sku;
        this.requested = requested;
        this.available = available;
        this.lineIndex = lineIndex;
    }

    public String sku() { return sku; }
    public int requested() { return requested; }
    public int available() { return available; }
    public int lineIndex() { return lineIndex; }
}
