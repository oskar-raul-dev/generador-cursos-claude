package hex.orders.application.error;

public final class AccessDenied extends ApplicationException {

    public AccessDenied() {
        super("actor lacks the required capability");
    }
}
