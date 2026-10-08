package hex.orders.application.error;

public final class ProductAlreadyExists extends ApplicationException {

    private final String sku;

    public ProductAlreadyExists(String sku) {
        super(sku + " already exists");
        this.sku = sku;
    }

    public String sku() {
        return sku;
    }
}
