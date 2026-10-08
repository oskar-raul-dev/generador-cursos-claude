package dev.ms.orders.service;

// Los errores de negocio que el borde HTTP traduce a problem+json (web/ApiErrors).
public final class Errors {
    private Errors() {}

    public static class ApiError extends RuntimeException {
        ApiError(String message) { super(message); }
    }
    public static final class Unauthenticated extends ApiError {
        public Unauthenticated() { super("no identity from the gateway"); }
    }
    public static final class CatalogUnavailable extends ApiError {
        public CatalogUnavailable(String why) { super("catalog unavailable: " + why); }
    }
    public static final class ProductNotFound extends ApiError {
        public ProductNotFound(String sku) { super(sku); }
    }
    public static final class OrderNotFound extends ApiError {
        public OrderNotFound() { super("order not found"); }
    }
    public static final class InsufficientInventory extends ApiError {
        public final int lineIndex, requested, available;
        public InsufficientInventory(String sku, int lineIndex, int requested, int available) {
            super(sku + ": requested " + requested + ", available " + available);
            this.lineIndex = lineIndex; this.requested = requested; this.available = available;
        }
    }
    public static final class OrderNotPayable extends ApiError {
        public OrderNotPayable(String status) { super("order is " + status); }
    }
    public static final class OrderNotCancellable extends ApiError {
        public OrderNotCancellable(String status) { super("order is " + status); }
    }
    public static final class InventoryUnavailable extends ApiError {
        public InventoryUnavailable(Throwable cause) { super("inventory did not answer: " + cause.getMessage()); initCause(cause); }
    }
    public static final class PaymentsUnavailable extends ApiError {
        public PaymentsUnavailable(String why) { super("payments unavailable: " + why); }
    }
    public static final class IdempotencyKeyRequired extends ApiError {
        public IdempotencyKeyRequired() { super("Idempotency-Key header is required"); }
    }
    public static final class IdempotencyKeyReused extends ApiError {
        public IdempotencyKeyReused() { super("Idempotency-Key reused with a different payload"); }
    }
}
