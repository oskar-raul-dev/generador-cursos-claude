package hex.orders.domain;

// Los cinco estados del contrato. Las transiciones válidas las decide Order, no este enum.
public enum OrderStatus {
    CONFIRMED,
    PAID,
    PAYMENT_REJECTED,
    PAYMENT_PENDING,
    CANCELLED
}
