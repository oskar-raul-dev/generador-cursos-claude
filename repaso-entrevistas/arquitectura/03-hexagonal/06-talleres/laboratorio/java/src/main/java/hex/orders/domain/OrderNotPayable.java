package hex.orders.domain;

public final class OrderNotPayable extends DomainException {

    private final OrderStatus status;

    public OrderNotPayable(OrderStatus status) {
        super("order is " + status);
        this.status = status;
    }

    public OrderStatus status() {
        return status;
    }
}
