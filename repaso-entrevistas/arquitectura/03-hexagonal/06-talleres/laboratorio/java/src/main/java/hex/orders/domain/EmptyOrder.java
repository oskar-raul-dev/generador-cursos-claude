package hex.orders.domain;

public final class EmptyOrder extends DomainException {

    public EmptyOrder() {
        super("an order must have at least one line");
    }
}
