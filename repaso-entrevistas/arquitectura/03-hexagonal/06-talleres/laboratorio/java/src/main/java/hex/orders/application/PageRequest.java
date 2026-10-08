package hex.orders.application;

// El servidor acota el tamaño a 100 aunque el cliente pida más (decisión del contrato).
public record PageRequest(String cursor, int limit) {

    public static final int MAX_LIMIT = 100;
    public static final int DEFAULT_LIMIT = 20;

    public PageRequest {
        if (limit < 1) {
            limit = DEFAULT_LIMIT;
        }
        if (limit > MAX_LIMIT) {
            limit = MAX_LIMIT;
        }
    }

    public static PageRequest of(String cursor, Integer limit) {
        return new PageRequest(cursor, limit == null ? DEFAULT_LIMIT : limit);
    }
}
