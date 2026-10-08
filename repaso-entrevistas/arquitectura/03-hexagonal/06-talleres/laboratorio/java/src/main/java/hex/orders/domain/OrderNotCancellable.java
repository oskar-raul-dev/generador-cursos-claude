package hex.orders.domain;

public final class OrderNotCancellable extends DomainException {

    private final OrderStatus status;

    public OrderNotCancellable(OrderStatus status) {
        super("order is " + status);
        this.status = status;
    }

    public OrderStatus status() {
        return status;
    }
}
